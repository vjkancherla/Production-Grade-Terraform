terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary provider for global resources (Route 53 is global)
provider "aws" {
  alias  = "global"
  region = "us-east-1"  # Route 53 is managed from us-east-1

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "global"
      Layer       = "900-global-services"
      ManagedBy   = "terraform"
    }
  }
}

# London region provider for reading regional outputs
provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}

# Sydney region provider for reading regional outputs
provider "aws" {
  alias  = "sydney"
  region = "ap-southeast-2"
}