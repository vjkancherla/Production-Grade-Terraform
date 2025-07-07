# 000-base-network - VPC Infrastructure

This layer creates the foundational networking infrastructure for the multi-region reporting application, including VPC, subnets, NAT gateways, and security monitoring.

## Resources Created

### Core Networking
- **VPC** with DNS resolution and hostnames enabled
- **Internet Gateway** for public internet access
- **Public Subnets** across multiple availability zones with auto-assign public IPs
- **Private Subnets** across multiple availability zones for secure workloads
- **NAT Gateway(s)** for private subnet internet access (configurable: single or per-AZ)
- **Route Tables** with proper associations for public and private traffic

### Security & Monitoring
- **VPC Flow Logs** with CloudWatch integration for network monitoring
- **CloudWatch Log Group** with 14-day retention for flow logs
- **IAM Roles and Policies** for VPC Flow Logs service

## Configuration Options

### Networking
- **VPC CIDR:** Configurable (default: 10.0.0.0/16 for London, 10.1.0.0/16 for Sydney)
- **Availability Zones:** Configurable count (default: 2)
- **Subnet CIDRs:** Separate ranges for public and private subnets
- **NAT Strategy:** Single NAT (cost-optimized) or per-AZ NAT (high availability)

### Regional Differences
- **London (eu-west-2):** 10.0.x.x CIDR range
- **Sydney (ap-southeast-2):** 10.1.x.x CIDR range
- Non-overlapping IP ranges to avoid conflicts

## Features

### Cost Optimization
- **Single NAT Gateway option** saves ~$45/month per region
- **14-day flow log retention** balances observability with storage costs
- **On-demand resource sizing** with no over-provisioning

### High Availability
- **Multi-AZ deployment** across 2 availability zones
- **Separate public/private subnets** in each AZ
- **Optional per-AZ NAT gateways** for redundancy

### Security
- **Private subnets** for compute workloads (Lambda, EKS)
- **Public subnets** only for load balancers and NAT gateways
- **VPC Flow Logs** for network traffic monitoring and security analysis
- **Proper route table isolation** between public and private networks

## Architecture

```
VPC (10.x.0.0/16)
├── Public Subnets (10.x.1.0/24, 10.x.2.0/24)
│   ├── Internet Gateway
│   ├── NAT Gateway(s)
│   └── Future: Application Load Balancers
└── Private Subnets (10.x.11.0/24, 10.x.12.0/24)
    ├── Future: EKS Worker Nodes
    ├── Future: Lambda Functions (VPC mode)
    └── Route to NAT Gateway for internet access
```

## Usage

**Deploy to London:**
```bash
# Initialize with backend configuration
terraform init -backend-config=backend-config.hcl

# Create and switch to London workspace
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars
```

**Deploy to Sydney:**
```bash
# Create and switch to Sydney workspace
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

**Switch between workspaces:**
```bash
terraform workspace select london
terraform workspace select sydney
terraform workspace list
```

## File Structure

```
000-base-network/
├── backend-config.hcl    # S3 backend configuration (shared)
├── backend.tf            # Backend block (static)
├── main.tf              # VPC, subnets, NAT, flow logs
├── outputs.tf           # Network info for other layers
├── variables.tf         # Input variables with defaults
├── versions.tf          # Provider and Terraform constraints
└── vars/
    ├── london.tfvars    # London-specific values
    └── sydney.tfvars    # Sydney-specific values
```

## Dependencies

**Required:**
- Bootstrap layer must be deployed first (provides S3 backend)
- AWS credentials with VPC creation permissions

