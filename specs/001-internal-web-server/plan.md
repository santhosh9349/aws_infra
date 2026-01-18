# Implementation Plan: Internal Web Server for Client Dashboard

**Branch**: `001-internal-web-server` | **Date**: 2026-01-17 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-internal-web-server/spec.md`

## Summary

Deploy a secure internal web server in the Development VPC to host the client dashboard application. The server must be isolated from public internet access, accept HTTPS traffic from other internal VPCs via Transit Gateway, use minimal resources for cost optimization, and include mandatory resource tagging for compliance.

## Technical Context

**Language/Version**: Terraform v1.5.x with AWS Provider 5.x  
**Primary Dependencies**: AWS EC2, VPC, Security Groups, Systems Manager (SSM) for no-SSH management  
**Storage**: EBS volumes (default EC2 storage, encrypted at rest)  
**Testing**: `terraform plan` validation, AWS Systems Manager Session Manager for connectivity testing  
**Target Platform**: AWS EC2 in Development VPC (172.0.0.0/16) private subnets  
**Project Type**: Infrastructure as Code (Terraform modules)  
**Performance Goals**: Instance launches within 5 minutes, accepts 100% of valid HTTPS connections from internal VPCs  
**Constraints**: Zero public internet accessibility, no SSH access (use SSM Session Manager), minimal instance size (t3.micro or t3.small)  
**Scale/Scope**: Single EC2 instance in dev environment, expandable pattern for additional instances

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Infrastructure as Code (IaC) First
- **Status**: PASS
- **Evidence**: All infrastructure will be defined in Terraform modules
- **Verification**: No manual AWS Console changes required

### ✅ II. Module-First Architecture
- **Status**: PASS
- **Evidence**: Will use existing `terraform/modules/ec2/` module, may need enhancements for SSM and security group configuration
- **Verification**: Module has main.tf, variables.tf, outputs.tf structure

### ✅ III. Dynamic Scalability
- **Status**: PASS
- **Evidence**: Single instance now, but module supports variable-driven instance configuration
- **Verification**: No hardcoded values, all configuration via variables

### ✅ IV. Security & Compliance
- **Status**: PASS
- **Evidence**: 
  - Mandatory tagging will be applied (Environment, Project, ManagedBy, Owner, CostCenter, VPC)
  - Instance in private subnet only
  - Security Group with least-privilege (HTTPS from internal CIDRs only)
  - EBS encryption enabled
- **Verification**: Security group rules, subnet placement, and tags in module configuration

### ✅ V. Operational Verification
- **Status**: PASS
- **Evidence**: Will validate with `terraform fmt`, `terraform validate`, and `terraform plan`
- **Verification**: Plan shows expected resource creation without errors

## Project Structure

### Documentation (this feature)

```text
specs/001-internal-web-server/
├── spec.md              # Feature specification (already exists)
├── plan.md              # This file
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (resource definitions)
├── quickstart.md        # Phase 1 output (deployment guide)
└── contracts/           # Phase 1 output (security group rules, IAM policies)
```

### Source Code (repository root)

```text
terraform/
├── modules/
│   ├── ec2/                    # Existing EC2 module (will be enhanced)
│   │   ├── main.tf            # EC2 instance, IAM role, security group
│   │   ├── variables.tf       # Instance configuration variables
│   │   └── outputs.tf         # Instance ID, private IP, security group ID
│   └── [other existing modules]/
│
└── dev/
    ├── ec2.tf                  # EC2 module instantiation (will be updated)
    ├── variables.tf            # Environment variables (will be updated)
    └── [other environment files]
