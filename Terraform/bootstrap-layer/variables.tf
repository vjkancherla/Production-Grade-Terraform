# AWS account on which to operate
variable "aws_account_id" {
  description = "The ID of the AWS Account to apply changes to."
  type        = string
}

# AWS region in which to create the state resources
variable "region" {
  description = "AWS region in which to create the state resources"
  type        = string
  default     = "eu-west-2"
}

# Project name for resource naming
variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "cutlass-tech"
}