# AWS Infrastructure - Terraform IaC Repository

This repository manages AWS infrastructure deployment using Infrastructure as Code (IaC) with Terraform. Infrastructure is provisioned across multiple environments (dev/prod) with strict tagging, security standards, and automated scalability patterns.

## Tech Stack

### Infrastructure
- **Terraform v1.5.x** for declarative infrastructure management
- **AWS Provider 5.x** for AWS resource provisioning
- **AWS Services**: VPC (multi-VPC architecture), Transit Gateway (full mesh connectivity), Subnets, Route Tables, Internet Gateways, EC2, Security Groups
- **State Management**: Terraform Cloud (remote state, no local state management)
- **Architecture**: Multi-VPC setup with Transit Gateway hub for inter-VPC communication
  - Inspection VPC (192.0.0.0/16) - Network inspection/firewall
  - Dev VPC (172.0.0.0/16) - Development environment
  - Prod VPC (10.0.0.0/16) - Production environment
- Infrastructure organized into reusable modules under `terraform/modules/`
- Environment-specific configurations in `terraform/dev/` and `terraform/prod/`
- **Scalability**: Fully dynamic - scales from 3 to 100+ VPCs with zero code changes

### Development Tools
- Scripts for common tasks located in `scripts/` directory
- GitHub Actions for CI/CD workflows
- MCP servers for enhanced workflow automation
- SpecKit for feature specification and planning (`.specify/`, `.github/agents/`)

## Project Structure

```
aws_infra/
├── terraform/                    # Infrastructure as Code
│   ├── modules/                 # Reusable Terraform modules
│   │   ├── vpc/                # VPC module with networking configuration
│   │   │   ├── main.tf         # VPC resource definitions
│   │   │   ├── outputs.tf      # VPC outputs (vpc_id, cidr_block, etc.)
│   │   │   └── variables.tf    # VPC input variables
│   │   ├── subnet/             # Subnet module for public/private subnets
│   │   │   ├── main.tf         # Subnet resource definitions
│   │   │   ├── outputs.tf      # Subnet outputs (subnet_ids, etc.)
│   │   │   └── variables.tf    # Subnet input variables
│   │   ├── route_table/        # Route table module for VPC routing
│   │   │   ├── main.tf         # Route table, associations, TGW/IGW routes
│   │   │   ├── outputs.tf      # Route table outputs (route_table_id, etc.)
│   │   │   └── variables.tf    # Route table input variables
│   │   ├── ec2/                # EC2 instance module
│   │   │   ├── main.tf         # EC2 instance definitions
│   │   │   ├── outputs.tf      # EC2 outputs (instance_ids, IPs, etc.)
│   │   │   └── variables.tf    # EC2 input variables
│   │   └── tgw/                # Transit Gateway module for multi-VPC connectivity
│   │       ├── main.tf         # TGW + multiple VPC attachments (scalable)
│   │       ├── outputs.tf      # TGW outputs (tgw_id, attachment_ids, etc.)
│   │       └── variables.tf    # TGW input variables
│   │
│   ├── dev/                     # Development environment configuration
│   │   ├── terraform.tf        # Terraform and provider configuration
│   │   ├── variables.tf        # Multi-VPC variables (inspection, dev, prod)
│   │   ├── vpc.tf              # Dynamic VPC creation (for_each loop)
│   │   ├── subnets.tf          # Dynamic subnet creation across all VPCs
│   │   ├── ec2.tf              # EC2 module instantiation
│   │   ├── tgw.tf              # TGW with dynamic VPC attachments
│   │   ├── route_tables.tf     # Dynamic route tables + IGWs for all VPCs
│   │   ├── outputs.tf          # Environment outputs (VPCs, TGW, routes)
│   │   ├── SCALABILITY_GUIDE.md       # Complete scalability documentation
│   │   ├── SCALING_EXAMPLE.md         # Step-by-step: 3 to 10 VPCs example
│   │   └── TGW_CONNECTIVITY_GUIDE.md  # Transit Gateway architecture guide
│   │
│   └── prod/                    # Production environment configuration
│       └── (not yet implemented - use dev/ as template)
│
├── environments/                 # Environment-specific configurations
│   └── dev/                     # Development environment files
│
├── scripts/                      # Automation and utility scripts
│   └── (deployment, testing, setup scripts)
│
├── .specify/                     # SpecKit feature specification system
│   ├── memory/                  # Feature specifications and documentation
│   ├── scripts/                 # SpecKit automation scripts
│   └── templates/               # Specification templates
│
├── .github/                      # GitHub configuration
│   ├── copilot-instructions.md  # This file
│   ├── agents/                  # SpecKit agent definitions
│   │   ├── speckit.clarify.agent.md
│   │   └── (other agent files)
│   └── prompts/                 # SpecKit prompt templates
│
├── .gemini/                      # Gemini AI integration
│   └── commands/                # Custom command definitions
│
├── README.md                     # Project documentation
└── LICENSE                       # License information
```

