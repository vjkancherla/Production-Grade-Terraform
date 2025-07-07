# Backend configuration for all workspaces
# Usage: terraform init -backend-config=backend-config.hcl

bucket         = "123456789012-tf-state-cutlass-tech"
key            = "100-data-layer/terraform.tfstate"
region         = "eu-west-2"
dynamodb_table = "terraform_lock_123456789012_multi_region_app"
encrypt        = true

# Note: Replace the bucket name and dynamodb_table with actual values from your bootstrap layer:
# - bucket: {aws_account_id}-tf-state-{project_name}
# - dynamodb_table: terraform_lock_{aws_account_id}_{project_name}
#
# Terraform workspaces automatically create separate state paths:
# - london workspace: 100-data-layer/env:/london/terraform.tfstate
# - sydney workspace: 100-data-layer/env:/sydney/terraform.tfstate