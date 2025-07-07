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

# SQS Configuration
variable "sqs_visibility_timeout_seconds" {
  description = "SQS message visibility timeout in seconds"
  type        = number
  default     = 300
}

variable "sqs_message_retention_seconds" {
  description = "SQS message retention period in seconds"
  type        = number
  default     = 1209600  # 14 days
}

variable "sqs_receive_wait_time_seconds" {
  description = "SQS long polling wait time in seconds"
  type        = number
  default     = 20
}

variable "sqs_max_receive_count" {
  description = "Maximum number of times a message can be received before moving to DLQ"
  type        = number
  default     = 3
}

# SES Configuration
variable "ses_from_email" {
  description = "Default 'from' email address for SES"
  type        = string
  default     = "noreply@example.com"
}

variable "ses_reply_to_email" {
  description = "Default 'reply-to' email address for SES"
  type        = string
  default     = "support@example.com"
}

variable "ses_verified_domains" {
  description = "List of domains to verify in SES"
  type        = list(string)
  default     = ["example.com"]
}

variable "ses_verified_emails" {
  description = "List of email addresses to verify in SES"
  type        = list(string)
  default     = ["admin@example.com"]
}

# Email Template Configuration
variable "enable_email_templates" {
  description = "Enable creation of SES email templates"
  type        = bool
  default     = true
}