# Get current AWS account ID and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Key for Lambda environment variables encryption
resource "aws_kms_key" "lambda" {
  description             = "KMS key for Lambda encryption - ${var.project_name} - ${var.region}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-lambda-key-${var.region}"
  }
}

resource "aws_kms_alias" "lambda" {
  name          = "alias/${var.project_name}-lambda-${var.region}"
  target_key_id = aws_kms_key.lambda.key_id
}

# ===== IAM ROLES AND POLICIES =====

# Base IAM role for Lambda functions
resource "aws_iam_role" "lambda_base" {
  name = "${var.project_name}-lambda-base-role-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_base.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCExecutionRole"
}

# DynamoDB access policy for Lambda functions
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.project_name}-lambda-dynamodb-${var.region}"
  description = "DynamoDB access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          try(data.terraform_remote_state.data.outputs.usage_plans_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.usage_plans_table}"),
          try(data.terraform_remote_state.data.outputs.organizations_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.organizations_table}"),
          try(data.terraform_remote_state.data.outputs.users_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.users_table}"),
          "${try(data.terraform_remote_state.data.outputs.usage_plans_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.usage_plans_table}")}/index/*",
          "${try(data.terraform_remote_state.data.outputs.organizations_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.organizations_table}")}/index/*",
          "${try(data.terraform_remote_state.data.outputs.users_table_arn, "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${local.users_table}")}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_base.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

# KMS access policy for Lambda functions
resource "aws_iam_policy" "lambda_kms" {
  name        = "${var.project_name}-lambda-kms-${var.region}"
  description = "KMS access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.lambda.arn,
          try(data.terraform_remote_state.data.outputs.dynamodb_kms_key_arn, "alias/aws/dynamodb")
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  role       = aws_iam_role.lambda_base.name
  policy_arn = aws_iam_policy.lambda_kms.arn
}

# ===== LAMBDA SECURITY GROUP =====

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg-${var.region}"
  description = "Security group for Lambda functions"
  vpc_id      = local.vpc_id

  # Outbound HTTPS for API calls and DynamoDB
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # Outbound DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS outbound"
  }

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.region}"
  }
}

# ===== LAMBDA FUNCTIONS =====

# 1. Usage Check Lambda
data "archive_file" "usage_check" {
  type        = "zip"
  output_path = "${path.module}/lambda_packages/usage_check.zip"
  source {
    content = file("${path.module}/lambda_functions/usage_check.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "usage_check" {
  function_name = "${var.project_name}-usage-check-${var.region}"
  role         = aws_iam_role.lambda_base.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = data.archive_file.usage_check.output_path
  source_code_hash = data.archive_file.usage_check.output_base64sha256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      USAGE_PLANS_TABLE    = local.usage_plans_table
      ORGANIZATIONS_TABLE  = local.organizations_table
      USERS_TABLE         = local.users_table
      LOG_LEVEL           = var.lambda_log_level
      REGION              = var.region
    }
  }

  kms_key_arn = aws_kms_key.lambda.arn

  tags = {
    Name        = "${var.project_name}-usage-check-${var.region}"
    Function    = "UsageCheck"
    Description = "Validates usage limits before report execution"
  }
}

# 2. Post-Processing Lambda
data "archive_file" "post_processing" {
  type        = "zip"
  output_path = "${path.module}/lambda_packages/post_processing.zip"
  source {
    content = file("${path.module}/lambda_functions/post_processing.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "post_processing" {
  function_name = "${var.project_name}-post-processing-${var.region}"
  role         = aws_iam_role.lambda_base.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = data.archive_file.post_processing.output_path
  source_code_hash = data.archive_file.post_processing.output_base64sha256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      USAGE_PLANS_TABLE    = local.usage_plans_table
      ORGANIZATIONS_TABLE  = local.organizations_table
      USERS_TABLE         = local.users_table
      LOG_LEVEL           = var.lambda_log_level
      REGION              = var.region
    }
  }

  kms_key_arn = aws_kms_key.lambda.arn

  tags = {
    Name        = "${var.project_name}-post-processing-${var.region}"
    Function    = "PostProcessing"
    Description = "Handles report completion workflows"
  }
}

# 3. Credit Top-up Lambda
data "archive_file" "credit_topup" {
  type        = "zip"
  output_path = "${path.module}/lambda_packages/credit_topup.zip"
  source {
    content = file("${path.module}/lambda_functions/credit_topup.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "credit_topup" {
  function_name = "${var.project_name}-credit-topup-${var.region}"
  role         = aws_iam_role.lambda_base.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = data.archive_file.credit_topup.output_path
  source_code_hash = data.archive_file.credit_topup.output_base64sha256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      USAGE_PLANS_TABLE    = local.usage_plans_table
      ORGANIZATIONS_TABLE  = local.organizations_table
      USERS_TABLE         = local.users_table
      LOG_LEVEL           = var.lambda_log_level
      REGION              = var.region
    }
  }

  kms_key_arn = aws_kms_key.lambda.arn

  tags = {
    Name        = "${var.project_name}-credit-topup-${var.region}"
    Function    = "CreditTopup"
    Description = "Manages ad-hoc credit additions"
  }
}

# 4. Notification Lambda
data "archive_file" "notification" {
  type        = "zip"
  output_path = "${path.module}/lambda_packages/notification.zip"
  source {
    content = file("${path.module}/lambda_functions/notification.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "notification" {
  function_name = "${var.project_name}-notification-${var.region}"
  role         = aws_iam_role.lambda_base.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = var.lambda_runtime
  timeout      = var.lambda_timeout
  memory_size  = var.lambda_memory_size

  filename         = data.archive_file.notification.output_path
  source_code_hash = data.archive_file.notification.output_base64sha256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      USAGE_PLANS_TABLE    = local.usage_plans_table
      ORGANIZATIONS_TABLE  = local.organizations_table
      USERS_TABLE         = local.users_table
      LOG_LEVEL           = var.lambda_log_level
      REGION              = var.region
    }
  }

  kms_key_arn = aws_kms_key.lambda.arn

  tags = {
    Name        = "${var.project_name}-notification-${var.region}"
    Function    = "Notification"
    Description = "Processes SQS messages for customer alerts"
  }
}