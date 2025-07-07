# 900-global-services

Route 53 geo-routing and DNS management for global traffic distribution across London and Sydney regions.

## Overview

This layer creates:
- **Route 53 Hosted Zone** for domain management
- **Geographic Routing** to closest regional API
- **Health Checks** with automatic failover

## Architecture

```
Client Request → Route 53 → Geographic Routing → Regional API Gateway
```

## DNS Endpoints

| Endpoint | Routing Strategy | Purpose |
|----------|------------------|---------|
| `api.domain.com` | Geographic | Primary API (routes by location) |


## Geographic Routing

### London Regions (Europe)
- **Countries**: GB, IE, FR, DE, NL, BE, ES, IT, PT, CH, AT, DK, SE, NO, FI, PL, CZ, HU, RO, GR
- **Endpoint**: Routes to London API Gateway

### Sydney Regions (Asia-Pacific)  
- **Countries**: AU, NZ, JP, KR, SG, MY, TH, ID, PH, VN, IN, HK, TW, BD, LK, PK, MN, KH, LA, MM
- **Endpoint**: Routes to Sydney API Gateway

### Default Region
- **Countries**: Americas, Africa, Middle East (all others)
- **Endpoint**: Routes to configurable default region (London)

## Dependencies

- **300-api-layer**: London and Sydney API Gateway endpoints
- **Domain ownership**: Must control DNS for the target domain

## Configuration

### Single Global Deployment
```bash
terraform init -backend-config=backend-config.hcl
terraform plan -var-file=vars/global.tfvars  
terraform apply -var-file=vars/global.tfvars
```

## Key Resources

- **Hosted Zone**: DNS zone for your domain
- **Health Checks**: HTTPS monitoring of regional APIs
- **A Records**: Geographic and failover routing policies
- **CNAME Records**: Application subdomain aliases

## Health Monitoring

- **Path**: `/health` (configurable)
- **Interval**: 30 seconds
- **Failure Threshold**: 3 consecutive failures
- **Protocol**: HTTPS on port 443

## Traffic Flow

1. **Client** requests `api.your-domain.com`
2. **Route 53** determines client location
3. **Geographic routing** selects closest region
4. **Health check** validates region availability
5. **Failover** to secondary region if primary unhealthy
6. **Response** served from healthy regional API
