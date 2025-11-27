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
  bucket = "report-data-${random_id.suffix.hex}"  # bucket name must be globally unique
  versioning {
    enabled = true  # keep all previous versions of files
  }
}

# S3 bucket for generated reports
resource "aws_s3_bucket" "reports_bucket" {
  bucket = "report-output-${random_id.suffix.hex}"
  versioning {
    enabled = true
  }
}
