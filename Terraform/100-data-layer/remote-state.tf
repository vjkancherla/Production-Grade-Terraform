# Remote state data source for 000-base-network layer
# This allows us to read networking outputs from the base network layer

data "terraform_remote_state" "network" {
  backend = "s3"
  
  config = {
    bucket         = "123456789012-tf-state-cutlass-tech"  # Replace with actual values
    key            = "000-base-network/env:/${terraform.workspace}/terraform.tfstate"
    region         = "eu-west-2"  # Region where bootstrap layer was deployed
    dynamodb_table = "terraform_lock_123456789012_multi_region_app"  # Replace with actual values
  }
}

# Local values derived from network state
locals {
  network_outputs = data.terraform_remote_state.network.outputs
  
  # Network information from base layer
  vpc_id                = local.network_outputs.vpc_id
  vpc_cidr_block        = local.network_outputs.vpc_cidr_block
  private_subnet_ids    = local.network_outputs.private_subnet_ids
  public_subnet_ids     = local.network_outputs.public_subnet_ids
  availability_zones    = local.network_outputs.availability_zones
  
  # Derived values for DynamoDB VPC endpoints (if needed)
  subnet_ids_for_vpc_endpoint = local.network_outputs.private_subnet_ids
}