# Hosted Zone Outputs
output "hosted_zone_id" {
  description = "ID of the Route 53 hosted zone"
  value       = local.hosted_zone_id
}

output "hosted_zone_name" {
  description = "Name of the Route 53 hosted zone"
  value       = local.hosted_zone_name
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

# DNS Endpoints
output "api_endpoints" {
  description = "API endpoint URLs with different routing strategies"
  value = {
    geo_routed      = "https://${var.api_subdomain}.${local.hosted_zone_name}"
  }
}