## Coding Guidelines

### Infrastructure as Code (Terraform) Guidelines
- **Module-first approach**: Create reusable modules for all infrastructure components
- **Dynamic scalability**: Use `for_each` loops and locals for automatic scaling
- **Variable naming**: Use snake_case for all Terraform variables and resources
- **Mandatory tagging**: Every AWS resource MUST include the following tags:
  - `Environment` (dev/staging/prod)
  - `Project` ("AWS Infrastructure")
  - `ManagedBy` ("Terraform")
  - `Owner` ("DevOps Team")
  - `CostCenter` (environment name)
  - `VPC` (VPC name for VPC-specific resources)
- **State management**: Never manage state locally - all state in Terraform Cloud
- **Naming conventions**:
  - Subnets starting with `pub_` are public (get public IPs and IGW routes)
  - Subnets starting with `priv_` are private (TGW routes only)
  - This convention is CRITICAL for route table logic
- **Security**: 
  - Configure security groups with least privilege access
  - Place compute resources in private subnets
  - Use Transit Gateway for inter-VPC communication
  - Enable VPC Flow Logs and CloudTrail
- **Documentation**: Include description for every variable and output
- **Output values**: Always output critical resource IDs, ARNs, and endpoints
- **DRY principle**: Avoid code duplication - use modules and data sources
- **Version pinning**: Pin provider versions in `terraform.tf` (AWS Provider 5.x)
- **Scalability**: Infrastructure scales automatically based on `var.vpcs` and `var.subnets` maps

### General Best Practices
- **Security first**: Never commit secrets, API keys, or sensitive data
- **Linting**: Code must pass all linters before commit
- **Documentation**: Update README.md when adding new features or infrastructure
- **Git commits**: Use conventional commit messages (feat:, fix:, docs:, refactor:, etc.)
- **PR requirements**: All changes require pull request with description and testing notes
- **SpecKit workflow**: Use SpecKit agents for feature specification, clarification, and planning before implementation

## Environment-Specific Guidelines

### Development (dev/)
- Use smaller instance types for cost optimization
- Enable detailed logging and debugging
- Relaxed security groups for testing (within reason)
- Test new infrastructure patterns before production deployment

### Production (prod/)
- Use production-grade instance types
- Enable AWS CloudWatch monitoring and alerting
- Strict security groups following least privilege
- Enable AWS WAF and Shield when applicable
- Multi-AZ deployment for high availability
- Implement automated backups and disaster recovery

## MCP Server Integration

### GitHub MCP Server
- Use GitHub MCP server for all GitHub-related operations
- Always provide GitHub web links after operations for visibility
- When searching: use single words or minimal phrases for better results

### Terraform MCP Server
- Use Terraform MCP server for Terraform Cloud operations
- Provide Terraform Cloud links after operations
- Focus on configuration and modules - ignore state management

## SpecKit Integration

### Feature Development Workflow
1. **Specify**: Use `/speckit.specify` to create feature specifications in `.specify/memory/`
2. **Clarify**: Use `/speckit.clarify` to resolve ambiguities and add clarifications
3. **Plan**: Use `/speckit.plan` to create technical implementation plans
4. **Implement**: Use `/speckit.implement` to execute the plan with validation

### Agent Files
- Agents located in [.github/agents/](.github/agents/) define specialized workflows
- [`speckit.clarify.agent.md`](.github/agents/speckit.clarify.agent.md): Identifies and resolves specification ambiguities
- Additional agents available for specification, planning, and implementation phases

### Prerequisites Script
- Run `.specify/scripts/powershell/check-prerequisites.ps1` to validate feature branch environment
- Use `-Json -PathsOnly` flags for structured output during automated workflows

## Resources & Scripts

