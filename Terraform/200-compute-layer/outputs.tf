# Lambda Function ARNs
output "usage_check_lambda_arn" {
  description = "ARN of the usage check Lambda function"
  value       = aws_lambda_function.usage_check.arn
}

output "usage_check_lambda_name" {
  description = "Name of the usage check Lambda function"
  value       = aws_lambda_function.usage_check.function_name
}

output "post_processing_lambda_arn" {
  description = "ARN of the post-processing Lambda function"
  value       = aws_lambda_function.post_processing.arn
}

output "post_processing_lambda_name" {
  description = "Name of the post-processing Lambda function"
  value       = aws_lambda_function.post_processing.function_name
}

output "credit_topup_lambda_arn" {
  description = "ARN of the credit top-up Lambda function"
  value       = aws_lambda_function.credit_topup.arn
}

output "credit_topup_lambda_name" {
  description = "Name of the credit top-up Lambda function"
  value       = aws_lambda_function.credit_topup.function_name
}

output "notification_lambda_arn" {
  description = "ARN of the notification Lambda function"
  value       = aws_lambda_function.notification.arn
}

output "notification_lambda_name" {
  description = "Name of the notification Lambda function"
  value       = aws_lambda_function.notification.function_name
}

# IAM Role
output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_base.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda_base.name
}

# Security Group
output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
}

# KMS Key
output "lambda_kms_key_arn" {
  description = "ARN of the Lambda KMS key"
  value       = aws_kms_key.lambda.arn
}

output "lambda_kms_key_id" {
  description = "ID of the Lambda KMS key"
  value       = aws_kms_key.lambda.key_id
}