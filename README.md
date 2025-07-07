# Multi-Region AWS Infrastructure

Complete, Production-Grade, Terraform infrastructure for a multi-region reporting application with usage limits, credit management, and global DNS routing.

## 🏗️ Architecture Overview

![Architecture Diagram](./cutlass-tech-HDD.png)

The complete multi-region infrastructure spans London (eu-west-2) and Sydney (ap-southeast-2) regions with global DNS routing for optimal user experience.

## 📁 Project Structure

```
cutlass-tech/
├── bootstrap/                   # S3 backend + DynamoDB locks
├── 000-base-network/            # VPC, subnets, gateways
├── 100-data-layer/              # DynamoDB Global Tables
├── 200-compute-layer/           # Lambda functions
├── 300-api-layer/               # API Gateway + Cognito
├── 400-messaging-layer/         # SQS + SES
├── 900-global-services/         # Route 53 geo-routing
└── README.md                    # This file
```

## 🔧 Terraform Workspaces Strategy

This infrastructure leverages **Terraform workspaces** to deploy the same source code across multiple regions with region-specific configurations. This approach provides several key benefits:

### Why Terraform Workspaces?

- **Single Source of Truth**: One codebase maintains consistency across all regions
- **DRY Principle**: Avoid duplicating infrastructure code for each region
- **Centralized Management**: Unified state management with region-specific state files
- **Simplified Maintenance**: Updates to infrastructure logic apply to all regions
- **Cost Efficiency**: Shared S3 backend with separate state files per workspace

### Workspace Architecture

```
Terraform State Structure:
├── S3 Backend (shared)
│   ├── env:/london/[layer]/terraform.tfstate
│   ├── env:/sydney/[layer]/terraform.tfstate
│   └── env:/default/900-global-services/terraform.tfstate
├── DynamoDB Locks (shared)
│   ├── cutlass-tech-terraform-locks
└── Regional Configurations
    ├── vars/london.tfvars
    ├── vars/sydney.tfvars
    └── vars/global.tfvars
```

### How Workspaces Enable Multi-Region Deployment

1. **Region-Specific State Isolation**
   - Each workspace maintains its own state file
   - London: `env:/london/[layer]/terraform.tfstate`
   - Sydney: `env:/sydney/[layer]/terraform.tfstate`
   - Global: `env:/default/900-global-services/terraform.tfstate`

2. **Variable File Strategy**
   - **london.tfvars**: London-specific configurations (eu-west-2)
   - **sydney.tfvars**: Sydney-specific configurations (ap-southeast-2)
   - **global.tfvars**: Global resources (Route 53, cross-region settings)

3. **Workspace-Aware Resource Naming**
   ```hcl
   # Example: Resources automatically get workspace suffix
   resource "aws_vpc" "main" {
     cidr_block = var.vpc_cidr
     
     tags = {
       Name = "cutlass-tech-vpc-${terraform.workspace}"
       Environment = terraform.workspace
     }
   }
   ```

4. **Conditional Resource Creation**
   ```hcl
   # Example: Create Global Tables only in primary region
   resource "aws_dynamodb_global_table" "usage_credits" {
     count = terraform.workspace == "london" ? 1 : 0
     name  = "cutlass-tech-usage-credits"
     
     replica {
       region_name = "eu-west-2"
     }
     
     replica {
       region_name = "ap-southeast-2"
     }
   }
   ```

### Workspace Commands Reference

```bash
# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new <region-name>

# Switch to workspace
terraform workspace select <region-name>

# Show current workspace
terraform workspace show

# Delete workspace (careful!)
terraform workspace delete <region-name>
```

### Variable File Structure

#### London Configuration (vars/london.tfvars)
```hcl
# Regional settings
aws_region = "eu-west-2"
availability_zones = ["eu-west-2a", "eu-west-2b"]

# Network configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# Application settings
environment = "london"
primary_region = true
lambda_memory_size = 512
api_gateway_stage = "prod"

# Domain configuration
domain_name = "api-london.your-domain.com"
certificate_arn = "arn:aws:acm:eu-west-2:123456789012:certificate/..."
```

