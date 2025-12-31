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
- **AWS Services**: EC2 (application hosting), ALB (Application Load Balancer), VPC, Transit Gateway, Subnets, Security Groups, Target Groups
- **State Management**: Terraform Cloud (remote state, no local state management)
- Infrastructure organized into reusable modules under `terraform/modules/`
- Environment-specific configurations in `terraform/dev/` and `terraform/prod/`

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
│   │   ├── ec2/                # EC2 instance module (hosts Next.js app)
│   │   │   ├── main.tf         # EC2 instance definitions
│   │   │   ├── outputs.tf      # EC2 outputs (instance_ids, IPs, etc.)
│   │   │   └── variables.tf    # EC2 input variables
│   │   ├── alb/                # Application Load Balancer module
│   │   │   ├── main.tf         # ALB, listeners, target groups
│   │   │   ├── outputs.tf      # ALB outputs (dns_name, arn, etc.)
│   │   │   └── variables.tf    # ALB input variables
│   │   └── tgw/                # Transit Gateway module for network connectivity
│   │       ├── main.tf         # TGW resource definitions
│   │       ├── outputs.tf      # TGW outputs (tgw_id, attachments, etc.)
│   │       └── variables.tf    # TGW input variables
│   │
│   ├── dev/                     # Development environment configuration
│   │   ├── terraform.tf        # Terraform and provider configuration
│   │   ├── variables.tf        # Environment-specific variables
│   │   ├── vpc.tf              # VPC module instantiation
│   │   ├── subnets.tf          # Subnet module instantiation
│   │   ├── ec2.tf              # EC2 module instantiation
│   │   ├── alb.tf              # ALB module instantiation
│   │   ├── tgw.tf              # TGW module instantiation
│   │   └── outputs.tf          # Environment outputs
│   │
│   └── prod/                    # Production environment configuration
│       └── (similar structure to dev/)
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
- **Variable naming**: Use snake_case for all Terraform variables and resources
- **Mandatory tagging**: Every AWS resource MUST include the following tags:
  - `Environment` (dev/staging/prod)
  - `Project` (project name)
  - `ManagedBy` ("Terraform")
  - `Owner` (team or individual)
  - `CostCenter` (for billing)
- **State management**: Never manage state locally - all state in Terraform Cloud
- **Security**: 
  - Always use HTTPS listeners on ALB with valid SSL/TLS certificates
  - Configure security groups with least privilege access
  - Enable ALB access logs to S3 for audit trails
- **Documentation**: Include description for every variable and output
- **Output values**: Always output critical resource IDs, ARNs, and endpoints (especially ALB DNS name)
- **DRY principle**: Avoid code duplication - use modules and data sources
- **Version pinning**: Pin provider versions in `terraform.tf` (AWS Provider 5.x)

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

## Resources & Scripts

### Available Scripts
- Check `scripts/` directory for deployment, setup, and testing utilities
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
- Implement proper CORS policies for API endpoints
- Regular dependency updates and security scanning

## Notes for Copilot

- When creating new Terraform resources, always include the mandatory tags
- For Next.js components, follow the established component structure in `app/`
- When modifying infrastructure, consider impact on both dev and prod environments
- Always validate Terraform with `terraform plan` before applying
- Reference existing modules before creating new infrastructure components
- Ensure EC2 instances are always placed in private subnets with ALB in public subnets
- Configure ALB health checks to match the Next.js application's health endpoint
- Use target groups to manage EC2 instances behind the ALB

