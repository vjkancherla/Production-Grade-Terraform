# API Gateway Outputs
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

# API Endpoints
output "api_endpoints" {
  description = "API endpoint URLs"
  value = {
    usage_check     = "${aws_api_gateway_stage.main.invoke_url}/usage-check"
    post_processing = "${aws_api_gateway_stage.main.invoke_url}/post-processing"
    credits         = "${aws_api_gateway_stage.main.invoke_url}/credits"
  }
}

# Cognito Outputs
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
  sensitive   = true
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_hosted_ui_url" {
  description = "Cognito Hosted UI URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}

# Authentication Configuration
output "auth_config" {
  description = "Authentication configuration for frontend applications"
  value = {
    user_pool_id        = aws_cognito_user_pool.main.id
    user_pool_client_id = aws_cognito_user_pool_client.main.id
    region              = var.region
    hosted_ui_domain    = aws_cognito_user_pool_domain.main.domain
    oauth_domain        = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
  }
  sensitive = true
}

# Custom Domain (if configured)
output "custom_domain_name" {
  description = "Custom domain name for API Gateway"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].domain_name : null
}

output "custom_domain_target_domain_name" {
  description = "Target domain name for Route 53 alias record"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].regional_domain_name : null
}

output "custom_domain_hosted_zone_id" {
  description = "Hosted zone ID for Route 53 alias record"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.main[0].regional_zone_id : null
}

# CloudWatch Log Group
output "api_gateway_log_group_name" {
  description = "Name of the API Gateway CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "api_gateway_log_group_arn" {
  description = "ARN of the API Gateway CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway.arn
}

# API Gateway Authorizer
output "api_gateway_authorizer_id" {
  description = "ID of the Cognito authorizer"
  value       = aws_api_gateway_authorizer.cognito.id
}

# Integration Information
output "lambda_integrations" {
  description = "Lambda function integrations"
  value = {
    usage_check = {
      lambda_arn  = local.usage_check_lambda_arn
      api_method  = "POST"
      api_path    = "/usage-check"
    }
    post_processing = {
      lambda_arn  = local.post_processing_lambda_arn
      api_method  = "POST"
      api_path    = "/post-processing"
    }
    credits = {
      lambda_arn  = local.credit_topup_lambda_arn
      api_method  = "POST"
      api_path    = "/credits"
    }
  }
}