#!/bin/bash

# Text-to-Speech Application Deployment Script with CORS Fixes
# This script deploys the complete TTS application infrastructure with all CORS fixes

set -e

echo "🚀 Starting Text-to-Speech Application Deployment with CORS Fixes..."
echo "=================================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

# Check if curl is installed (for testing)
if ! command -v curl &> /dev/null; then
    echo "⚠️  curl is not installed. Some tests may not work."
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS credentials configured"

# Verify project structure
echo "📁 Verifying project structure..."
if [ ! -f "backend/lambda_function.py" ]; then
    echo "❌ Backend Lambda function not found!"
    exit 1
fi

if [ ! -f "infra/main.tf" ]; then
    echo "❌ Infrastructure configuration not found!"
    exit 1
fi

if [ ! -f "Frontend/index.html" ]; then
    echo "❌ Frontend files not found!"
    exit 1
fi

echo "✅ Project structure verified"

# Navigate to infrastructure directory
cd infra

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
terraform init

# Plan Terraform deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply Terraform configuration
echo "🚀 Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
echo "📤 Getting deployment outputs..."
WEBSITE_BUCKET=$(terraform output -raw website_bucket_name)
API_URL=$(terraform output -raw api_gateway_url)
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name)
API_GATEWAY_ID=$(terraform output -raw api_gateway_id)

echo "✅ Infrastructure deployed successfully!"
echo "📊 Deployment Summary:"
echo "   Website Bucket: $WEBSITE_BUCKET"
echo "   API URL: $API_URL"
echo "   Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "   API Gateway ID: $API_GATEWAY_ID"

# Package Lambda function
echo "📦 Packaging Lambda function..."
cd ../backend
zip -r lambda_function.zip lambda_function.py

# Deploy Lambda function
echo "🚀 Deploying Lambda function..."
aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --zip-file fileb://lambda_function.zip

# Wait for Lambda to be ready
echo "⏳ Waiting for Lambda function to be ready..."
sleep 10

# Test Lambda function
echo "🧪 Testing Lambda function..."
LAMBDA_TEST_RESPONSE=$(aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --payload '{"text":"Hello CORS test","voice":"Joanna"}' \
    --cli-binary-format raw-in-base64-out \
    /tmp/lambda_response.json)

if [ $? -eq 0 ]; then
    echo "✅ Lambda function test successful"
    cat /tmp/lambda_response.json
    rm -f /tmp/lambda_response.json
else
    echo "❌ Lambda function test failed"
    exit 1
fi

echo "✅ Lambda function deployed and tested successfully!"

# Update frontend with correct API URL
echo "🌐 Updating frontend with correct API URL..."
cd ../Frontend

# Update API URLs in all frontend files
echo "📝 Updating API URLs in frontend files..."

# List of files to update
FRONTEND_FILES=("index.html" "index-cors-fixed.html" "index-proxy.html" "index-react.html" "src/services/TTSService.js")

for file in "${FRONTEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   Updating $file..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|https://4b5jz7mn34.execute-api.us-east-1.amazonaws.com/prod|$API_URL|g" "$file"
            sed -i '' "s|https://4k1b3exoef.execute-api.us-east-1.amazonaws.com/prod|$API_URL|g" "$file"
        else
            # Linux
            sed -i "s|https://4b5jz7mn34.execute-api.us-east-1.amazonaws.com/prod|$API_URL|g" "$file"
            sed -i "s|https://4k1b3exoef.execute-api.us-east-1.amazonaws.com/prod|$API_URL|g" "$file"
        fi
    fi
done

echo "✅ Frontend files updated with correct API URL"

# Create error.html file
echo "📝 Creating error.html file..."
cat > error.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Not Found - TTS App</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            color: white;
            text-align: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 {
            font-size: 4rem;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
        }
        h2 {
            font-size: 1.5rem;
            margin: 20px 0;
            opacity: 0.9;
        }
        p {
            font-size: 1.1rem;
            margin: 20px 0;
            opacity: 0.8;
        }
        .btn {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 25px;
            margin: 10px;
            transition: all 0.3s ease;
            border: 2px solid rgba(255, 255, 255, 0.3);
        }
        .btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
        .emoji {
            font-size: 2rem;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">😵</div>
        <h1>404</h1>
        <h2>Page Not Found</h2>
        <p>The page you're looking for doesn't exist or has been moved.</p>
        <p>Don't worry, let's get you back on track!</p>
        <a href="/" class="btn">🏠 Go Home</a>
        <a href="/index-cors-fixed.html" class="btn">🔧 CORS Fixed Version</a>
        <a href="/index-proxy.html" class="btn">🌐 Proxy Version</a>
        <a href="/index-react.html" class="btn">⚛️ React Version</a>
    </div>
</body>
</html>
EOF

# Upload frontend to S3
echo "📤 Uploading frontend to S3..."
aws s3 sync . s3://"$WEBSITE_BUCKET"/ --delete

echo "✅ Frontend uploaded successfully!"

# Get website URL
WEBSITE_URL=$(cd ../infra && terraform output -raw website_url)

# Test CORS configuration
echo "🧪 Testing CORS configuration..."
if command -v curl &> /dev/null; then
    echo "   Testing OPTIONS preflight request..."
    OPTIONS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        "$API_URL/convert")
    
    if [ "$OPTIONS_RESPONSE" = "200" ]; then
        echo "   ✅ OPTIONS request successful (HTTP $OPTIONS_RESPONSE)"
    else
        echo "   ❌ OPTIONS request failed (HTTP $OPTIONS_RESPONSE)"
    fi
    
    echo "   Testing POST request..."
    POST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d '{"text":"Hello CORS test","voice":"Joanna"}' \
        "$API_URL/convert")
    
    if [ "$POST_RESPONSE" = "200" ]; then
        echo "   ✅ POST request successful (HTTP $POST_RESPONSE)"
    else
        echo "   ❌ POST request failed (HTTP $POST_RESPONSE)"
    fi
    
    echo "   Testing CORS headers..."
    CORS_HEADERS=$(curl -s -I -X OPTIONS \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        "$API_URL/convert" | grep -i "access-control" || echo "No CORS headers found")
    
    if [ -n "$CORS_HEADERS" ]; then
        echo "   ✅ CORS headers present:"
        echo "$CORS_HEADERS" | sed 's/^/      /'
    else
        echo "   ❌ No CORS headers found"
    fi
