# S3 객체의 정보를 읽어오기 위한 DATA SOURCE 추가
# 역할: "image-storage-team4-ott-project" 버킷에 있는 "lambda_function.zip" 파일의 최신 ETag (파일 내용의 해시값)를 AWS로부터 읽어옴
# 테라폼이 terraform apply를 실행할 때마다 S3에 직접 접근하여 이 ETag를 확인합니다.

data "aws_s3_object" "lambda_code_object" {
  bucket = "image-storage-team4-ott-project" # 이미지 업로드용 S3 버킷 이름
  key    = "lambda_function.zip"
}


#람다 리소스

resource "aws_lambda_function" "thumbnail" {
  function_name = "thumbnail"
  role          = aws_iam_role.lambda_thumbnail_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  memory_size   = 1024 # 추가된 부분
  timeout       = 180  # 추가된 부분 
  #s3_bucket     = "image-storage-team4-ott-project"  #->이미지업로드용 버킷으로 작성!!
  s3_bucket     = data.aws_s3_bucket.image_storage.id
  s3_key        = "lambda_function.zip"

  environment {
    variables = {
      # GCP VM의 프라이빗 IP를 람다 환경 변수로 주입합니다.
      # output에서 정의한 "fastapi_backend_private_ip" 값을 참조합니다.
      # URL 형태로 전달하기 위해 "http://" 접두사를 붙여줍니다.
      FASTAPI_BACKEND_URL  = "http://${var.gcp_fastapi_private_ip}"
      LAMBDA_CALLBACK_SECRET = var.fastapi_secret_key # Terraform 변수에서 가져옴
      CLOUDFRONT_DOMAIN = "https://${aws_cloudfront_distribution.cdn.domain_name}" #추가된부분
    }
  }

  # **이 부분이 가장 중요!**
  # data.aws_s3_bucket_object.lambda_code_object 에서 읽어온 ETag 값을 source_code_hash로 사용합니다.
  # 이 ETag는 GitHub Actions가 S3에 lambda_function.zip을 업로드할 때마다
  # 파일 내용이 변경되면 새롭게 생성되는 값입니다.
  # 테라폼은 이 source_code_hash 값이 이전 apply 때와 달라진 것을 감지하면,
  # 람다 함수를 새로운 코드로 업데이트합니다.

  source_code_hash = data.aws_s3_object.lambda_code_object.etag

  # ✅ 람다 VPC 설정 시작
  # 람다 함수가 당신의 AWS VPC (ott-project-vpc) 내의 프라이빗 서브넷에 배포됩니다.
  vpc_config {
    # VPN 연결이 설정된 AWS VPC의 프라이빗 서브넷 ID를 참조합니다.
    # 이 서브넷들을 통해 람다가 VPN 터널을 타고 GCP VM으로 트래픽을 보냅니다.
    subnet_ids         = module.vpc.private_subnets  # ✅ 모듈 출력 사용

    # 람다 함수에 적용할 보안 그룹 ID를 지정합니다.
    # 이 보안 그룹은 람다의 아웃바운드 트래픽을 제어합니다.
    # 아래에서 새로 정의할 aws_security_group.lambda_outbound_sg 의 ID를 참조합니다.
    security_group_ids = [aws_security_group.lambda_outbound_sg.id] # ✅ 새로 정의할 보안 그룹 사용
  }
  # ✅ 람다 VPC 설정 끝
 
  tags = {
    Name = "thumbnail-lambda"
    Project = "OTT"
  }  
}


#lambda-thumbnail-role 만들기

resource "aws_iam_role" "lambda_thumbnail_role" {
  name = "lambda-thumbnail-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}



#정책 만들기

resource "aws_iam_policy" "lambda_thumbnail_s3_policy" {
  name        = "lambda-thumbnail-s3-policy"
  description = "Allow Lambda to access only the specific bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::image-storage-team4-ott-project/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_thumbnail_role.name
  policy_arn = aws_iam_policy.lambda_thumbnail_s3_policy.arn
}
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_thumbnail_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# ✅ IAM Role에 VPC 접근 권한 추가
# 람다 함수가 VPC에 연결되려면 이 권한이 반드시 필요합니다
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_thumbnail_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# S3 버킷 데이터 소스는 cloudfront.tf에서 이미 정의됨

# Lambda 권한 부여
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.image_storage.arn
}

# S3 → Lambda 트리거
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = data.aws_s3_bucket.image_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    #filter_suffix       = ".jpg" #제거
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

#엔드포인트 
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3" 
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids  

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::image-storage-team4-ott-project",
          "arn:aws:s3:::image-storage-team4-ott-project/*"
        ]
      }
    ]
  })

  tags = {
    Name = "s3-endpoint-image-only"
  }
}


# ✅ 람다 함수용 아웃바운드 보안 그룹
resource "aws_security_group" "lambda_outbound_sg" {
  name        = "lambda-thumbnail-outbound-sg"
  description = "Allow Lambda to send outbound traffic to GCP VM via VPN"
  vpc_id      = module.vpc.vpc_id # ✅ 모듈이 생성한 VPC의 ID 참조

  # 아웃바운드 규칙: GCP VM의 프라이빗 IP 대역으로 HTTP/HTTPS 허용
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # ✅ GCP VPC의 프라이빗 CIDR 블록으로 변경 (예: "10.128.0.0/20")
    # 이 값은 var.gcp_vpc_private_cidr_block 변수를 통해 받을 겁니다.
    cidr_blocks = [var.gcp_vpc_private_cidr_block] # ✅ 변수로 받아와 GCP VM IP 대역 지정
    description = "Allow HTTP to GCP VM via VPN"
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # ✅ GCP VPC의 프라이빗 CIDR 블록으로 변경
    cidr_blocks = [var.gcp_vpc_private_cidr_block] # ✅ 변수로 받아와 GCP VM IP 대역 지정
    description = "Allow HTTPS to GCP VM via VPN"
  }
  # S3도 아웃바운드에 추가
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description = "Allow traffic to S3 via VPC Endpoint"
  }

  # 인바운드 규칙: 람다는 보통 다른 리소스가 람다에게 직접 접근할 필요가 없으므로 인바운드 규칙은 없거나 최소화합니다.
  # (S3 트리거는 별도의 람다 권한으로 동작하며, 네트워크 인바운드 규칙과는 무관합니다.)

  tags = {
    Name    = "lambda-thumbnail-outbound-sg"
    Project = "OTT"
  }
}