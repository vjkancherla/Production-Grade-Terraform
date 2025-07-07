# Get current AWS account ID and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===== COGNITO USER POOL =====

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.cognito_user_pool_name}-${var.region}"

  # Password policy
  password_policy {
    minimum_length    = var.cognito_password_policy.minimum_length
    require_lowercase = var.cognito_password_policy.require_lowercase
    require_numbers   = var.cognito_password_policy.require_numbers
    require_symbols   = var.cognito_password_policy.require_symbols
    require_uppercase = var.cognito_password_policy.require_uppercase
  }

  # MFA configuration
  mfa_configuration = var.cognito_mfa_configuration

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attributes
  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }

  schema {
    attribute_data_type = "String"
    name               = "org_id"
    required           = false
    mutable           = true
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  tags = {
    Name = "${var.project_name}-${var.cognito_user_pool_name}-${var.region}"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-api-client-${var.region}"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials", "authorization_code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  # Callback URLs (update these with your actual frontend URLs)
  callback_urls = ["https://example.com/callback"]
  logout_urls   = ["https://example.com/logout"]

  # Token validity
  access_token_validity  = 60  # 1 hour
  id_token_validity     = 60  # 1 hour
  refresh_token_validity = 30  # 30 days

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-auth-${var.region}-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "random_id" "domain_suffix" {
  byte_length = 4
}

# ===== API GATEWAY =====

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api-${var.region}"
  description = "Multi-region reporting application API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-api-${var.region}"
  }
}

# API Gateway Authorizer (Cognito)
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.project_name}-cognito-authorizer-${var.region}"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]
}

# ===== API RESOURCES AND METHODS =====

# /usage-check resource
resource "aws_api_gateway_resource" "usage_check" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "usage-check"
}

resource "aws_api_gateway_method" "usage_check_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.usage_check.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "usage_check" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.usage_check.id
  http_method = aws_api_gateway_method.usage_check_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = local.usage_check_lambda_arn
}

# /post-processing resource
resource "aws_api_gateway_resource" "post_processing" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "post-processing"
}

resource "aws_api_gateway_method" "post_processing_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.post_processing.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "post_processing" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.post_processing.id
  http_method = aws_api_gateway_method.post_processing_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = local.post_processing_lambda_arn
}

# /credits resource (for credit top-up)
resource "aws_api_gateway_resource" "credits" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "credits"
}

resource "aws_api_gateway_method" "credits_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.credits.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "credits" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.credits.id
  http_method = aws_api_gateway_method.credits_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = local.credit_topup_lambda_arn
}

# ===== LAMBDA PERMISSIONS =====

# Lambda permission for API Gateway to invoke usage-check function
resource "aws_lambda_permission" "usage_check_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = local.usage_check_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke post-processing function
resource "aws_lambda_permission" "post_processing_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = local.post_processing_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke credit top-up function
resource "aws_lambda_permission" "credits_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = local.credit_topup_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ===== API GATEWAY DEPLOYMENT =====

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.usage_check_post,
    aws_api_gateway_method.post_processing_post,
    aws_api_gateway_method.credits_post,
    aws_api_gateway_integration.usage_check,
    aws_api_gateway_integration.post_processing,
    aws_api_gateway_integration.credits
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.usage_check.id,
      aws_api_gateway_method.usage_check_post.id,
      aws_api_gateway_integration.usage_check.id,
      aws_api_gateway_resource.post_processing.id,
      aws_api_gateway_method.post_processing_post.id,
      aws_api_gateway_integration.post_processing.id,
      aws_api_gateway_resource.credits.id,
      aws_api_gateway_method.credits_post.id,
      aws_api_gateway_integration.credits.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.api_gateway_stage_name

  # Throttling
  throttle_settings {
    rate_limit  = var.api_gateway_throttle_rate_limit
    burst_limit = var.api_gateway_throttle_burst_limit
  }

  # Logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = "$requestId $status $error.message" 
  }

  tags = {
    Name = "${var.project_name}-api-stage-${var.region}"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-api-${var.region}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-api-logs-${var.region}"
  }
}