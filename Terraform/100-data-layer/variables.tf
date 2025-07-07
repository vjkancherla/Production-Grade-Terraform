variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "cutlass-tech"
}

# DynamoDB Configuration
variable "usage_plans_table_name" {
  description = "Name of the usage plans DynamoDB table"
  type        = string
  default     = "usage-plans"
}

variable "organizations_table_name" {
  description = "Name of the organizations DynamoDB table"
  type        = string
  default     = "organizations"
}

variable "users_table_name" {
  description = "Name of the users DynamoDB table"
  type        = string
  default     = "users"
}

# DynamoDB Settings
variable "billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection for DynamoDB tables"
  type        = bool
  default     = true
}

# Global Tables Configuration
variable "is_primary_region" {
  description = "Whether this is the primary region for Global Tables setup"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "The replica region for Global Tables (only used if is_primary_region is true)"
  type        = string
  default     = ""
}

