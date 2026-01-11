<!--
═══════════════════════════════════════════════════════════════════════════════
SYNC IMPACT REPORT
═══════════════════════════════════════════════════════════════════════════════
Constitution Version: INITIAL → 1.0.0
Date: 2026-01-11

PRINCIPLES ESTABLISHED:
  ✅ I. Infrastructure as Code (IaC) First
  ✅ II. Module-First Architecture
  ✅ III. Dynamic Scalability
  ✅ IV. Security & Compliance
  ✅ V. Operational Verification

SECTIONS ADDED:
  ✅ Development Workflow
  ✅ Governance

TEMPLATE ALIGNMENT STATUS:
  ✅ plan-template.md - Constitution Check section aligns (gate validation)
  ✅ spec-template.md - Requirements structure aligns (FR-### format)
  ✅ tasks-template.md - Phase organization aligns (infrastructure-specific)
  ⚠️  All templates require Terraform-specific guidance updates

FOLLOW-UP ACTIONS:
  - Update plan-template.md Constitution Check gates to include:
    * Module structure validation (main.tf, variables.tf, outputs.tf)
    * Tagging compliance check
    * Dynamic scalability verification (no hardcoded counts)
  
  - Update spec-template.md to include infrastructure-specific sections:
    * AWS Services & Resources required
    * Network architecture requirements
    * Security & compliance needs
  
  - Update tasks-template.md examples to reflect Terraform workflows:
    * Phase 1: Module creation (main.tf, variables.tf, outputs.tf)
    * Phase 2: Variable definition and environment integration
    * Phase 3: terraform plan validation
    * Phase 4: terraform apply and verification

COMMIT MESSAGE:
  docs: establish AWS Infrastructure constitution v1.0.0
  
  - Define 5 core principles for Terraform IaC development
  - Establish module-first architecture standard
  - Set dynamic scalability requirements
  - Define mandatory tagging and security standards
  - Document operational verification gates
═══════════════════════════════════════════════════════════════════════════════
-->

# AWS Infrastructure Constitution

## Core Principles

### I. Infrastructure as Code (IaC) First
All infrastructure changes MUST be defined in Terraform. Manual changes via the AWS Console are strictly forbidden (ClickOps). All state MUST be managed remotely in Terraform Cloud; local state management is prohibited.

**Rationale**: Declarative infrastructure ensures reproducibility, auditability, and prevents configuration drift. Remote state enables team collaboration and prevents state conflicts.

### II. Module-First Architecture
Infrastructure components MUST be implemented as reusable modules in `terraform/modules/` before being instantiated in environment configurations (`terraform/dev/`, `terraform/prod/`).

**Requirements**:
- Modules MUST have `main.tf`, `variables.tf`, and `outputs.tf`
- Modules MUST use `snake_case` for variables and resources
- Modules MUST output all critical resource IDs and ARNs
- Modules MUST include descriptions for all variables and outputs

**Rationale**: Reusable modules eliminate duplication, enforce consistency across environments, and enable testing in isolation.

### III. Dynamic Scalability
Hardcoding resource counts or names is PROHIBITED for scalable components (VPCs, Subnets, Route Tables, etc.).

**Requirements**:
- Use `for_each` and local maps to handle iteration
- Architecture MUST scale from 3 to 100+ VPCs strictly by updating `variables.tf` maps
- No logic code changes required when adding resources

**Rationale**: Dynamic infrastructure scales effortlessly without code rewrites. This prevents technical debt and enables rapid environment expansion.

### IV. Security & Compliance
Security is not an afterthought - it is built into every resource.

**Requirements**:
- **Tagging**: All resources MUST have standard tags:
  - `Environment` (dev/staging/prod)
  - `Project` ("AWS Infrastructure")
  - `ManagedBy` ("Terraform")
  - `Owner` ("DevOps Team")
  - `CostCenter` (environment name)
  - `VPC` (VPC name for VPC-specific resources)
- **Network**: Compute resources MUST reside in private subnets. Public subnets are for load balancers/NAT/IGW only.
- **Access**: Security Groups MUST use least-privilege CIDR blocks. No 0.0.0.0/0 for ingress except for public ALBs/NLBs.
- **Encryption**: EBS volumes and S3 buckets MUST use encryption at rest.

**Rationale**: Consistent tagging enables cost tracking and automation. Network isolation protects compute resources. Least-privilege access minimizes attack surface.

### V. Operational Verification
Code is considered "complete" ONLY when `terraform plan` passes without errors and correctly shows the expected additions/changes. Breaking changes to existing infrastructure MUST be flagged during the specification phase.

**Requirements**:
- `terraform fmt` MUST pass before commit
- `terraform validate` MUST pass before PR creation
- `terraform plan` MUST show expected changes with no errors
- Destructive changes (replacements) MUST be documented in PR description

**Rationale**: Validation gates prevent broken code from reaching production. Plan verification ensures intended behavior matches actual behavior.

## Development Workflow

### Feature Specification
Features MUST be specified in `.specify/memory/` using the SpecKit workflow before implementation begins.

**Requirements**:
- Specifications MUST define required input variables
- Specifications MUST define expected module outputs
- Specifications MUST identify AWS services and resources needed
- Specifications MUST document security and compliance requirements

### Naming Conventions
**Subnets**:
- `pub_*` prefix for public subnets (receive IGW routes and public IP assignment)
- `priv_*` prefix for private subnets (receive TGW routes only)
- This convention is CRITICAL for route table logic

**Resources**:
- Format: `aws_<service>_<description>` (e.g., `aws_vpc_main_inspection`)
- Use descriptive names that indicate purpose and environment

**Variables**:
- Use `snake_case` for all variable names
- Prefix booleans with `enable_` or `is_` (e.g., `enable_flow_logs`)
- Use plural names for collections (e.g., `vpcs`, `subnets`)

### Version Control
- **Terraform**: v1.5.x (pinned in `terraform.tf`)
- **AWS Provider**: 5.x (pinned in `terraform.tf`)
- Module versions: Use git tags for module versioning if modules extracted to separate repos

## Governance

This Constitution supersedes all other documentation. Deviations require an amendment to this file with version increment and rationale.

**Amendment Process**:
- MAJOR version: Backward-incompatible principle changes (e.g., removing IaC-First requirement)
- MINOR version: New principles or substantial guidance additions
- PATCH version: Clarifications, wording improvements, non-semantic refinements

**Compliance Verification**:
All Pull Requests MUST verify compliance with:
- Module structure (main.tf, variables.tf, outputs.tf present)
- Mandatory tagging on all AWS resources
- Dynamic scalability patterns (no hardcoded resource counts)
- Terraform v1.5.x and AWS Provider 5.x compatibility
- `terraform plan` passes without errors

**Reference Documentation**:
- Runtime guidance: `.github/copilot-instructions.md`
- Architecture details: `terraform/dev/TGW_CONNECTIVITY_GUIDE.md`
- Scaling patterns: `terraform/dev/SCALABILITY_GUIDE.md`

**Version**: 1.0.0 | **Ratified**: 2026-01-11 | **Last Amended**: 2026-01-11
