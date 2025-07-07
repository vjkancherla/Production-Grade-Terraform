# Remote state from 300-api-layer (London)
data "terraform_remote_state" "api_london" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "300-api-layer/env:/london/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Remote state from 300-api-layer (Sydney)
data "terraform_remote_state" "api_sydney" {
  backend = "s3"
  config = {
    bucket = "${var.aws_account_id}-tf-state-${var.project_name}"
    key    = "300-api-layer/env:/sydney/terraform.tfstate"
    region = "eu-west-2"
  }
}

# Local values for easy reference
locals {
  # API Gateway endpoints from each region
  london_api_gateway_id               = data.terraform_remote_state.api_london.outputs.api_gateway_id
  london_api_gateway_invoke_url       = data.terraform_remote_state.api_london.outputs.api_gateway_invoke_url
  london_custom_domain_target         = try(data.terraform_remote_state.api_london.outputs.custom_domain_target_domain_name, null)
  london_custom_domain_hosted_zone_id = try(data.terraform_remote_state.api_london.outputs.custom_domain_hosted_zone_id, null)
  
  sydney_api_gateway_id               = data.terraform_remote_state.api_sydney.outputs.api_gateway_id
  sydney_api_gateway_invoke_url       = data.terraform_remote_state.api_sydney.outputs.api_gateway_invoke_url
  sydney_custom_domain_target         = try(data.terraform_remote_state.api_sydney.outputs.custom_domain_target_domain_name, null)
  sydney_custom_domain_hosted_zone_id = try(data.terraform_remote_state.api_sydney.outputs.custom_domain_hosted_zone_id, null)
  
  # Extract domain names from invoke URLs for health checks
  london_api_domain = replace(local.london_api_gateway_invoke_url, "https://", "")
  sydney_api_domain = replace(local.sydney_api_gateway_invoke_url, "https://", "")
  
  # Determine endpoints for routing
  london_endpoint = local.london_custom_domain_target != null ? local.london_custom_domain_target : local.london_api_domain
  sydney_endpoint = local.sydney_custom_domain_target != null ? local.sydney_custom_domain_target : local.sydney_api_domain
  
  # Hosted zone ID for alias records
  london_hosted_zone_id = local.london_custom_domain_hosted_zone_id != null ? local.london_custom_domain_hosted_zone_id : "Z1BKCTXD74EZPE"  # API Gateway London
  sydney_hosted_zone_id = local.sydney_custom_domain_hosted_zone_id != null ? local.sydney_custom_domain_hosted_zone_id : "Z2RPCDW04V8134"  # API Gateway Sydney
}