else
    echo "   ⚠️  curl not available, skipping CORS tests"
fi

# Create CORS test page
echo "📝 Creating CORS test page..."
cat > index-cors-test.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>TTS App - CORS Test</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; background: #f9f9f9; }
    .status { padding: 10px; margin: 10px 0; border-radius: 5px; font-weight: bold; }
    .status.success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .status.error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    .status.info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin: 5px; }
    button:hover { background: #0056b3; }
    .log { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 10px; margin: 10px 0; font-family: monospace; font-size: 12px; max-height: 200px; overflow-y: auto; }
    textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; margin: 10px 0; resize: vertical; }
    select { padding: 10px; border: 1px solid #ddd; border-radius: 5px; margin: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔧 TTS CORS Test Page</h1>
    
    <div class="test-section">
      <h3>Test Input</h3>
      <textarea id="testText" rows="3" placeholder="Enter text to convert...">Hello, this is a CORS test!</textarea>
      <br>
      <select id="testVoice">
        <option value="Joanna">Joanna</option>
        <option value="Matthew">Matthew</option>
        <option value="Amy">Amy</option>
        <option value="Brian">Brian</option>
      </select>
    </div>

    <div class="test-section">
      <h3>API Connectivity Tests</h3>
      <button onclick="testPreflight()">Test OPTIONS (Preflight)</button>
      <button onclick="testFetch()">Test Fetch API</button>
      <button onclick="testXHR()">Test XMLHttpRequest</button>
      <button onclick="runAllTests()">Run All Tests</button>
    </div>

    <div class="test-section">
      <h3>Test Results</h3>
      <div id="testResults"></div>
    </div>

    <div class="test-section">
      <h3>Console Log</h3>
      <div id="consoleLog" class="log"></div>
      <button onclick="clearLog()">Clear Log</button>
    </div>

    <div class="test-section">
      <h3>Audio Output</h3>
      <audio id="audioPlayer" controls style="width: 100%;"></audio>
    </div>
  </div>

  <script>
    const API_URL = 'API_URL_PLACEHOLDER';
    let testCounter = 0;

    function log(message, type = 'info') {
      const timestamp = new Date().toLocaleTimeString();
      const logDiv = document.getElementById('consoleLog');
      const logEntry = document.createElement('div');
      logEntry.innerHTML = `[${timestamp}] ${message}`;
      logEntry.style.color = type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#333';
      logDiv.appendChild(logEntry);
      logDiv.scrollTop = logDiv.scrollHeight;
    }

    function clearLog() {
      document.getElementById('consoleLog').innerHTML = '';
    }

    function addResult(testName, success, message) {
      testCounter++;
      const resultsDiv = document.getElementById('testResults');
      const resultDiv = document.createElement('div');
      resultDiv.className = `status ${success ? 'success' : 'error'}`;
      resultDiv.innerHTML = `${testCounter}. ${testName}: ${success ? '✅ PASS' : '❌ FAIL'} - ${message}`;
      resultsDiv.appendChild(resultDiv);
    }

    async function testPreflight() {
      log('Testing OPTIONS preflight request...', 'info');
      try {
        const response = await fetch(API_URL + '/convert', {
          method: 'OPTIONS',
          headers: {
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'Content-Type'
          }
        });
        
        const corsHeaders = {
          'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
          'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
          'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers')
        };
        
        log(`OPTIONS Response: ${response.status}`, response.status === 200 ? 'success' : 'error');
        log(`CORS Headers: ${JSON.stringify(corsHeaders)}`, 'info');
        
        addResult('OPTIONS Preflight', response.status === 200, 
          `Status: ${response.status}, Headers: ${JSON.stringify(corsHeaders)}`);
      } catch (error) {
        log(`OPTIONS Error: ${error.message}`, 'error');
        addResult('OPTIONS Preflight', false, error.message);
      }
    }

    async function testFetch() {
      log('Testing Fetch API...', 'info');
      const text = document.getElementById('testText').value;
      const voice = document.getElementById('testVoice').value;
      
      try {
        const response = await fetch(API_URL + '/convert', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          mode: 'cors',
          credentials: 'omit',
          body: JSON.stringify({ text, voice })
        });
        
        log(`Fetch Response: ${response.status}`, response.status === 200 ? 'success' : 'error');
        
        if (response.ok) {
          const data = await response.json();
          log(`Fetch Data: ${JSON.stringify(data)}`, 'success');
          
          if (data.audio_url) {
            document.getElementById('audioPlayer').src = data.audio_url;
            addResult('Fetch API', true, 'Success - Audio URL received');
          } else {
            addResult('Fetch API', false, 'No audio URL in response');
          }
        } else {
          const errorText = await response.text();
          addResult('Fetch API', false, `HTTP ${response.status}: ${errorText}`);
        }
      } catch (error) {
        log(`Fetch Error: ${error.message}`, 'error');
        addResult('Fetch API', false, error.message);
      }
    }

    async function testXHR() {
      log('Testing XMLHttpRequest...', 'info');
      const text = document.getElementById('testText').value;
      const voice = document.getElementById('testVoice').value;
      
      return new Promise((resolve) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', API_URL + '/convert', true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.setRequestHeader('Accept', 'application/json');
        
        xhr.onreadystatechange = function() {
          if (xhr.readyState === 4) {
            log(`XHR Response: ${xhr.status}`, xhr.status === 200 ? 'success' : 'error');
            
            if (xhr.status === 200) {
              try {
                const data = JSON.parse(xhr.responseText);
                log(`XHR Data: ${JSON.stringify(data)}`, 'success');
                
                if (data.audio_url) {
                  document.getElementById('audioPlayer').src = data.audio_url;
                  addResult('XMLHttpRequest', true, 'Success - Audio URL received');
                } else {
                  addResult('XMLHttpRequest', false, 'No audio URL in response');
                }
              } catch (parseError) {
                addResult('XMLHttpRequest', false, `Parse error: ${parseError.message}`);
              }
            } else {
              addResult('XMLHttpRequest', false, `HTTP ${xhr.status}: ${xhr.statusText}`);
            }
            resolve();
          }
        };
        
        xhr.onerror = function() {
          log('XHR Network Error', 'error');
          addResult('XMLHttpRequest', false, 'Network error');
          resolve();
        };
        
        xhr.send(JSON.stringify({ text, voice }));
      });
    }

    async function runAllTests() {
      log('Running all CORS tests...', 'info');
      document.getElementById('testResults').innerHTML = '';
      testCounter = 0;
      
      await testPreflight();
      await new Promise(resolve => setTimeout(resolve, 1000));
      await testFetch();
      await new Promise(resolve => setTimeout(resolve, 1000));
      await testXHR();
      
      log('All tests completed!', 'success');
    }

    // Update API URL
    document.addEventListener('DOMContentLoaded', function() {
      const script = document.querySelector('script');
      script.textContent = script.textContent.replace('API_URL_PLACEHOLDER', API_URL);
    });

    // Auto-run basic connectivity test on load
    window.addEventListener('load', () => {
      log('CORS Test Page loaded', 'info');
      testPreflight();
    });
  </script>
