# Terraform Infrastructure as Code Guidelines

This document defines the standards and best practices for Terraform development in this repository.

## General Principles
- **Module-First Approach**: Always evaluate if a new resource should be part of a reusable module.
- **Dynamic Scalability**: Use `for_each` and `count` with local variables to ensure infrastructure can scale without hardcoding.
- **Environment Isolation**: Maintain clear separation between `dev/`, `prod/`, and shared `modules/`.

## Resource Tagging
Every AWS resource **MUST** include these standard tags:
- `Environment`: (e.g., dev, staging, prod)
- `Project`: "AWS Infrastructure"
- `Owner`: "DevOps Team"
- `VPC`: Include for VPC-specific resources

## Naming Conventions
- **Files**: Use snake_case for filenames (e.g., `vpc_peering.tf`).
- **Resources**: Use snake_case for all resource and variable names.
- **Subnets**: 
  - `pub_*`: Public subnets (assigned public IPs, routed to IGW).
  - `priv_*`: Private subnets (no public IPs, routed via TGW/NAT).

## Module Structure
Each module in `terraform/modules/` must contain:
1. `main.tf`: Primary resource definitions.
2. `variables.tf`: Input variables with clear descriptions and types.
3. `outputs.tf`: Exported resource IDs, ARNs, and connection strings.
4. `README.md`: Usage examples and architecture notes.

## State Management
- Local state files are strictly prohibited.
- All state must be managed via **Terraform Cloud** or a configured remote backend.

## Security & Network
- **Least Privilege**: Security groups must be as restrictive as possible.
- **Private by Default**: Place all compute and database resources in private subnets.
- **TGW Connectivity**: Internal traffic between VPCs should leverage the Transit Gateway.

## Validation & Deployment
- Always run `terraform fmt` and `terraform validate` before committing.
- A `terraform plan` must be reviewed and approved via Pull Request before application.
