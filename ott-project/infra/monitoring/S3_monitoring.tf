# S3 bucket for CloudTrail logs

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail_log_bucket" {
  bucket        = "ott-project-cloudtrail-logs-team4"
  force_destroy = true
}

resource "aws_s3_bucket" "video_storage" {
  bucket        = "ott-project-video-storage-team4"
  force_destroy = true
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_log_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_log_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/s3-data-events"
  retention_in_days = 7
}

# IAM Role for CloudTrail to send logs to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cloudwatch_role" {
  name = "cloudtrail_to_cloudwatch_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for the Role
resource "aws_iam_policy" "cloudtrail_to_cloudwatch_policy" {
  name   = "cloudtrail_to_cloudwatch_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogStream",
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:PutLogEvents",
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "cloudtrail_to_cloudwatch_attachment" {
  role       = aws_iam_role.cloudtrail_to_cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudtrail_to_cloudwatch_policy.arn
}

# CloudTrail to log S3 data events to CloudWatch Logs
resource "aws_cloudtrail" "s3_data_events_trail" {
  name                          = "s3-data-events-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_log_bucket.id
  is_multi_region_trail         = true
  include_global_service_events = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = false
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.video_storage.arn}/"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_log_bucket_policy,
    aws_iam_role_policy_attachment.cloudtrail_to_cloudwatch_attachment
  ]
}

