# Text-to-Speech Application Deployment Script (PowerShell)
# This script deploys the complete TTS application infrastructure

param(
    [switch]$SkipChecks
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting Text-to-Speech Application Deployment..." -ForegroundColor Green

# Check if AWS CLI is installed
if (-not $SkipChecks) {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    try {
        $awsVersion = aws --version 2>$null
        Write-Host "AWS CLI found: $awsVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "AWS CLI is not installed. Please install it first." -ForegroundColor Red
        Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        exit 1
    }

    # Check if Terraform is installed
    try {
        $terraformVersion = terraform --version 2>$null
        Write-Host "Terraform found: $terraformVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Terraform is not installed. Please install it first." -ForegroundColor Red
        Write-Host "   Download from: https://www.terraform.io/downloads" -ForegroundColor Yellow
        exit 1
    }

    # Check AWS credentials
    Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
    try {
        aws sts get-caller-identity | Out-Null
        Write-Host "AWS credentials configured" -ForegroundColor Green
    }
    catch {
        Write-Host "AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
        exit 1
    }
}

# Navigate to infrastructure directory
Set-Location infra

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan Terraform deployment
Write-Host "Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

# Apply Terraform configuration
Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
terraform apply tfplan

# Get outputs
Write-Host "Getting deployment outputs..." -ForegroundColor Yellow
$websiteBucket = terraform output -raw website_bucket_name
$apiUrl = terraform output -raw api_gateway_url
$lambdaFunctionName = terraform output -raw lambda_function_name

Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "Deployment Summary:" -ForegroundColor Cyan
Write-Host "   Website Bucket: $websiteBucket" -ForegroundColor White
Write-Host "   API URL: $apiUrl" -ForegroundColor White
Write-Host "   Lambda Function: $lambdaFunctionName" -ForegroundColor White

# Lambda function is automatically deployed by Terraform
Write-Host "Lambda function deployed successfully by Terraform!" -ForegroundColor Green

# Build and deploy React frontend
Write-Host "Building React frontend..." -ForegroundColor Yellow
Set-Location ../Frontend

# Update API URL in the service file
$serviceContent = Get-Content "src/services/TTSService.js" -Raw
$updatedServiceContent = $serviceContent -replace "https://4b5jz7mn34\.execute-api\.us-east-1\.amazonaws\.com/prod", $apiUrl
Set-Content "src/services/TTSService.js" -Value $updatedServiceContent

Write-Host "API URL updated in React service" -ForegroundColor Green

# Install dependencies and build
Write-Host "Installing React dependencies..." -ForegroundColor Yellow
npm install

Write-Host "Building React application..." -ForegroundColor Yellow
npm run build

# Upload built frontend to S3
Write-Host "Uploading React build to S3..." -ForegroundColor Yellow
aws s3 sync build/ s3://$websiteBucket/ --delete

Write-Host "Frontend uploaded successfully!" -ForegroundColor Green

# Get website URL
Set-Location ../infra
$websiteUrl = terraform output -raw website_url

Write-Host ""
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Your Text-to-Speech application is now live at:" -ForegroundColor Cyan
Write-Host "   $websiteUrl" -ForegroundColor White
Write-Host ""
Write-Host "Monitor your application at:" -ForegroundColor Cyan
$dashboardUrl = terraform output -raw cloudwatch_dashboard_url
Write-Host "   $dashboardUrl" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs: aws logs tail /aws/lambda/$lambdaFunctionName --follow" -ForegroundColor White
Write-Host "   Update Lambda: aws lambda update-function-code --function-name $lambdaFunctionName --zip-file fileb://lambda_function.zip" -ForegroundColor White
Write-Host "   Update frontend: aws s3 sync ../Frontend/ s3://$websiteBucket/ --delete" -ForegroundColor White
Write-Host ""

# Clean up
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Your Text-to-Speech application is ready to use!" -ForegroundColor Green