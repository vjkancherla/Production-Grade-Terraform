# Remote state from 000-base-network layer
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "000-base-network/env:/${terraform.workspace}/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Remote state from 100-data-layer
data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "100-data-layer/env:/${terraform.workspace}/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Local values for easy reference
locals {
  vpc_id              = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids  = data.terraform_remote_state.network.outputs.private_subnet_ids
  
  # DynamoDB table names from data layer (or construct if not available in replica regions)
  usage_plans_table   = try(data.terraform_remote_state.data.outputs.usage_plans_table_name, "${var.project_name}-${var.usage_plans_table_name}")
  organizations_table = try(data.terraform_remote_state.data.outputs.organizations_table_name, "${var.project_name}-${var.organizations_table_name}")
  users_table        = try(data.terraform_remote_state.data.outputs.users_table_name, "${var.project_name}-${var.users_table_name}")
}