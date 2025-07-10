resource "aws_s3_bucket" "video_storage" {
  bucket        = "ott-project-video-storage-team4-ott-project"
  force_destroy = true # 버킷 안에 객체 있어도 삭제 허용

  tags = {
    Name = "video-stream-bucket"
    Env  = "prod"
  }
}

# 영상 스트리밍용 CORS 설정 추가
resource "aws_s3_bucket_cors_configuration" "video_storage_cors" {
  bucket = aws_s3_bucket.video_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "Content-Length", "Content-Type"]
    max_age_seconds = 3000
  }
}


resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.video_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_s3_bucket_policy" "video_storage_policy" {
  bucket = aws_s3_bucket.video_storage.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccessForSpecificIAMRole"
        Effect    = "Allow"
        Principal = {
          AWS = var.iam_user_arn 
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.video_storage.arn}/*"
      }
    ]
  })
}