# variables.tf

# AWS region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Verified email for SES (you will change this to your email)
variable "email_address" {
  description = "Verified email in SES for sending reports"
  type        = string
}
