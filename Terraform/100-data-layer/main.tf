# Get current AWS account ID for ARN construction in replica regions
data "aws_caller_identity" "current" {}

# KMS Key for DynamoDB encryption
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption - ${var.project_name} - ${var.region}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-dynamodb-key-${var.region}"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-dynamodb-${var.region}"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# Usage Plans Table
# Stores different plan types (basic, premium, enterprise) with their limits
# Only create in primary region - Global Tables will replicate to other regions
resource "aws_dynamodb_table" "usage_plans" {
  count = var.is_primary_region ? 1 : 0
  name         = "${var.project_name}-${var.usage_plans_table_name}"
  billing_mode = var.billing_mode
  hash_key     = "plan_id"

  attribute {
    name = "plan_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  # Global Tables replica configuration
  replica {
    region_name = var.region
    
    server_side_encryption {
      enabled     = true
      kms_key_arn = aws_kms_key.dynamodb.arn
    }

    point_in_time_recovery {
      enabled = var.point_in_time_recovery
    }
  }

  # Add replica for the other region if this is the primary region
  dynamic "replica" {
    for_each = var.is_primary_region ? [var.replica_region] : []
    content {
      region_name = replica.value
      
      server_side_encryption {
        enabled = true
        # Note: You'll need to create KMS keys in both regions or use AWS managed keys
        # For simplicity, using AWS managed key in replica region
        kms_key_arn = "alias/aws/dynamodb"
      }

      point_in_time_recovery {
        enabled = var.point_in_time_recovery
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.usage_plans_table_name}"
    Type = "UsagePlans"
  }
}

# Organizations Table
# Stores organization information and their assigned plan with credit management
# Only create in primary region - Global Tables will replicate to other regions
resource "aws_dynamodb_table" "organizations" {
  count = var.is_primary_region ? 1 : 0
  name         = "${var.project_name}-${var.organizations_table_name}"
  billing_mode = var.billing_mode
  hash_key     = "org_id"

  attribute {
    name = "org_id"
    type = "S"
  }

  attribute {
    name = "plan_id"
    type = "S"
  }

  global_secondary_index {
    name     = "plan-index"
    hash_key = "plan_id"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  # Global Tables replica configuration
  replica {
    region_name = var.region
    
    server_side_encryption {
      enabled     = true
      kms_key_arn = aws_kms_key.dynamodb.arn
    }

    point_in_time_recovery {
      enabled = var.point_in_time_recovery
    }

    # GSI configuration for replica
    global_secondary_index {
      name     = "plan-index"
      hash_key = "plan_id"
    }
  }

  # Add replica for the other region if this is the primary region
  dynamic "replica" {
    for_each = var.is_primary_region ? [var.replica_region] : []
    content {
      region_name = replica.value
      
      server_side_encryption {
        enabled = true
        kms_key_arn = "alias/aws/dynamodb"
      }

      point_in_time_recovery {
        enabled = var.point_in_time_recovery
      }

      # GSI configuration for replica
      global_secondary_index {
        name     = "plan-index"
        hash_key = "plan_id"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.organizations_table_name}"
    Type = "Organizations"
    Description = "Organization info with plan assignment and credit management"
  }
}

# Users Table
# Stores user information linked to organizations with individual usage limits, counters, and credits
# Only create in primary region - Global Tables will replicate to other regions
resource "aws_dynamodb_table" "users" {
  count = var.is_primary_region ? 1 : 0
  name         = "${var.project_name}-${var.users_table_name}"
  billing_mode = var.billing_mode
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "org_id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name     = "org-index"
    hash_key = "org_id"
  }

  global_secondary_index {
    name     = "email-index"
    hash_key = "email"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection

  # Global Tables replica configuration
  replica {
    region_name = var.region
    
    server_side_encryption {
      enabled     = true
      kms_key_arn = aws_kms_key.dynamodb.arn
    }

    point_in_time_recovery {
      enabled = var.point_in_time_recovery
    }

    # GSI configuration for replica
    global_secondary_index {
      name     = "org-index"
      hash_key = "org_id"
    }

    global_secondary_index {
      name     = "email-index"
      hash_key = "email"
    }
  }

  # Add replica for the other region if this is the primary region
  dynamic "replica" {
    for_each = var.is_primary_region ? [var.replica_region] : []
    content {
      region_name = replica.value
      
      server_side_encryption {
        enabled = true
        kms_key_arn = "alias/aws/dynamodb"
      }

      point_in_time_recovery {
        enabled = var.point_in_time_recovery
      }

      # GSI configuration for replica
      global_secondary_index {
        name     = "org-index"
        hash_key = "org_id"
      }

      global_secondary_index {
        name     = "email-index"
        hash_key = "email"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.users_table_name}"
    Type = "Users"
    Description = "User info with individual usage limits, counters, and credit management"
  }
}

# DynamoDB VPC Endpoint (for private access)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.terraform_remote_state.network.outputs.private_route_table_ids
  policy            = data.aws_iam_policy_document.dynamodb_vpc_endpoint.json

  tags = {
    Name = "${var.project_name}-dynamodb-endpoint-${var.region}"
  }
}

# IAM policy for DynamoDB VPC endpoint
data "aws_iam_policy_document" "dynamodb_vpc_endpoint" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeTable"
    ]
    resources = var.is_primary_region ? [
      aws_dynamodb_table.usage_plans[0].arn,
      aws_dynamodb_table.organizations[0].arn,
      aws_dynamodb_table.users[0].arn,
      "${aws_dynamodb_table.usage_plans[0].arn}/*",
      "${aws_dynamodb_table.organizations[0].arn}/*",
      "${aws_dynamodb_table.users[0].arn}/*"
    ] : [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.usage_plans_table_name}",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.organizations_table_name}",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.users_table_name}",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.usage_plans_table_name}/*",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.organizations_table_name}/*",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.users_table_name}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [local.vpc_id]
    }
  }
}