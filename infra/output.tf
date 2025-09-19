output "website_bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  value       = aws_s3_bucket.website_bucket.bucket
}

output "website_bucket_domain_name" {
  description = "Domain name of the S3 bucket for website hosting"
  value       = aws_s3_bucket.website_bucket.bucket_domain_name
}

output "website_url" {
  description = "URL of the website"
  value       = "http://${aws_s3_bucket.website_bucket.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

output "audio_bucket_name" {
  description = "Name of the S3 bucket for audio storage"
  value       = aws_s3_bucket.audio_bucket.bucket
}

output "audio_bucket_arn" {
  description = "ARN of the S3 bucket for audio storage"
  value       = aws_s3_bucket.audio_bucket.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.tts_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.tts_function.arn
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.tts_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.tts_api.id
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.tts_dashboard.dashboard_name}"
}

output "lambda_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT
    To deploy your Text-to-Speech application:
    
    1. Upload your frontend files to the website bucket:
       aws s3 sync ../Frontend/ s3://${aws_s3_bucket.website_bucket.bucket}/
    
    2. Update the API URL in your frontend:
       Replace the hardcoded API URL in index.html with: ${aws_api_gateway_rest_api.tts_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.environment}
    
    3. Package and deploy the Lambda function:
       cd ../backend
       zip lambda_function.zip lambda_function.py
       aws lambda update-function-code --function-name ${aws_lambda_function.tts_function.function_name} --zip-file fileb://lambda_function.zip
    
    4. Access your application at:
       ${aws_s3_bucket.website_bucket.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com
    
    5. Monitor your application at:
       ${aws_cloudwatch_dashboard.tts_dashboard.dashboard_name}
  EOT
}
