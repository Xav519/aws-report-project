import boto3
import os
from datetime import datetime

s3 = boto3.client("s3")
bucket = os.environ["REPORTS_BUCKET"]

def lambda_handler(event, context):
    # Example file content
    content = f"Report generated at {datetime.utcnow()}"
    filename = f"report_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.txt"
    
    # Upload to S3
    s3.put_object(Bucket=bucket, Key=filename, Body=content)
    
    return {
        "statusCode": 200,
        "body": f"File {filename} uploaded to {bucket}"
    }
