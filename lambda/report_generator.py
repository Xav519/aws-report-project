# report_generator.py
# Simple Lambda function to generate a CSV report in S3

import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    reports_bucket = os.environ['REPORTS_BUCKET']

    # Simple CSV content
    content = "Product,Sales,Inventory\nProduct A,1000,250\nProduct B,1500,180\n"

    # File name with timestamp
    file_name = f"daily_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

    # Upload to S3
    s3.put_object(Bucket=reports_bucket, Key=file_name, Body=content)

    return {"statusCode": 200, "body": f"Report generated: {file_name}"}
