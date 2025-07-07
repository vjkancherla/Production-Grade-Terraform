# Add these outputs to your 100-data-layer/outputs.tf

# Table Names (conditional based on whether tables exist in this region)
output "usage_plans_table_name" {
  description = "Name of the usage plans DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.usage_plans[0].name : "${var.project_name}-${var.usage_plans_table_name}"
}

output "organizations_table_name" {
  description = "Name of the organizations DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.organizations[0].name : "${var.project_name}-${var.organizations_table_name}"
}

output "users_table_name" {
  description = "Name of the users DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.users[0].name : "${var.project_name}-${var.users_table_name}"
}

# Table ARNs (conditional based on whether tables exist in this region)
output "usage_plans_table_arn" {
  description = "ARN of the usage plans DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.usage_plans[0].arn : "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.usage_plans_table_name}"
}

output "organizations_table_arn" {
  description = "ARN of the organizations DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.organizations[0].arn : "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.organizations_table_name}"
}

output "users_table_arn" {
  description = "ARN of the users DynamoDB table"
  value       = var.is_primary_region ? aws_dynamodb_table.users[0].arn : "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-${var.users_table_name}"
}