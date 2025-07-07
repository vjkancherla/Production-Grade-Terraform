# 100-data-layer - DynamoDB Tables

This layer creates the DynamoDB tables for the multi-region reporting application's data storage needs.

## Tables Created

### 1. **usage_plans**
Stores subscription plan definitions with their base limits.

**Terraform Schema:**
- **Partition Key:** `plan_id` (String)

**Application Data Attributes** *(not defined in Terraform):*
- plan_name, monthly_report_limit, daily_report_limit, price, features

**Example Live Data:**
```json
{
  "plan_id": "premium",
  "plan_name": "Premium Plan",
  "monthly_report_limit": 1000,
  "daily_report_limit": 100,
  "price": 99.99,
  "features": ["advanced_analytics", "custom_exports", "api_access"],
  "status": "active",
  "created_at": "2025-06-10T10:00:00Z"
}
```

### 2. **organizations** 
Stores organization information, plan assignments, and credit management.

**Terraform Schema:**
- **Partition Key:** `org_id` (String)
- **GSI:** `plan-index` on `plan_id` (String)

**Application Data Attributes** *(not defined in Terraform):*
- plan_id, org_name, plan limits, additional credits, effective limits, current usage

**Example Live Data:**
```json
{
  "org_id": "org_12345",
  "plan_id": "premium",
  "org_name": "Acme Corporation",
  "plan_monthly_limit": 1000,
  "plan_daily_limit": 100,
  "additional_monthly_credits": 500,
  "additional_daily_credits": 50,
  "effective_monthly_limit": 1500,
  "effective_daily_limit": 150,
  "current_monthly_usage": 245,
  "current_daily_usage": 15,
  "billing_cycle_start": "2025-06-01",
  "status": "active",
  "created_at": "2025-06-10T10:00:00Z",
  "updated_at": "2025-06-10T14:30:00Z"
}
```

### 3. **users**
Stores user information with optional individual limits and credit overrides.

**Terraform Schema:**
- **Partition Key:** `user_id` (String)
- **GSI:** `org-index` on `org_id` (String)
- **GSI:** `email-index` on `email` (String)

**Application Data Attributes** *(not defined in Terraform):*
- org_id, email, name, role, user limits, additional credits, current usage, status

**Example Live Data:**
```json
{
  "user_id": "user_67890",
  "org_id": "org_12345",
  "email": "john.doe@acme.com",
  "name": "John Doe",
  "role": "admin",
  "user_monthly_limit": 150,
  "user_daily_limit": 20,
  "additional_monthly_credits": 25,
  "additional_daily_credits": 5,
  "current_monthly_usage": 23,
  "current_daily_usage": 3,
  "status": "active",
  "cognito_user_id": "us-east-1_aBcDeFgHi",
  "created_at": "2025-06-10T10:00:00Z",
  "last_login": "2025-06-10T14:25:00Z"
}
```

## Features

- **KMS Encryption:** Customer-managed keys for all tables
- **Point-in-time Recovery:** Enabled for data protection
- **Deletion Protection:** Prevents accidental table deletion
- **VPC Endpoint:** Private access to DynamoDB from VPC
- **Global Tables Ready:** Tables designed for cross-region replication

## Table Relationships

```
usage_plans (plan_id)
    ↓
organizations (plan_id → plan_id)
    ↓
users (org_id → org_id)
```

## Usage

**Deploy to London:**
```bash
terraform init -backend-config=backend-config.hcl
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars
```

**Deploy to Sydney:**
```bash
terraform workspace new sydney  
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

## Dependencies

**Remote State:**
- Reads from `000-base-network` layer for VPC information
- Uses VPC ID and private subnets for DynamoDB VPC endpoint

**Required:**
- VPC and subnets from base network layer
- S3 backend from bootstrap layer

## Outputs

The layer provides outputs for:
- Table names and ARNs for the 3 core tables
- KMS key information  
- VPC endpoint details

These outputs are consumed by:
- `200-compute-layer` (Lambda functions)
- `300-api-layer` (API Gateway integration)
- `400-messaging-layer` (SQS processing)


