/**
 * # bootstrap
 *
 * Configure state bucket and DynamoDB lock table for Terraform operations.
 *
 * Must be configured on a per account basis.
 *
 * State file bucket name format: `AWSACCOUNTID-tf-state-PROJECT`
 * DynamoDB lock table name format: `terraform_lock_AWSACCOUNTID_PROJECT`
 *
 * To run this layer obtain credentials locally and run:
 * `terraform apply -var "region=eu-west-2" -var "aws_account_id=AWSACCOUNTID" -var "project_name=cutlass-tech"`
 *
 * It is not required to keep the state file of this operation.
 */

esource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.aws_account_id}-tf-state-${var.project_name}"

  tags = {
    Name = "Terraform State"
  }
}

resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    id     = "state_lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls   = true
  block_public_policy = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform_lock_${var.aws_account_id}_${var.project_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock"
  }

  timeouts {
    update = "3h"
  }
}