# Text-to-Speech Application

A complete serverless text-to-speech application built with AWS using Amazon Polly, API Gateway, Lambda, S3, and Terraform. The repo includes both simple HTML frontends and a React-based frontend, plus one-click deployment scripts.

## 🏗️ Architecture

- **Frontend**: Static website hosted on S3 (HTML and React build options)
- **API**: API Gateway (REGIONAL) with Lambda proxy integration
- **Backend**: AWS Lambda (Python 3.9) using Amazon Polly (neural) to generate MP3
- **Storage**: S3 for static website and a separate S3 bucket for audio files (lifecycle rules)
- **Monitoring**: CloudWatch logs, alarms, and dashboard
- **Infrastructure**: Terraform for Infrastructure as Code (IaC)

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Python 3.9+ (for local development)
- Node.js 18+ and npm (for building the React frontend)

### Deployment

1. **Clone and navigate to the project:**
   ```bash
   git clone <your-repo>
   cd TTS-APPLICATION
   ```

2. **One-command deploy (Windows PowerShell):**
   ```powershell
   ./deploy.ps1
   ```

   Or on Linux/macOS:
   ```bash
   ./deploy.sh
   ```

   What this does:
   - Provisions all AWS infrastructure via Terraform in `infra/`
   - Packages and deploys the Lambda function in `backend/`
   - Builds and uploads the frontend to the website S3 bucket
   - Prints the live Website URL and API URL from Terraform outputs

### Manual Deployment

If you prefer to deploy manually:

1. **Provision infrastructure:**
   ```bash
   cd infra
   terraform init
   terraform plan
   terraform apply
   ```

2. **Package and deploy Lambda:**
   ```bash
   cd ../backend
   zip lambda_function.zip lambda_function.py
   aws lambda update-function-code --function-name <function-name> --zip-file fileb://lambda_function.zip
   ```

3. **Build and upload frontend (React build):**
   ```bash
   cd ../Frontend
   npm install
   npm run build
   aws s3 sync build/ s3://<website-bucket-name>/ --delete
   ```

   For the simple HTML version instead:
   ```bash
   cd ../Frontend
   aws s3 sync . s3://<website-bucket-name>/ --exclude "node_modules/*" --exclude "package-lock.json" --exclude "package.json"
   ```

## 📁 Project Structure

```
TTS-APPLICATION/
├── backend/
│   ├── lambda_function.py        # Lambda handler (Amazon Polly + S3)
│   ├── lambda_function.zip       # Deployment zip (generated)
│   └── requirements.txt          # Python dependencies
├── Frontend/
│   ├── index.html                # Simple HTML app
│   ├── index-cors-fixed.html     # HTML variant with strict CORS handling
│   ├── index-proxy.html          # HTML variant using a proxy pattern
│   ├── index-react.html          # HTML page pointing to React build
│   ├── package.json              # React build scripts
│   └── start-dev.ps1             # Dev helper (Windows)
├── infra/
│   ├── main.tf                   # Main Terraform configuration
│   ├── variables.tf              # Terraform variables
│   ├── output.tf                 # Terraform outputs
│   └── provider.tf               # AWS provider configuration
├── deploy.ps1                    # Windows one-click deploy
├── deploy.sh                     # Linux/macOS one-click deploy
├── deploy.bat                    # Batch wrapper (optional)
├── DOCS.md                       # Detailed architecture and notes
└── README.md                     # This file
```

## 🔧 Configuration

### Terraform Variables

You can customize the deployment by modifying `infra/variables.tf`:

- `project_name`: Name of your project (default: "tts-app")
- `environment`: Environment name (default: "prod")
- `aws_region`: AWS region (default: "us-east-1")
- `lambda_timeout`: Lambda timeout in seconds (default: 30)
- `lambda_memory_size`: Lambda memory in MB (default: 256)
- `log_retention_days`: CloudWatch log retention (default: 14)
- `audio_retention_days`: Audio file retention in S3 (default: 30)

