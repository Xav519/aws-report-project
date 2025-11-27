import json
from datetime import datetime

# Entry point for AWS Lambda
def lambda_handler(event, context):
    now = datetime.now()  # Get current timestamp
    message = {
        "status": "success",
        "timestamp": str(now),
        "message": "Hello from your Lambda!"
    }
    
    # Return response in Lambda format
    return {
        "statusCode": 200,
        "body": json.dumps(message)
    }