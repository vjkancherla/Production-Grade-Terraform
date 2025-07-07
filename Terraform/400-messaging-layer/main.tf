# Get current AWS account ID and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===== KMS KEY FOR ENCRYPTION =====

# KMS Key for SQS and SNS encryption
resource "aws_kms_key" "messaging" {
  description             = "KMS key for messaging services - ${var.project_name} - ${var.region}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-messaging-key-${var.region}"
  }
}

resource "aws_kms_alias" "messaging" {
  name          = "alias/${var.project_name}-messaging-${var.region}"
  target_key_id = aws_kms_key.messaging.key_id
}

# ===== SQS QUEUES =====

# Notification Check Queue (for determining if notifications are needed)
resource "aws_sqs_queue" "notification_check" {
  name                       = "${var.project_name}-notification-check-queue-${var.region}"
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_receive_wait_time_seconds
  
  # Enable encryption
  kms_master_key_id                 = aws_kms_key.messaging.arn
  kms_data_key_reuse_period_seconds = 300

  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_check_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = {
    Name        = "${var.project_name}-notification-check-queue-${var.region}"
    Purpose     = "Check if notifications are required after usage updates"
    MessageType = "usage_updates,threshold_checks"
  }
}

# Notification Check Dead Letter Queue
resource "aws_sqs_queue" "notification_check_dlq" {
  name                       = "${var.project_name}-notification-check-dlq-${var.region}"
  message_retention_seconds  = 1209600  # 14 days
  
  # Enable encryption
  kms_master_key_id                 = aws_kms_key.messaging.arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name    = "${var.project_name}-notification-check-dlq-${var.region}"
    Purpose = "Failed notification check messages"
  }
}


# ===== SQS LAMBDA TRIGGERS =====

# Event source mapping for notification check queue
resource "aws_lambda_event_source_mapping" "notification_check_queue" {
  event_source_arn = aws_sqs_queue.notification_check.arn
  function_name    = local.notification_lambda_arn
  batch_size       = 10
  
  # Error handling
  maximum_batching_window_in_seconds = 5
  
  tags = {
    Name = "${var.project_name}-notification-check-trigger-${var.region}"
  }
}

# ===== SES CONFIGURATION =====

# SES Domain Identity (verify domains)
resource "aws_ses_domain_identity" "main" {
  count  = length(var.ses_verified_domains)
  domain = var.ses_verified_domains[count.index]
}

# SES Email Identity (verify individual emails)
resource "aws_ses_email_identity" "main" {
  count = length(var.ses_verified_emails)
  email = var.ses_verified_emails[count.index]
}

# SES Configuration Set for tracking
resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-config-set-${var.region}"

  tags = {
    Name = "${var.project_name}-ses-config-${var.region}"
  }
}

# ===== SES EMAIL TEMPLATES =====

# Usage Threshold Alert Template
resource "aws_ses_template" "usage_threshold_alert" {
  count   = var.enable_email_templates ? 1 : 0
  name    = "${var.project_name}-usage-threshold-alert-${var.region}"
  subject = "Usage Alert: {{threshold_percentage}}% of your limit reached"
  
  html = <<-EOF
    <html>
      <body>
        <h2>Usage Alert</h2>
        <p>Hello {{user_name}},</p>
        <p>The customer's usage has reached <strong>{{threshold_percentage}}%</strong> of its limit.</p>
        <p><strong>Current Usage:</strong> {{current_usage}} / {{usage_limit}}</p>
        <p>Best regards,<br>The Team</p>
      </body>
    </html>
  EOF

  tags = {
    Name = "${var.project_name}-threshold-template-${var.region}"
  }
}

# ===== IAM PERMISSIONS =====

# IAM policy for Lambda to access SQS
resource "aws_iam_policy" "lambda_sqs_access" {
  name        = "${var.project_name}-lambda-sqs-access-${var.region}"
  description = "SQS access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.notification_check.arn,
          aws_sqs_queue.report_processing.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.messaging.arn
      }
    ]
  })
}

# IAM policy for Lambda to access SES
resource "aws_iam_policy" "lambda_ses_access" {
  name        = "${var.project_name}-lambda-ses-access-${var.region}"
  description = "SES access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendTemplatedEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress" = [var.ses_from_email]
          }
        }
      }
    ]
  })
}