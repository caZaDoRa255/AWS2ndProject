resource "aws_s3_bucket" "video_storage" {
  bucket        = "ott-project-video-storage-team4-ott-project"
  force_destroy = true # 버킷 안에 객체 있어도 삭제 허용

  tags = {
    Name        = "VideoStorageBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.video_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
