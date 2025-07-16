# 🔷 S3 버킷
data "aws_s3_bucket" "image_storage" {
  bucket = "image-storage-team4-ott-project"
}

# 🔷 OAI 생성
# CloudFront가 S3에 접근할 때 사용하는 가상의 사용자(Identity) 를 생성
#S3 버킷 정책에 이 OAI의 ARN을 지정해주면, CloudFront만 S3를 읽을 수 있음
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront to access image-storage-team4-ott-project"
}

# 🔷 CloudFront 배포
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true

  origin {
    domain_name = data.aws_s3_bucket.image_storage.bucket_regional_domain_name
    origin_id   = "s3-image-storage-team4-ott-project"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-image-storage-team4-ott-project"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"] 
    #HEAD는 HTTP 메서드 중 하나 , HEAD: 헤더 정보만 받고, 본문은 안 받음(속도 빠르고 트래픽 적음): 주로 “파일이 있나?” 확인할 때 사용
    cached_methods         = ["GET", "HEAD"] #GET:  파일 내용을 포함해서 받음
    compress               = true
    
    #S3에 요청할 때 쿼리스트링, 쿠키를 전달하지 않음 → 캐싱 효율↑
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100" # (비용 절감을 위해 일부 리전만 사용, 서울 + 동경 + 미국 일부)

  restrictions {
    geo_restriction {
      restriction_type = "none" #지리적 제약을 둘 수 있지만, 여기선 none → 전 세계 허용
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true #CloudFront에서 HTTPS를 쓸 수 있게 기본 제공 인증서를 사용
  }

  tags = {
    Name = "team4-ott-cdn"
  }
}

# 🔷 S3 버킷 정책
# S3 버킷 정책을 지정해서 CloudFront(OAI)만 S3를 읽을 수 있도록 허용
# 유저는 CloudFront로만 접근 가능하고 S3는 비공개 상태 유지
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = data.aws_s3_bucket.image_storage.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action   = "s3:GetObject",
        Resource = "${data.aws_s3_bucket.image_storage.arn}/*"
      }
    ]
  })
}
