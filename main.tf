# main.tf

# Tell Terraform we want to use AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region
}

# Generate random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 3
}

# S3 bucket for source data
resource "aws_s3_bucket" "data_bucket" {
  bucket = "report-data-${random_id.suffix.hex}"
}

# S3 bucket for generated reports
resource "aws_s3_bucket" "reports_bucket" {
  bucket = "report-output-${random_id.suffix.hex}"
}

# Enable versioning on data bucket
resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable versioning on reports bucket
resource "aws_s3_bucket_versioning" "reports_bucket_versioning" {
  bucket = aws_s3_bucket.reports_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}



# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "report_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM policy for Lambda (S3 + Logs)
resource "aws_iam_policy" "lambda_policy" {
  name        = "report_lambda_policy"
  description = "Policy for Lambda to access S3 buckets and CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject","s3:PutObject","s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*",
          aws_s3_bucket.reports_bucket.arn,
          "${aws_s3_bucket.reports_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Lambda function
resource "aws_lambda_function" "report_lambda" {
  function_name = "report_generator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "report_generator.lambda_handler"
  runtime       = "python3.12"
  filename      = "lambda/function.zip"
  source_code_hash = filebase64sha256("lambda/function.zip")

  environment {
    variables = {
      REPORTS_BUCKET = aws_s3_bucket.reports_bucket.bucket
      EMAIL_ADDRESS  = var.email_address
    }
  }

  timeout     = 300
  memory_size = 512
}

# IAM role for EventBridge Scheduler
resource "aws_iam_role" "scheduler_role" {
  name = "eventbridge_scheduler_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

# Policy for Scheduler to invoke Lambda
resource "aws_iam_policy" "scheduler_policy" {
  name   = "scheduler_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["lambda:InvokeFunction"]
      Effect   = "Allow"
      Resource = aws_lambda_function.report_lambda.arn
    }]
  })
}

# Attach policy to scheduler role
resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}



# EventBridge Scheduler to run Lambda daily at 9 AM UTC
resource "aws_scheduler_schedule" "daily_report" {
  # The name of the scheduler (how it appears in AWS)
  name = "daily_report_schedule"

  # The schedule in cron syntax: "0 9 * * ? *" means
  #  - minute 0
  #  - hour 9 UTC
  #  - every day of the month
  #  - every month
  #  - any day of the week (the '?' means no specific day)
  #  - every year
  schedule_expression = "cron(0 9 * * ? *)"

  # Flexible time window setting: OFF means the job will run exactly at the scheduled time
  flexible_time_window { 
    mode = "OFF"
  }

  # The target to execute when the schedule triggers
  target {
    # ARN of the Lambda function to invoke
    arn = aws_lambda_function.report_lambda.arn

    # IAM Role ARN that EventBridge Scheduler uses to assume permission to invoke the Lambda
    role_arn = aws_iam_role.scheduler_role.arn
  }
}



