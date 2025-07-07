# SQS Queue Outputs
output "notification_check_queue_arn" {
  description = "ARN of the notification check SQS queue"
  value       = aws_sqs_queue.notification_check.arn
}

output "notification_check_queue_url" {
  description = "URL of the notification check SQS queue"
  value       = aws_sqs_queue.notification_check.url
}

output "notification_check_queue_name" {
  description = "Name of the notification check SQS queue"
  value       = aws_sqs_queue.notification_check.name
}

output "notification_check_dlq_arn" {
  description = "ARN of the notification check dead letter queue"
  value       = aws_sqs_queue.notification_check_dlq.arn
}

# SES Outputs
output "ses_domain_identities" {
  description = "List of verified SES domain identities"
  value       = aws_ses_domain_identity.main[*].domain
}

output "ses_email_identities" {
  description = "List of verified SES email identities"
  value       = aws_ses_email_identity.main[*].email
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}

output "ses_configuration_set_arn" {
  description = "ARN of the SES configuration set"
  value       = aws_ses_configuration_set.main.arn
}

# SES Template Outputs
output "ses_template_names" {
  description = "Names of created SES email templates"
  value = var.enable_email_templates ? {
    usage_threshold_alert     = aws_ses_template.usage_threshold_alert[0].name
    credit_topup_confirmation = aws_ses_template.credit_topup_confirmation[0].name
    report_ready             = aws_ses_template.report_ready[0].name
  } : {}
}

# KMS Key Outputs
output "messaging_kms_key_arn" {
  description = "ARN of the messaging KMS key"
  value       = aws_kms_key.messaging.arn
}

output "messaging_kms_key_id" {
  description = "ID of the messaging KMS key"
  value       = aws_kms_key.messaging.key_id
}

output "messaging_kms_alias_name" {
  description = "Name of the messaging KMS key alias"
  value       = aws_kms_alias.messaging.name
}

# IAM Policy Outputs
output "lambda_sqs_access_policy_arn" {
  description = "ARN of the Lambda SQS access policy"
  value       = aws_iam_policy.lambda_sqs_access.arn
}

output "lambda_ses_access_policy_arn" {
  description = "ARN of the Lambda SES access policy"
  value       = aws_iam_policy.lambda_ses_access.arn
}

# Integration Information
output "queue_integrations" {
  description = "SQS queue integration information"
  value = {
    notification_check = {
      queue_arn        = aws_sqs_queue.notification_check.arn
      queue_url        = aws_sqs_queue.notification_check.url
      lambda_trigger   = local.notification_lambda_name
      message_types    = ["usage_updates", "threshold_checks"]
    }
    report_processing = {
      queue_arn        = aws_sqs_queue.report_processing.arn
      queue_url        = aws_sqs_queue.report_processing.url
      lambda_trigger   = "future_eks_integration"
      message_types    = ["report_requests"]
    }
  }
}

# Email Configuration
output "email_config" {
  description = "Email configuration for applications"
  value = {
    from_email          = var.ses_from_email
    reply_to_email      = var.ses_reply_to_email
    configuration_set   = aws_ses_configuration_set.main.name
    verified_domains    = var.ses_verified_domains
    verified_emails     = var.ses_verified_emails
  }
  sensitive = true
}