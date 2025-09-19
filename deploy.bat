@echo off
REM Text-to-Speech Application Deployment Script (Windows Batch)
REM This script deploys the complete TTS application infrastructure

echo 🚀 Starting Text-to-Speech Application Deployment...

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI is not installed. Please install it first.
    echo    Download from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Check if Terraform is installed
terraform --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Terraform is not installed. Please install it first.
    echo    Download from: https://www.terraform.io/downloads
    pause
    exit /b 1
)

REM Check AWS credentials
echo 🔐 Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS credentials not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed

REM Navigate to infrastructure directory
cd infra

REM Initialize Terraform
echo 🏗️  Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ❌ Terraform initialization failed
    pause
    exit /b 1
)

REM Plan Terraform deployment
echo 📋 Planning Terraform deployment...
terraform plan -out=tfplan
if %errorlevel% neq 0 (
    echo ❌ Terraform plan failed
    pause
    exit /b 1
)

REM Apply Terraform configuration
echo 🚀 Applying Terraform configuration...
terraform apply tfplan
if %errorlevel% neq 0 (
    echo ❌ Terraform apply failed
    pause
    exit /b 1
)

REM Get outputs
echo 📤 Getting deployment outputs...
for /f "tokens=*" %%i in ('terraform output -raw website_bucket_name') do set WEBSITE_BUCKET=%%i
for /f "tokens=*" %%i in ('terraform output -raw api_gateway_url') do set API_URL=%%i
for /f "tokens=*" %%i in ('terraform output -raw lambda_function_name') do set LAMBDA_FUNCTION_NAME=%%i

echo ✅ Infrastructure deployed successfully!
echo 📊 Deployment Summary:
echo    Website Bucket: %WEBSITE_BUCKET%
echo    API URL: %API_URL%
echo    Lambda Function: %LAMBDA_FUNCTION_NAME%

REM Lambda function is automatically deployed by Terraform
echo ✅ Lambda function deployed successfully by Terraform!

REM Build and deploy React frontend
echo 🌐 Building React frontend...
cd ..\Frontend

REM Update API URL in the service file
powershell -Command "(Get-Content 'src/services/TTSService.js' -Raw) -replace 'https://4b5jz7mn34\.execute-api\.us-east-1\.amazonaws\.com/prod', '%API_URL%' | Set-Content 'src/services/TTSService.js'"

echo ✅ API URL updated in React service

REM Install dependencies and build
echo 📦 Installing React dependencies...
npm install
if %errorlevel% neq 0 (
    echo ❌ npm install failed
    pause
    exit /b 1
)

echo 🏗️ Building React application...
npm run build
if %errorlevel% neq 0 (
    echo ❌ React build failed
    pause
    exit /b 1
)

REM Upload built frontend to S3
echo 📤 Uploading React build to S3...
aws s3 sync build/ s3://%WEBSITE_BUCKET%/ --delete
if %errorlevel% neq 0 (
    echo ❌ Frontend upload failed
    pause
    exit /b 1
)

echo ✅ Frontend uploaded successfully!

REM Get website URL
cd ..\infra
for /f "tokens=*" %%i in ('terraform output -raw website_url') do set WEBSITE_URL=%%i

echo.
echo 🎉 Deployment Complete!
echo 🌐 Your Text-to-Speech application is now live at:
echo    %WEBSITE_URL%
echo.
echo 📊 Monitor your application at:
for /f "tokens=*" %%i in ('terraform output -raw cloudwatch_dashboard_url') do echo    %%i
echo.
echo 🔧 Useful commands:
echo    View logs: aws logs tail /aws/lambda/%LAMBDA_FUNCTION_NAME% --follow
echo    Update Lambda: aws lambda update-function-code --function-name %LAMBDA_FUNCTION_NAME% --zip-file fileb://lambda_function.zip
echo    Update frontend: aws s3 sync ../Frontend/ s3://%WEBSITE_BUCKET%/ --delete
echo.

REM Clean up
echo 🧹 Cleanup completed!
echo ✨ Your Text-to-Speech application is ready to use!
pause
