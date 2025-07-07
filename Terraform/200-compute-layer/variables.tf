variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-west-2"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "cutlass-tech"
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

# Lambda Environment Variables
variable "lambda_log_level" {
  description = "Log level for Lambda functions"
  type        = string
  default     = "INFO"
}

# Fallback table names (used if remote state not available)
variable "usage_plans_table_name" {
  description = "Fallback name for usage plans table"
  type        = string
  default     = "usage-plans"
}

variable "organizations_table_name" {
  description = "Fallback name for organizations table"
  type        = string
  default     = "organizations"
}

variable "users_table_name" {
  description = "Fallback name for users table"
  type        = string
  default     = "users"
}