#### Sydney Configuration (vars/sydney.tfvars)
```hcl
# Regional settings
aws_region = "ap-southeast-2"
availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]

# Network configuration
vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]

# Application settings
environment = "sydney"
primary_region = false
lambda_memory_size = 512
api_gateway_stage = "prod"

# Domain configuration
domain_name = "api-sydney.your-domain.com"
certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/..."
```

#### Global Configuration (vars/global.tfvars)
```hcl
# DNS and routing
domain_name = "api.your-domain.com"
hosted_zone_id = "Z1234567890ABC"

# Regional endpoints
london_endpoint = "api-london.your-domain.com"
sydney_endpoint = "api-sydney.your-domain.com"

# Health check settings
health_check_path = "/health"
health_check_interval = 30
health_check_failure_threshold = 3

# Geo-routing configuration
geo_routing_enabled = true
```

### Best Practices for Multi-Region Workspaces

1. **Naming Conventions**
   - Use consistent workspace names: `london`, `sydney`
   - Include workspace in resource names: `${terraform.workspace}`
   - Tag all resources with workspace information

2. **State Management**
   - Always specify workspace before running terraform commands
   - Use different S3 prefixes for each workspace
   - Enable state locking with DynamoDB

3. **Variable Organization**
   - Keep region-specific variables in separate files
   - Use descriptive variable names
   - Document variable purposes and constraints

4. **Deployment Order**
   - Deploy London first (creates global resources)
   - Deploy Sydney second (consumes global resources)
   - Deploy global services last (depends on regional resources)

5. **Cross-Region References**
   ```hcl
   # Use data sources to reference resources from other regions
   data "terraform_remote_state" "london" {
     backend = "s3"
     config = {
       bucket = "cutlass-tech-terraform-state-123456789012"
       key    = "env:/london/200-compute-layer/terraform.tfstate"
       region = "eu-west-2"
     }
   }
   ```

## 🚀 Deployment Guide

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **Domain ownership** for Route 53 configuration
4. **AWS Account ID** for S3 backend configuration

### Step 1: Bootstrap (One-time setup)

```bash
# Deploy S3 backend and DynamoDB locks
cd bootstrap
terraform init
terraform apply
```

### Step 2: Base Network Layer

```bash
cd 000-base-network
terraform init -backend-config=backend-config.hcl

# Deploy London
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

### Step 3: Data Layer (DynamoDB Global Tables)

```bash
cd 100-data-layer
terraform init -backend-config=backend-config.hcl

# Deploy London FIRST (creates Global Tables)
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney SECOND (manages local resources only)
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

### Step 4: Compute Layer (Lambda Functions)

```bash
cd 200-compute-layer
terraform init -backend-config=backend-config.hcl

# Create lambda_packages directory
mkdir -p lambda_packages

# Deploy London
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

### Step 5: API Layer (API Gateway + Cognito)

```bash
cd 300-api-layer
terraform init -backend-config=backend-config.hcl

# Deploy London
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

### Step 6: Messaging Layer (SQS + SES)

```bash
cd 400-messaging-layer
terraform init -backend-config=backend-config.hcl

# Deploy London
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

### Step 7: Global Services (Route 53)

```bash
cd 900-global-services
terraform init -backend-config=backend-config.hcl

# Deploy global resources (single deployment)
terraform plan -var-file=vars/global.tfvars
terraform apply -var-file=vars/global.tfvars
```

## 🔧 Configuration

### Required Updates

Before deployment, update these configuration files:

1. **AWS Account ID**: Replace `123456789012` in all `backend-config.hcl` files

### Environment-Specific Configuration

| File | Purpose | Key Settings |
|------|---------|--------------|
| `vars/london.tfvars` | London region config | Region, subnets, domain settings |
| `vars/sydney.tfvars` | Sydney region config | Region, subnets, domain settings |
| `vars/global.tfvars` | Global DNS config | Domain, geo-routing, health checks |

## 🎯 Key Features

### Multi-Region Setup
- **London (eu-west-2)**: Primary region for European users
- **Sydney (ap-southeast-2)**: Primary region for Asia-Pacific users
- **DynamoDB Global Tables**: Bidirectional data replication

### Authentication & Authorization
- **Cognito User Pools**: OAuth 2.0 authentication per region
- **API Gateway Authorizers**: JWT token validation

### Usage Management
- **Usage Plans**: Basic, premium, enterprise tiers
- **Credit System**: Organization and user-level credits
- **Threshold Monitoring**: Automated usage alerts

### Messaging & Notifications
- **SQS Queues**: Async notification processing
- **SES Templates**: Usage alerts
- **Dead Letter Queues**: Failed message handling

### Global Routing
- **Geographic DNS**: Route users to closest region
- **Health Checks**: Automatic failover between regions
- **Multiple Strategies**: Geo, latency, and failover routing

## 📊 Monitoring & Operations

### Health Monitoring
```bash
# Check API health endpoints
curl -I https://api.your-domain.com/health

