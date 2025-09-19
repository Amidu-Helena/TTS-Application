import boto3
import base64
import json
import os
from datetime import datetime
import uuid

# Initialize AWS clients
polly = boto3.client("polly")
s3 = boto3.client("s3")

def lambda_handler(event, context):
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        text = body.get("text", "Hello, this is a test.")
        voice = body.get("voice", "Joanna")
        
        # Validate input
        if not text.strip():
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                    "Access-Control-Allow-Methods": "POST,OPTIONS",
                    "Access-Control-Max-Age": "86400"
                },
                "body": json.dumps({"error": "Text cannot be empty"})
            }
        
        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_id = str(uuid.uuid4())[:8]
        filename = f"audio_{timestamp}_{unique_id}.mp3"
        
        # Synthesize speech using Amazon Polly
        response = polly.synthesize_speech(
            Text=text,
            VoiceId=voice,
            OutputFormat="mp3",
            Engine="neural"  # Use neural engine for better quality
        )

        audio_stream = response["AudioStream"].read()
        
        # Get S3 bucket from environment variable
        audio_bucket = os.environ.get('AUDIO_BUCKET')
        
        if audio_bucket:
            # Upload to S3
            s3.put_object(
                Bucket=audio_bucket,
                Key=f"audio/{filename}",
                Body=audio_stream,
                ContentType="audio/mpeg",
                Metadata={
                    "text": text[:100],  # Store first 100 chars as metadata
                    "voice": voice,
                    "timestamp": timestamp
                }
            )
            
            # Generate presigned URL for the audio file (valid for 1 hour)
            audio_url = s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': audio_bucket, 'Key': f"audio/{filename}"},
                ExpiresIn=3600
            )
            
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                    "Access-Control-Allow-Methods": "POST,OPTIONS",
                    "Access-Control-Max-Age": "86400"
                },
                "body": json.dumps({
                    "message": "Audio generated successfully",
                    "audio_url": audio_url,
                    "filename": filename
                })
            }
        else:
            # Fallback: return base64 encoded audio directly
            encoded = base64.b64encode(audio_stream).decode("utf-8")

            return {
                "statusCode": 200,
                "isBase64Encoded": True,
                "headers": {
                    "Content-Type": "audio/mpeg",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                    "Access-Control-Allow-Methods": "POST,OPTIONS",
                    "Access-Control-Max-Age": "86400"
                },
                "body": encoded
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                "Access-Control-Allow-Methods": "POST,OPTIONS",
                "Access-Control-Max-Age": "86400"
            },
            "body": json.dumps({"error": f"Internal server error: {str(e)}"})
        }
