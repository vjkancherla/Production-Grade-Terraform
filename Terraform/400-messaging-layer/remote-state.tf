# Remote state from 000-base-network layer
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "000-base-network/env:/${terraform.workspace}/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Remote state from 200-compute-layer
data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "200-compute-layer/env:/${terraform.workspace}/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Local values for easy reference
locals {
  vpc_id              = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids  = data.terraform_remote_state.network.outputs.private_subnet_ids
  
  # Lambda function references for SQS triggers
  notification_lambda_arn  = data.terraform_remote_state.compute.outputs.notification_lambda_arn
  notification_lambda_name = data.terraform_remote_state.compute.outputs.notification_lambda_name
}