### Lambda Environment Variables

The Lambda function uses these environment variables:
- `AUDIO_BUCKET`: S3 bucket name for audio storage
- `REGION`: AWS region

## 🎯 Features

### Frontend
- Beautiful, responsive UI
- Real-time text-to-speech conversion
- Multiple voice options (e.g., Joanna, Matthew, Amy, Brian)
- Loading states and error handling
- Mobile-friendly design

### Backend
- Serverless Lambda function
- Amazon Polly integration with neural engine
- S3 audio file storage with presigned URLs
- Comprehensive error handling
- CloudWatch logging

### Infrastructure
- Complete Infrastructure as Code
- Secure IAM roles and policies
- S3 buckets with proper configurations
- API Gateway with CORS support
- CloudWatch monitoring and alarms
- Automated deployment scripts

## 📊 Monitoring

### CloudWatch Dashboard
Access application metrics at the CloudWatch dashboard URL provided by Terraform outputs.

### Key Metrics
- Lambda invocations, errors, and duration
- API Gateway request count and error rates
- S3 storage usage

### Alarms
- Lambda error rate monitoring
- Lambda duration monitoring

## 🔒 Security

### IAM Policies
- Least privilege access for Lambda function
- S3 bucket policies for public website access
- Secure audio file storage with presigned URLs

### CORS
- Properly configured CORS headers
- Secure API endpoints

## 🛠️ Development

### Local Testing
```bash
# Install dependencies
pip install -r backend/requirements.txt

# Test Lambda function locally (requires AWS credentials)
python backend/lambda_function.py
```

To run the React frontend locally (if using the React build):
```powershell
cd Frontend
npm install
npm start
```

### Updating the Application
1. Make your changes to the code
2. On Windows, run `./deploy.ps1` to redeploy (or `./deploy.sh` on Linux/macOS)
3. Or update specific components manually

## 📝 API Reference

### POST /convert
Converts text to speech using Amazon Polly.

**Request Body:**
```json
{
  "text": "Hello, world!",
  "voice": "Joanna"
}
```

**Response:**
```json
{
  "message": "Audio generated successfully",
  "audio_url": "https://s3.amazonaws.com/bucket/audio/file.mp3",
  "filename": "audio_20231201_143022_abc12345.mp3"
}
```

## 🚨 Troubleshooting

### Common Issues

1. **CORS errors in browser (Failed to fetch):**
   - Ensure `OPTIONS` method exists on `/convert` with proper integration response headers
   - Add API Gateway Default GatewayResponses with CORS for `DEFAULT_4XX` and `DEFAULT_5XX`
   - Redeploy the API stage after CORS changes
   - Hard refresh the browser (Ctrl+Shift+R) or use Incognito

2. **Lambda function not updating:**
   ```bash
   cd backend
   zip lambda_function.zip lambda_function.py
   aws lambda update-function-code --function-name <function-name> --zip-file fileb://lambda_function.zip
   ```

3. **Frontend not loading:**
   - Check S3 bucket policy and website hosting configuration
   - Verify files built to `Frontend/build/` (for React) and uploaded to the website bucket
   - Ensure correct API URL is used by the frontend

4. **API Gateway errors:**
   - Check Lambda function logs
   - Verify API Gateway configuration
   - Test Lambda function directly

### Logs
```bash
# View Lambda logs
aws logs tail /aws/lambda/<function-name> --follow

# View API Gateway execution logs (if enabled)
aws logs tail /aws/apigateway/<api-name> --follow
```

## 💰 Cost Optimization

- Audio files are automatically deleted after 30 days
- CloudWatch logs are retained for 14 days
- Lambda memory and timeout tuned for cost/perf balance
- S3 storage classes can be optimized for infrequent access

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Open an issue in the repository

---

**Happy Text-to-Speech! 🎤✨**
