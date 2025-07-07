# 300-api-layer

API Gateway and Cognito authentication layer for the multi-region reporting application.

## Overview

This layer creates:
- **API Gateway REST API** with regional endpoints
- **Cognito User Pool** for authentication
- **Lambda integrations** for compute functions

## Architecture

```
Internet → API Gateway → Cognito Auth → Lambda Functions
                      ↓
               CloudWatch Logs
```

## API Endpoints

| Endpoint | Method | Function | Purpose |
|----------|--------|----------|---------|
| `/usage-check` | POST | Usage Check Lambda | Validate usage limits |
| `/post-processing` | POST | Post-Processing Lambda | Handle report completion |
| `/credits` | POST | Credit Top-up Lambda | Manage credit additions |

## Dependencies

- **000-base-network**: VPC configuration
- **200-compute-layer**: Lambda functions

## Configuration

### London (Primary)
```bash
terraform workspace select london
terraform apply -var-file=vars/london.tfvars
```

### Sydney (Replica)
```bash
terraform workspace select sydney
terraform apply -var-file=vars/sydney.tfvars
```

## Key Resources

- **API Gateway**: Regional REST API with throttling
- **Cognito User Pool**: OAuth 2.0 authentication
- **CloudWatch Logs**: API access logging
- **Custom Domain**: Optional SSL endpoint

## Authentication Flow

1. User authenticates via Cognito Hosted UI
2. Receives JWT tokens (access/id/refresh)
3. Includes `Authorization: Bearer <token>` in API calls
4. API Gateway validates token via Cognito authorizer

### Alternative: Direct Token Generation (Future Enhancement)

For simplified client integration, consider adding authentication endpoints:

```
POST /auth/login    - Generate tokens from email/password
POST /auth/refresh  - Refresh expired access tokens
```

**Benefits:**
- No AWS SDK required on frontend
- Simplified authentication flow
- Standard REST API pattern
- Mobile app friendly

**Implementation Notes:**
- Add Lambda functions for Cognito API calls
- Use `InitiateAuth` and `RespondToAuthChallenge`
- Handle SRP authentication flow
- Separate IAM role with Cognito permissions only
- Return standard JSON tokens

## Outputs

- `api_gateway_invoke_url`: API base URL
- `cognito_user_pool_id`: For frontend auth config
- `auth_config`: Complete authentication setup

## Customization

Update `vars/*.tfvars`:
- **Custom domain**: Configure SSL endpoint
- **Throttling**: Adjust rate limits
- **Password policy**: Modify Cognito requirements

## Testing

```bash
# Get API URL
terraform output api_gateway_invoke_url

# Method 1: Using Cognito Hosted UI
# Navigate to: terraform output cognito_hosted_ui_url
# Complete login flow to get token

# Method 2: Direct authentication (if auth endpoints added)
curl -X POST ${API_URL}/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Example authenticated request
curl -X POST ${API_URL}/usage-check \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user123","org_id":"org456"}'
```

## Future Enhancements

### Authentication Endpoints
- **POST /auth/login**: Direct token generation from credentials
- **POST /auth/refresh**: Token refresh without SDK
- **POST /auth/logout**: Token invalidation
- **GET /auth/user**: Get user profile from token

### Report Generation Integration
API Gateway integration with EKS for report processing:

```
POST /reports/generate - Trigger report generation on EKS
GET /reports/{id}     - Check report status
GET /reports/{id}/download - Download completed report
```

**Implementation Notes:**
- **API Gateway → EKS**: Use VPC Link for private connectivity
- **Load Balancer**: Application Load Balancer in front of EKS
- **Authentication**: Same Cognito authorizer for consistency
- **Async Processing**: Return job ID immediately, poll for completion
- **File Storage**: S3 for report artifacts with signed URLs

**Architecture Flow:**
```
Client → API Gateway → VPC Link → ALB → EKS Pods
                                     ↓
                               S3 (Report Storage)
```

### Additional Features
- **Rate limiting**: Per-user API quotas
- **API versioning**: v1, v2 endpoint support  
- **Request validation**: JSON schema validation
- **Response caching**: Cache frequent requests
- **Custom authorizers**: Role-based access control