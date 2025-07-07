output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.state_bucket.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of S3 bucket for Terraform state"
  value       = aws_s3_bucket.state_bucket.arn
}

output "terraform_locks_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "terraform_locks_table_arn" {
  description = "ARN of DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "backend_config" {
  description = "Backend configuration for other Terraform layers"
  value = {
    bucket         = aws_s3_bucket.state_bucket.bucket
    region         = var.region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = true
  }
}

output "backend_config_hcl" {
  description = "Backend configuration in HCL format for copy-paste"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state_bucket.bucket}"
        region         = "${var.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
        encrypt        = true
      }
    }
  EOT
}