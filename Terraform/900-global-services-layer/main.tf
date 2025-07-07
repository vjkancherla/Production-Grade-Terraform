# Get current AWS account ID
data "aws_caller_identity" "current" {
  provider = aws.global
}

# ===== ROUTE 53 HOSTED ZONE =====

# Create hosted zone (if requested)
resource "aws_route53_zone" "main" {
  count    = var.create_hosted_zone ? 1 : 0
  name     = var.domain_name
  provider = aws.global

  tags = {
    Name = "${var.project_name}-hosted-zone"
  }
}

# Use existing hosted zone (if provided)
data "aws_route53_zone" "existing" {
  count    = var.create_hosted_zone ? 0 : 1
  zone_id  = var.existing_hosted_zone_id
  provider = aws.global
}

# Local reference to the hosted zone
locals {
  hosted_zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
  hosted_zone_name = var.create_hosted_zone ? aws_route53_zone.main[0].name : data.aws_route53_zone.existing[0].name
}

# ===== HEALTH CHECKS =====

# Health check for London API Gateway
resource "aws_route53_health_check" "london_api" {
  provider                        = aws.global
  fqdn                           = local.london_api_domain
  port                           = 443
  type                           = "HTTPS"
  resource_path                  = var.health_check_path
  failure_threshold              = var.health_check_failure_threshold
  request_interval               = var.health_check_interval
  measure_latency               = true
  invert_healthcheck            = false
  insufficient_data_health_status = "Failure"

  tags = {
    Name   = "${var.project_name}-london-api-health-check"
    Region = "london"
  }
}

# Health check for Sydney API Gateway
resource "aws_route53_health_check" "sydney_api" {
  provider                        = aws.global
  fqdn                           = local.sydney_api_domain
  port                           = 443
  type                           = "HTTPS"
  resource_path                  = var.health_check_path
  failure_threshold              = var.health_check_failure_threshold
  request_interval               = var.health_check_interval
  measure_latency               = true
  invert_healthcheck            = false
  insufficient_data_health_status = "Failure"

  tags = {
    Name   = "${var.project_name}-sydney-api-health-check"
    Region = "sydney"
  }
}

# ===== API SUBDOMAIN GEO-ROUTING =====

# Specific country records for London (Europe)
resource "aws_route53_record" "api_london_countries" {
  provider = aws.global
  count    = length(var.london_regions)
  zone_id  = local.hosted_zone_id
  name     = "${var.api_subdomain}.${local.hosted_zone_name}"
  type     = "A"
  
  set_identifier = "london-${var.london_regions[count.index]}"
  
  geolocation_routing_policy {
    country = var.london_regions[count.index]
  }
  
  health_check_id = aws_route53_health_check.london_api.id
  
  alias {
    name                   = local.london_endpoint
    zone_id               = local.london_hosted_zone_id
    evaluate_target_health = true
  }
  
  ttl = var.dns_ttl_seconds
}

# Sydney API record (for Asia-Pacific regions)
resource "aws_route53_record" "api_sydney_countries" {
  provider = aws.global
  count    = length(var.sydney_regions)
  zone_id  = local.hosted_zone_id
  name     = "${var.api_subdomain}.${local.hosted_zone_name}"
  type     = "A"
  
  set_identifier = "sydney-${var.sydney_regions[count.index]}"
  
  geolocation_routing_policy {
    country = var.sydney_regions[count.index]
  }
  
  health_check_id = aws_route53_health_check.sydney_api.id
  
  alias {
    name                   = local.sydney_endpoint
    zone_id               = local.sydney_hosted_zone_id
    evaluate_target_health = true
  }
  
  ttl = var.dns_ttl_seconds
}

# Default/fallback record
resource "aws_route53_record" "api_default" {
  provider = aws.global
  zone_id  = local.hosted_zone_id
  name     = "${var.api_subdomain}.${local.hosted_zone_name}"
  type     = "A"
  
  set_identifier = "default-${var.default_region}"
  
  geolocation_routing_policy {
    country = "*"  # Default for all other countries
  }
  
  # Use the health check for the default region
  health_check_id = var.default_region == "london" ? aws_route53_health_check.london_api.id : aws_route53_health_check.sydney_api.id
  
  alias {
    name                   = var.default_region == "london" ? local.london_endpoint : local.sydney_endpoint
    zone_id               = var.default_region == "london" ? local.london_hosted_zone_id : local.sydney_hosted_zone_id
    evaluate_target_health = true
  }
  
  ttl = var.dns_ttl_seconds
}