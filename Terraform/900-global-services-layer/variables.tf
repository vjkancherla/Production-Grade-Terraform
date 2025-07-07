variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "cutlass-tech"
}

# Route 53 Configuration
variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
  default     = "example.com"
}

variable "api_subdomain" {
  description = "Subdomain for API endpoints"
  type        = string
  default     = "api"
}

variable "app_subdomain" {
  description = "Subdomain for frontend application"
  type        = string
  default     = "app"
}

# Geo-routing Configuration
variable "london_regions" {
  description = "List of regions/countries to route to London"
  type        = list(string)
  default     = ["GB", "IE", "FR", "DE", "NL", "BE", "ES", "IT", "PT", "CH", "AT", "DK", "SE", "NO", "FI"]
}

variable "sydney_regions" {
  description = "List of regions/countries to route to Sydney"
  type        = list(string)
  default     = ["AU", "NZ", "JP", "KR", "SG", "MY", "TH", "ID", "PH", "VN", "IN", "HK", "TW"]
}

variable "default_region" {
  description = "Default region for unmatched locations"
  type        = string
  default     = "london"
  validation {
    condition     = contains(["london", "sydney"], var.default_region)
    error_message = "Default region must be either 'london' or 'sydney'."
  }
}

# Health Check Configuration
variable "health_check_path" {
  description = "Path for Route 53 health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive failures before marking unhealthy"
  type        = number
  default     = 3
}

# DNS TTL Configuration
variable "dns_ttl_seconds" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 60
}

# Hosted Zone Configuration
variable "create_hosted_zone" {
  description = "Create a new Route 53 hosted zone (set to false if using existing)"
  type        = bool
  default     = true
}

variable "existing_hosted_zone_id" {
  description = "ID of existing hosted zone (used if create_hosted_zone is false)"
  type        = string
  default     = ""
}