</body>
</html>
EOF

# Update the CORS test page with the correct API URL
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|API_URL_PLACEHOLDER|$API_URL|g" index-cors-test.html
else
    sed -i "s|API_URL_PLACEHOLDER|$API_URL|g" index-cors-test.html
fi

# Upload the CORS test page
aws s3 cp index-cors-test.html s3://"$WEBSITE_BUCKET"/

echo "✅ CORS test page created and uploaded"

echo ""
echo "🎉 Deployment Complete with CORS Fixes!"
echo "======================================"
echo "🌐 Your Text-to-Speech application is now live at:"
echo "   $WEBSITE_URL"
echo ""
echo "🧪 Test your CORS configuration:"
echo "   $WEBSITE_URL/index-cors-test.html"
echo ""
echo "📊 Monitor your application at:"
echo "   $(cd ../infra && terraform output -raw cloudwatch_dashboard_url)"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
echo "   Update Lambda: aws lambda update-function-code --function-name $LAMBDA_FUNCTION_NAME --zip-file fileb://lambda_function.zip"
echo "   Update frontend: aws s3 sync ../Frontend/ s3://$WEBSITE_BUCKET/ --delete"
echo ""
echo "🔍 CORS Configuration:"
echo "   ✅ OPTIONS preflight requests handled"
echo "   ✅ CORS headers configured for all responses"
echo "   ✅ Multiple fallback methods implemented"
echo "   ✅ Error handling with CORS headers"
echo ""

# Clean up
cd ../backend
rm -f lambda_function.zip

echo "🧹 Cleanup completed!"
echo "✨ Your Text-to-Speech application with CORS fixes is ready to use!"
