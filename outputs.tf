# outputs.tf

output "data_bucket_name" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "reports_bucket_name" {
  value = aws_s3_bucket.reports_bucket.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.report_lambda.function_name
}

output "eventbridge_schedule_name" {
  value = aws_scheduler_schedule.daily_report.name
}
