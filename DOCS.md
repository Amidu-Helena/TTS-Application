# Text-to-Speech App – Architecture, Deployment, and Current Status

## Overview
- **Frontend**: Static web UI (HTML and React versions) hosted on S3
- **API**: API Gateway REST API (REGIONAL) with Lambda proxy integration
- **Backend**: AWS Lambda (Python 3.9) using Amazon Polly to generate MP3
- **Storage**: S3 bucket for static website; separate S3 bucket for audio files with lifecycle rules
- **Observability**: CloudWatch Logs, Alarms, and Dashboard
- **Infra as Code**: Terraform modules in `infra/`

## Key Files
- `infra/` – Terraform (`main.tf`, `variables.tf`, `output.tf`, `provider.tf`)
- `backend/lambda_function.py` – Lambda handler integrating Polly and S3
- `Frontend/` – Original HTML app plus React app (`src/`, `public/`) and alternative HTML fallbacks
- `deploy.ps1` – Windows PowerShell deploy: infra + React build + S3 upload

## Deploy Steps (Windows)
1) Provision infra
- PowerShell
  - `./deploy.ps1`
- Manual
  - `cd infra`
  - `terraform init && terraform apply`

2) Deploy frontend (React)
- `cd Frontend`
- `npm install && npm run build`
- `aws s3 sync build/ s3://<website-bucket>/ --delete`

3) Outputs
- Website URL: printed by Terraform outputs
- API URL: `https://<api-id>.execute-api.<region>.amazonaws.com/<stage>`

## Lambda Behavior
- Accepts JSON body: `{ "text": string, "voice": string }`
- Calls Polly (neural engine) to synthesize MP3
- Stores MP3 in audio S3 bucket under `audio/` with metadata
- Returns JSON with presigned `audio_url`
- Returns CORS headers on success and error:
  - `Access-Control-Allow-Origin: *`
  - `Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token`
  - `Access-Control-Allow-Methods: POST,OPTIONS`

## API Gateway
- Resource: `/convert`
- Methods: `POST` (Lambda proxy), `OPTIONS` (MOCK) for CORS
- CORS integration configured for `OPTIONS` method with the standard headers

## Current Issue
- Symptom: Frontend shows "Failed to generate audio: Failed to fetch"
- Scope: Occurs in both raw HTML and React-based frontend
- API direct tests sometimes inconclusive due to interrupted/blocked terminal requests

### Likely Causes
1) CORS still failing for some responses:
   - Lambda adds CORS headers for success and error paths, but API Gateway may return 4XX/5XX before Lambda (missing CORS on Gateway default responses)
2) Stage deployment cache not reflecting latest resources (OPTIONS/cors)
3) Browser or CDN caching of old responses

### Reproduction
- Open website URL from Terraform outputs
- Open DevTools Console (F12)
- Enter text and click Speak
- Observe network request to `.../prod/convert` and browser CORS errors

## Fixes Implemented So Far
- Added `OPTIONS` method + MOCK integration with CORS method/integration responses
- Added Lambda CORS headers on success, base64 fallback, and error responses
- Built React frontend with Axios + fallback fetch and improved error messaging
- Updated deployment scripts to build and upload the React app

## Remaining Actions (Proposed)
1) Add API Gateway Default GatewayResponses with CORS headers (covers 4XX/5XX before Lambda):
   - `aws_api_gateway_gateway_response` for `DEFAULT_4XX` and `DEFAULT_5XX`
   - With `response_parameters` mapping:
     - `gatewayresponse.header.Access-Control-Allow-Origin = "' * '"`
     - `gatewayresponse.header.Access-Control-Allow-Headers = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"`
     - `gatewayresponse.header.Access-Control-Allow-Methods = "'POST,OPTIONS'"`
2) Re-deploy stage after CORS resource changes:
   - Ensure `aws_api_gateway_deployment` depends on all CORS resources (already updated)
   - Confirm `aws_api_gateway_stage` uses the new deployment
3) Validate end-to-end with curl (include `-H "Origin: https://<bucket-website>"`) and in-browser
4) Optional: Pin API URL via env in React (`REACT_APP_API_URL`) and rebuild

## Quick Terraform Snippets To Add
Add to `infra/main.tf`:

- DEFAULT 4XX/5XX Gateway Responses with CORS

```hcl
resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id = aws_api_gateway_rest_api.tts_api.id
  response_type = "DEFAULT_4XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id = aws_api_gateway_rest_api.tts_api.id
  response_type = "DEFAULT_5XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}
```

- Ensure deployment depends on these resources too:

```hcl
depends_on = [
  aws_api_gateway_integration.lambda_integration,
  aws_api_gateway_integration.lambda_options,
  aws_api_gateway_integration_response.convert_options_200,
  aws_api_gateway_gateway_response.default_4xx,
  aws_api_gateway_gateway_response.default_5xx
]
```

## Operational Checks
- `terraform validate` → success
- `terraform apply -auto-approve` → re-deploys API Gateway stage
- Browser hard refresh (Ctrl+Shift+R) or try Incognito to avoid cache

## Known Good URLs
- Website: from `terraform output website_url`
- API: from `terraform output api_gateway_url` then append `/convert`

## Support Data
- Current API ID: visible in API Gateway (`4b5jz7mn34`)
- Current website bucket: from Terraform outputs

## Appendix – Local API Test Commands
- CORS preflight:
```
curl -i -X OPTIONS "https://<api-id>.execute-api.<region>.amazonaws.com/<stage>/convert" \
  -H "Origin: https://<bucket-name>.s3-website-<region>.amazonaws.com" \
  -H "Access-Control-Request-Method: POST"
```
- POST call:
```
curl -i -X POST "https://<api-id>.execute-api.<region>.amazonaws.com/<stage>/convert" \
  -H "Content-Type: application/json" \
  -H "Origin: https://<bucket-name>.s3-website-<region>.amazonaws.com" \
  -d '{"text":"Hello test","voice":"Joanna"}'
```