### Common Tasks
- **Deploy infrastructure**: Navigate to environment folder (`terraform/dev/` or `terraform/prod/`) and use Terraform commands (`terraform plan`, `terraform apply`)
- **Scale infrastructure**: Add new VPCs to `var.vpcs` and subnets to `var.subnets` in `variables.tf` - everything else is automatic
- **Module updates**: Modify modules in `terraform/modules/` and update version references in environment configs
- **Multi-VPC connectivity**: All VPCs automatically get full mesh routing via Transit Gateway
- **View architecture**: Check `TGW_CONNECTIVITY_GUIDE.md` for infrastructure diagrams
- **Scaling guide**: See `SCALABILITY_GUIDE.md` for detailed scaling documentation
- Scripts should be executable and include usage documentation in comments
- Create new scripts for repetitive tasks

## Security & Compliance

### AWS Security Best Practices
- **VPC Security**: 
  - Use security groups to control traffic between resources
  - Implement NACLs for additional network-level security
  - Enable VPC Flow Logs for network traffic analysis
- **EC2 Instances**: 
  - Place in private subnets when possible
  - Use security groups to restrict access
  - Enable Systems Manager for secure access (no SSH keys)
  - Use IAM instance profiles for AWS service access
- **IAM Policies**: Follow principle of least privilege
- **Encryption**: Enable encryption at rest (EBS) and in transit (TLS)
- **Network**: Use VPC security groups and NACLs appropriately
- **Logging**: Enable CloudTrail, VPC Flow Logs, and resource-specific logs

### Code Security
- Never hardcode credentials or secrets
- Use AWS Secrets Manager or Parameter Store for sensitive data
- Scan Terraform code for security issues before applying
- Review security group rules for overly permissive access

## Infrastructure Architecture

### Multi-VPC Design
The infrastructure uses a **Transit Gateway hub-and-spoke** model for inter-VPC connectivity:

```
        Internet
           |
    Internet Gateways (one per VPC)
           |
    [Public Subnets] ←→ [Private Subnets]
           |                    |
           └────────────────────┘
                    |
             Transit Gateway (Hub)
                    |
        Full Mesh Routing Between All VPCs
```

**Key Features:**
- **3 VPCs by default**: inspection (192.0.0.0/16), dev (172.0.0.0/16), prod (10.0.0.0/16)
- **4 subnets per VPC**: 2 public (pub_sub1, pub_sub2), 2 private (priv_sub1, priv_sub2)
- **Automatic scaling**: Add VPCs to variables.tf and everything scales automatically
- **Full mesh connectivity**: Each VPC can communicate with all other VPCs via TGW
- **Internet access**: Each VPC has its own Internet Gateway for public subnets
- **Dynamic routing**: Routes to all other VPCs are automatically created

### Scalability
- **Current**: 3 VPCs, 12 subnets, 6 route tables, 1 Transit Gateway, 3 TGW attachments
- **Can scale to**: 100+ VPCs with zero code changes (just update variables)
- **Full documentation**: See [terraform/dev/SCALABILITY_GUIDE.md](terraform/dev/SCALABILITY_GUIDE.md) and [SCALING_EXAMPLE.md](terraform/dev/SCALING_EXAMPLE.md)

## Notes for Copilot

### Terraform Best Practices
- When creating new Terraform resources, always include the mandatory tags
- Always validate Terraform with `terraform plan` before applying
- Reference existing modules before creating new infrastructure components
- Use dynamic `for_each` loops instead of hardcoding resource names
- Respect subnet naming convention: `pub_*` for public, `priv_*` for private
- When adding new VPCs, only update `variables.tf` - all other files are dynamic

### Module Development
- All modules must have `main.tf`, `variables.tf`, and `outputs.tf`
- Include comprehensive variable descriptions
- Output all critical resource identifiers
- Use consistent naming patterns across modules

### Documentation
- Major infrastructure changes should be documented in relevant .md files
- Keep [TGW_CONNECTIVITY_GUIDE.md](terraform/dev/TGW_CONNECTIVITY_GUIDE.md) updated with architecture changes
- Update [SCALABILITY_GUIDE.md](terraform/dev/SCALABILITY_GUIDE.md) if scaling patterns change
- Document new modules in module-specific README files

### SpecKit Workflow
- Use SpecKit agents for structured feature development
- Run clarification phase before creating implementation plans
- Validate prerequisites before starting implementation
- Follow the specify → clarify → plan → implement workflow for complex features

