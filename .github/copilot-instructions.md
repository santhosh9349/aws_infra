# AWS Infrastructure - Next.js + Terraform Monorepo

This repository manages a full-stack AWS infrastructure deployment combining a Next.js 15 frontend with Infrastructure as Code (IaC) using Terraform. The application is hosted on AWS EC2 instances behind an Application Load Balancer (ALB), and infrastructure is provisioned across multiple environments (dev/prod) with strict tagging and security standards.

## Tech Stack

### Frontend
- **Next.js 15** for server-side rendering and optimal performance
- **React 19** with Server Components where applicable
- **TypeScript** (strict mode enabled) for type safety across all frontend code
- **Tailwind CSS** for utility-first styling and responsive design
- All frontend code resides in `app/` directory
- Application runs on Node.js runtime on EC2 instances

### Infrastructure
- **Terraform v1.5.x** for declarative infrastructure management
- **AWS Provider 5.x** for AWS resource provisioning
- **AWS Services**: VPC (multi-VPC architecture), Transit Gateway (full mesh connectivity), Subnets, Route Tables, Internet Gateways, EC2 (application hosting)
- **State Management**: Terraform Cloud (remote state, no local state management)
- **Architecture**: Multi-VPC setup with Transit Gateway hub for inter-VPC communication
  - Inspection VPC (192.0.0.0/16) - Network inspection/firewall
  - Dev VPC (172.0.0.0/16) - Development environment
  - Prod VPC (10.0.0.0/16) - Production environment
- Infrastructure organized into reusable modules under `terraform/modules/`
- Environment-specific configurations in `terraform/dev/` (prod not yet implemented)
- **Scalability**: Fully dynamic - scales from 3 to 100+ VPCs with zero code changes

### Development Tools
- Scripts for common tasks located in `scripts/` directory
- GitHub Actions for CI/CD (if applicable)
- MCP servers for enhanced workflow automation

## Project Structure

```
aws_infra/
├── app/                          # Next.js 15 application
│   ├── components/              # React components
│   ├── pages/                   # Next.js pages (if using pages router)
│   ├── app/                     # App router (if using app router)
│   ├── styles/                  # Tailwind CSS and custom styles
│   ├── public/                  # Static assets
│   └── next.config.js           # Next.js configuration
│
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
│   │   ├── ec2/                # EC2 instance module (hosts Next.js app)
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
├── scripts/                      # Automation and utility scripts
│   └── (deployment, testing, setup scripts)
│
├── .github/                      # GitHub configuration
│   └── copilot-instructions.md  # This file
│
├── README.md                     # Project documentation
└── LICENSE                       # License information
```

## Coding Guidelines

### TypeScript Standards
- **Always use strict TypeScript mode** across all frontend and configuration files
- **Type hints required** for all function parameters and return values
- **No implicit `any` types** - explicitly type all variables
- **Use interfaces over type aliases** for object shapes when possible
- **Prefer const assertions** for literal types

### Frontend Guidelines
- **Component structure**: Use functional components with TypeScript interfaces for props
- **Styling**: Tailwind CSS utility classes only - avoid custom CSS unless absolutely necessary
- **File naming**: Use kebab-case for files (`user-profile.tsx`), PascalCase for components (`UserProfile`)
- **Import order**: External libraries → Internal modules → Relative imports
- **Code organization**: Keep components small and focused (< 200 lines ideal)

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

## Environment-Specific Guidelines

### Development (dev/)
- Use smaller instance types for cost optimization
- Enable detailed logging and debugging
- Relaxed security groups for testing (within reason)

### Production (prod/)
- Use production-grade instance types
- Enable AWS CloudWatch monitoring and alerting
- Strict security groups following least privilege
- Enable AWS WAF and Shield when applicable
- Multi-AZ deployment for high availability

## MCP Server Integration

### GitHub MCP Server
- Use GitHub MCP server for all GitHub-related operations
- Always provide GitHub web links after operations for visibility
- When searching: use single words or minimal phrases for better results

### Terraform MCP Server
- Use Terraform MCP server for Terraform Cloud operations
- Provide Terraform Cloud links after operations
- Focus on configuration and modules - ignore state management

## Resources & Scripts`terraform/dev/` and use Terraform commands (`terraform plan`, `terraform apply`)
- **Scale infrastructure**: Add new VPCs to `var.vpcs` and subnets to `var.subnets` in `variables.tf` - everything else is automatic
- **Application deployment**: Build Next.js application and deploy to EC2 instances via SSH or CI/CD pipeline
- **Module updates**: Modify modules in `terraform/modules/` and update version references in environment configs
- **Multi-VPC connectivity**: All VPCs automatically get full mesh routing via Transit Gateway
- **View architecture**: Check `TGW_CONNECTIVITY_GUIDE.md` for infrastructure diagrams
- **Scaling guide**: See `SCALABILITY_GUIDE.md` for detailed scaling documentation
- Scripts should be executable and include usage documentation in comments
- Create new scripts for repetitive tasks

### Common Tasks
- **Deploy infrastructure**: Navigate to appropriate environment folder (`terraform/dev/` or `terraform/prod/`) and use Terraform commands
- **Application deployment**: Build Next.js application and deploy to EC2 instances via SSH or CI/CD pipeline
- **ALB configuration**: Update ALB listeners, target groups, and health checks as needed
- **Module updates**: Modify modules in `terraform/modules/` and update version references in environment configs

## Security & Compliance

### AWS Security Best Practices
- **ALB Security**: 
  - Use HTTPS listeners with ACM certificates
  - Configure security groups to allow only necessary traffic
  - Enable access logs and connection logs
  - Implement WAF rules for additional protection
- **EC2 Instances**: 
  - Place in private subnets behind ALB
  - Use security groups to restrict access to ALB only
  - Enable Systems Manager for secure access (no SSH keys)
- **IAM Policies**: Follow principle of least privilege
- **Encryption**: Enable encryption at rest (EBS) and in transit (HTTPS/TLS)
- **Network**: Use VPC security groups and NACLs appropriately
- **Logging**: Enable CloudTrail, VPC Flow Logs, and ALB access logs

### Code Security
- Never hardcode credentials or secrets
- Use AWS Secrets Manager or Parameter Store for sensitive data
- IInfrastructure Architecture

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
- **Full documentation**: See `terraform/dev/SCALABILITY_GUIDE.md` and `SCALING_EXAMPLE.md`

## Notes for Copilot

### Terraform Best Practices
- When creating new Terraform resources, always include the mandatory tags
- Always validate Terraform with `terraform plan` before applying
- Reference existing modules before creating new infrastructure components
- Use dynamic `for_each` loops instead of hardcoding resource names
- Respect subnet naming convention: `pub_*` for public, `priv_*` for private
- When adding new VPCs, only update `variables.tf` - all other files are dynamic

### Frontend Best Practices
- For Next.js components, follow the established component structure in `app/`
- Ensure EC2 instances are always placed in private subnets
- Use Application Load Balancer in public subnets for internet-facing apps

### Documentation
- Major infrastructure changes should be documented in relevant .md files
- Keep TGW_CONNECTIVITY_GUIDE.md updated with architecture changes
- Update SCALABILITY_GUIDE.md if scaling patterns changecture components
- Ensure EC2 instances are always placed in private subnets with ALB in public subnets
- Configure ALB health checks to match the Next.js application's health endpoint
- Use target groups to manage EC2 instances behind the ALB

