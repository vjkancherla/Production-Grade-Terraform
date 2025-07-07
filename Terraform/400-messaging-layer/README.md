# 400-messaging-layer

SQS queuing and SES email services for the multi-region reporting application.

## Overview

This layer creates:
- **SQS Queues** for async message processing
- **SES Email Service** with templates and verification
- **Lambda Triggers** for automated processing
- **KMS Encryption** for all messaging services

## Architecture

```
Post-Processing → notification-check-queue → Notification Lambda → SES Email
                                                                     ↓
EKS/API Gateway → report-processing-queue → (Future EKS Integration)
```

## SQS Queues

| Queue | Purpose | Trigger | Message Types |
|-------|---------|---------|---------------|
| `notification-check-queue` | Check if notifications needed | Notification Lambda | usage_updates, threshold_checks |

## Email Templates

- **usage-threshold-alert**: 80%/90%/100% usage warnings
- **credit-topup-confirmation**: Credit addition confirmations  
- **report-ready**: Download links for completed reports

## Dependencies

- **000-base-network**: VPC configuration
- **200-compute-layer**: Notification Lambda function

## Configuration

### London
```bash
terraform workspace select london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars
```

### Sydney
```bash
terraform workspace select sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars
```

## Message Flow

1. **Usage Update**: Post-processing Lambda sends message to notification-check-queue
2. **Threshold Check**: Notification Lambda processes message, checks usage thresholds
3. **Email Sending**: If threshold exceeded, sends templated email via SES
4. **Error Handling**: Failed messages go to dead letter queues