```

**Structure Decision**: Using existing Terraform module structure. The `terraform/modules/ec2/` module exists and will be enhanced to support:
- SSM Session Manager IAM role
- Security group with HTTPS-only ingress from internal VPC CIDRs
- Mandatory tagging
- EBS encryption

## Complexity Tracking

> No Constitution violations - all gates pass. Table not needed.

---

# Phase 0: Research & Technical Decisions

## Overview
Resolve technical unknowns and document architectural decisions for the internal web server implementation.

## Research Tasks

### 1. EC2 Instance Type Selection
**Question**: What is the smallest suitable EC2 instance type for a development client dashboard?

**Research Findings**:
- **t3.micro** (2 vCPU, 1 GB RAM) - suitable for very light web applications
- **t3.small** (2 vCPU, 2 GB RAM) - recommended for web servers with moderate traffic
- **Decision**: Use **t3.small** as default with variable override capability
- **Rationale**: Provides enough headroom for a dashboard application with API calls, but still cost-optimized for dev environment (~$15/month vs $8/month for t3.micro)

### 2. No-SSH Management with AWS Systems Manager
**Question**: How to manage EC2 instances without SSH access?

**Research Findings**:
- **AWS Systems Manager Session Manager** provides secure shell access without SSH
- **Requirements**:
  - IAM instance profile with `AmazonSSMManagedInstanceCore` policy
  - VPC endpoint for SSM (or internet access via NAT Gateway)
  - SSM agent (pre-installed on Amazon Linux 2023, Ubuntu, Windows)
- **Decision**: Use SSM Session Manager with IAM role
- **Rationale**: Meets no-SSH policy, provides audit logging, no need for SSH keys or bastion hosts

### 3. Security Group Configuration
**Question**: Which internal VPC CIDRs should be allowed for HTTPS ingress?

**Research Findings**:
- Current VPC architecture:
  - Inspection VPC: 192.0.0.0/16
  - Dev VPC: 172.0.0.0/16 (where server will reside)
  - Prod VPC: 10.0.0.0/16
- **Decision**: Allow HTTPS (port 443) from all internal VPC CIDRs (192.0.0.0/16, 172.0.0.0/16, 10.0.0.0/16)
- **Rationale**: Enables connectivity from all VPCs in Transit Gateway mesh, follows least-privilege (no 0.0.0.0/0)

### 4. EBS Volume Configuration
**Question**: What EBS volume size and type for a web server?

**Research Findings**:
- **gp3** (general purpose SSD) is most cost-effective
- Web server OS + application typically needs 20-30 GB
- **Decision**: 20 GB gp3 volume with encryption enabled
- **Rationale**: Sufficient for OS + web application, cost-optimized, meets encryption requirement

### 5. Amazon Machine Image (AMI) Selection
**Question**: Which AMI should be used for the web server?

**Research Findings**:
- **Amazon Linux 2023** - AWS-optimized, free tier eligible, long-term support
- **Ubuntu 22.04 LTS** - popular, wide package support
- **Decision**: Use latest Amazon Linux 2023 AMI (dynamically retrieved via data source)
- **Rationale**: AWS-optimized, pre-installed SSM agent, free licensing, receives security updates

### 6. Private Subnet Selection
**Question**: Which private subnet in Dev VPC should host the instance?

**Research Findings**:
- Dev VPC has `priv_sub1` and `priv_sub2` (different AZs)
- **Decision**: Use `priv_sub1` as default, allow variable override for multi-AZ deployment
- **Rationale**: Single instance for dev doesn't require multi-AZ, but architecture supports it

### 7. User Data Script
**Question**: Does the instance need initialization scripts?

**Research Findings**:
- Basic web server setup can be done via user data
- Client dashboard application deployment is out of scope (per spec)
- **Decision**: Minimal user data script to install HTTPS web server (nginx or apache) for testing connectivity
- **Rationale**: Enables immediate HTTPS connectivity testing, application deployment handled separately

### 8. Tagging Strategy
**Question**: What are the exact tag values for this resource?

**Research Findings**:
- Constitution requires: Environment, Project, ManagedBy, Owner, CostCenter, VPC
- **Decision**:
  - Environment: "dev"
  - Project: "AWS Infrastructure"
  - ManagedBy: "Terraform"
  - Owner: "DevOps Team"
  - CostCenter: "dev"
  - VPC: "dev"
- **Rationale**: Aligns with constitution standards and existing infrastructure

---

# Phase 1: Design & Contracts

## Data Model

See [data-model.md](./data-model.md) for complete resource definitions.

**Summary**:
- **EC2 Instance**: t3.small, Amazon Linux 2023, 20GB gp3 encrypted EBS, private subnet
- **Security Group**: HTTPS ingress from internal VPC CIDRs (192.0.0.0/16, 172.0.0.0/16, 10.0.0.0/16)
- **IAM Role**: Instance profile with SSM managed instance core policy
- **Tags**: All mandatory tags applied

## API Contracts

See [contracts/](./contracts/) directory for:
- **security-group-rules.json**: Security group ingress/egress rules
- **iam-policy.json**: IAM policy for SSM Session Manager access
- **user-data.sh**: Instance initialization script

## Quickstart Guide

See [quickstart.md](./quickstart.md) for deployment instructions.

## Constitution Check (Post-Design)

### ✅ I. Infrastructure as Code (IaC) First
- **Status**: PASS
- **Evidence**: All resources defined in Terraform, no manual steps

### ✅ II. Module-First Architecture
- **Status**: PASS  
- **Evidence**: Using `terraform/modules/ec2/` module with variables for all configuration

### ✅ III. Dynamic Scalability
- **Status**: PASS
- **Evidence**: Instance count, type, subnet, and all parameters configurable via variables

### ✅ IV. Security & Compliance
- **Status**: PASS
- **Evidence**: All mandatory tags present, private subnet, encrypted EBS, least-privilege security group

### ✅ V. Operational Verification
- **Status**: PASS
- **Evidence**: Plan output validates expected resource creation

---

# Next Steps

This plan is complete. To proceed with implementation:

1. Execute `/speckit.tasks` command to generate phase-by-phase implementation tasks
2. Generate artifacts:
   - `research.md` ✅ (documented above in Phase 0)
   - `data-model.md` (next: detailed resource schemas)
   - `contracts/` directory (next: security group rules, IAM policies)
   - `quickstart.md` (next: deployment guide)
3. Update agent context with Terraform modules and AWS services
4. Begin implementation in `terraform/modules/ec2/` and `terraform/dev/`