# Monitor Route 53 health checks
terraform output -state=900-global-services/terraform.tfstate monitoring_urls
```

### Logs & Debugging
```bash
# API Gateway logs
aws logs tail /aws/apigateway/cutlass-tech-api-london --region eu-west-2

# Lambda function logs  
aws logs tail /aws/lambda/cutlass-tech-usage-check-london --region eu-west-2

# DynamoDB metrics
aws cloudwatch get-metric-statistics --namespace AWS/DynamoDB --region eu-west-2
```

### Testing

```bash
# Test API endpoints
export API_URL=$(terraform output -state=300-api-layer/terraform.tfstate api_gateway_invoke_url)
curl -X POST $API_URL/usage-check \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test123","org_id":"org456"}'

# Test DNS resolution
dig api.your-domain.com @8.8.8.8
```

## 🔒 Security

### Network Security
- **Private Subnets**: Compute resources isolated from internet
- **VPC Endpoints**: Private access to AWS services
- **Security Groups**: Least-privilege network access

### Data Security
- **KMS Encryption**: All data encrypted at rest
- **DynamoDB Encryption**: Customer-managed keys
- **SQS Encryption**: Encrypted message queues

### Access Control
- **IAM Roles**: Least-privilege service permissions
- **Cognito Authentication**: JWT-based API access
- **API Gateway Throttling**: Rate limiting protection

## 💰 Cost Optimization

### Implemented Optimizations
- **Single NAT Gateway**: Per region instead of per AZ
- **PAY_PER_REQUEST**: DynamoDB billing mode
- **Lambda**: Serverless compute scaling
- **CloudWatch Logs**: 14-day retention period

### Cost Monitoring
```bash
# Estimate monthly costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-02-01 \
  --granularity MONTHLY --metrics BlendedCost
```

## 🚨 Troubleshooting

### Common Issues

#### DynamoDB Global Tables
- **Issue**: Tables not replicating between regions
- **Solution**: Ensure London deployed first, check IAM permissions

#### DNS Resolution
- **Issue**: Domain not resolving to correct region
- **Solution**: Verify nameservers, wait for DNS propagation (48h)

#### API Gateway 403 Errors
- **Issue**: Authentication failures
- **Solution**: Verify Cognito tokens, check authorizer configuration

#### Lambda Cold Starts
- **Issue**: High latency on first requests
- **Solution**: Implement provisioned concurrency for critical functions

#### Terraform Workspace Issues
- **Issue**: Resources created in wrong region
- **Solution**: Verify current workspace with `terraform workspace show`

- **Issue**: State file conflicts between regions
- **Solution**: Ensure proper backend configuration and workspace isolation

### Support Resources
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/aws/
- **CloudFormation Logs**: Check for detailed error messages

## 🔄 Maintenance

### Regular Tasks
- **Security Updates**: Update Lambda runtimes quarterly
- **Certificate Renewal**: Monitor SSL certificate expiration
- **Cost Review**: Monthly cost optimization analysis
- **Backup Verification**: Test DynamoDB point-in-time recovery

### Scaling Considerations
- **Add Regions**: Replicate layer structure for new regions
- **Increase Capacity**: Adjust Lambda memory/timeout as needed
- **Database Scaling**: Monitor DynamoDB capacity and auto-scaling

## 🎉 Success Criteria

After successful deployment, you should have:

✅ **Global DNS routing** based on user location  
✅ **Regional API endpoints** with authentication  
✅ **Bidirectional data replication** between regions  
✅ **Automated usage monitoring** and notifications  
✅ **Health checks** with automatic failover  
✅ **Encrypted data** at rest and in transit  
✅ **Monitoring and logging** across all components

Your multi-region reporting application infrastructure is now ready for production! 🚀