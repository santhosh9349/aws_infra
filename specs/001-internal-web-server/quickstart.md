# Quickstart Guide: Deploy Internal Web Server

**Feature**: Internal Web Server for Client Dashboard  
**Branch**: 001-internal-web-server  
**Estimated Time**: 15-20 minutes  

## Prerequisites

### Required Access
- [x] AWS account with permissions to create EC2, VPC, IAM resources
- [x] Terraform Cloud workspace configured with AWS credentials
- [x] Git repository cloned locally

### Required Tools
- [x] Terraform CLI v1.5.x or higher ([install](https://developer.hashicorp.com/terraform/downloads))
- [x] AWS CLI v2 ([install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- [x] Git

### Required Information
- [x] Development VPC ID (should be provisioned via `terraform/dev/vpc.tf`)
- [x] Private subnet ID in Dev VPC (e.g., `priv_sub1`)
- [x] Transit Gateway ID (existing TGW connecting all VPCs)

### Verify Prerequisites
```bash
# Check Terraform version
terraform version
# Expected: Terraform v1.5.x or higher

# Check AWS CLI and credentials
aws sts get-caller-identity
# Expected: Your AWS account ID and user/role ARN

# Check current branch
git branch --show-current
# Expected: 001-internal-web-server

# Check existing infrastructure
cd terraform/dev
terraform output vpc_ids
terraform output subnet_ids
# Expected: Dev VPC and private subnet IDs
```

---

## Step 1: Review and Update EC2 Module

### 1.1: Navigate to EC2 Module
```bash
cd terraform/modules/ec2
```

### 1.2: Review Module Files
Check that the module has the following files:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values

### 1.3: Enhance Module for SSM and Security Groups

Edit [main.tf](../../../terraform/modules/ec2/main.tf):

```hcl
# Data source: Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for SSM access
resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-ssm-role"
  })
}

# Attach AWS-managed SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile
resource "aws_iam_instance_profile" "ssm_instance" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ssm_role.name

  tags = merge(var.tags, {
    Name = "${var.name}-instance-profile"
  })
}

# Security group
resource "aws_security_group" "web_server" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name} - HTTPS only from internal VPCs"
  vpc_id      = var.vpc_id

  # HTTPS ingress from internal VPC CIDRs
  dynamic "ingress" {
    for_each = var.ingress_cidrs
    content {
      description = "HTTPS from ${ingress.value}"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

# EC2 instance
resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance.name

  user_data = var.user_data

  monitoring    = true
  ebs_optimized = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
```

Edit [variables.tf](../../../terraform/modules/ec2/variables.tf):

```hcl
variable "name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for instance placement"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "ingress_cidrs" {
  description = "List of CIDR blocks allowed for HTTPS ingress"
  type        = list(string)
  default     = ["192.0.0.0/16", "172.0.0.0/16", "10.0.0.0/16"]
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

Edit [outputs.tf](../../../terraform/modules/ec2/outputs.tf):

```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.this.arn
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web_server.id
}

output "instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = aws_iam_instance_profile.ssm_instance.arn
}

output "iam_role_name" {
  description = "IAM role name for SSM access"
  value       = aws_iam_role.ssm_role.name
}
```

---

## Step 2: Update Development Environment Configuration

### 2.1: Navigate to Dev Environment
```bash
cd ../../dev
```

### 2.2: Update ec2.tf

Create or update [ec2.tf](../../../terraform/dev/ec2.tf):

```hcl
# Get VPC and subnet information from existing infrastructure
locals {
  dev_vpc_id     = module.vpc["dev"].vpc_id
  dev_subnet_id  = module.subnet["dev"]["priv_sub1"].subnet_id
}

# Module: Internal Web Server
module "internal_web_server" {
  source = "../modules/ec2"

  name          = "dev-internal-web-server"
  vpc_id        = local.dev_vpc_id
  subnet_id     = local.dev_subnet_id
  instance_type = "t3.small"
  volume_size   = 20

  # HTTPS ingress from all internal VPC CIDRs
  ingress_cidrs = [
    "192.0.0.0/16",  # Inspection VPC
    "172.0.0.0/16",  # Dev VPC
    "10.0.0.0/16"    # Prod VPC
  ]

  # User data script for nginx installation
  user_data = file("${path.module}/../../specs/001-internal-web-server/contracts/user-data.sh")

  # Mandatory tags per Constitution IV
  tags = {
    Environment = "dev"
    Project     = "AWS Infrastructure"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "dev"
    VPC         = "dev"
  }
}
```

### 2.3: Update outputs.tf

Add to [outputs.tf](../../../terraform/dev/outputs.tf):

```hcl
# Internal Web Server Outputs
output "internal_web_server_id" {
  description = "Internal web server instance ID"
  value       = module.internal_web_server.instance_id
}

output "internal_web_server_private_ip" {
  description = "Internal web server private IP address"
  value       = module.internal_web_server.instance_private_ip
}

output "internal_web_server_security_group_id" {
  description = "Internal web server security group ID"
  value       = module.internal_web_server.security_group_id
}
```

---

## Step 3: Validate and Deploy

### 3.1: Format Terraform Code
```bash
terraform fmt -recursive
```

### 3.2: Initialize Terraform
```bash
terraform init
```
**Expected**: "Terraform has been successfully initialized!"

### 3.3: Validate Configuration
```bash
terraform validate
```
**Expected**: "Success! The configuration is valid."

### 3.4: Review Plan
```bash
terraform plan
```

**Expected Resources to be Created**:
- `module.internal_web_server.aws_instance.this`
- `module.internal_web_server.aws_security_group.web_server`
- `module.internal_web_server.aws_iam_role.ssm_role`
- `module.internal_web_server.aws_iam_role_policy_attachment.ssm_policy`
- `module.internal_web_server.aws_iam_instance_profile.ssm_instance`
- `data.aws_ami.amazon_linux_2023` (read)

**Review**:
- ✅ No destructive changes (replacements) to existing resources
- ✅ Security group has ONLY port 443 ingress
- ✅ Security group has no 0.0.0.0/0 ingress
- ✅ Instance in private subnet
- ✅ IAM instance profile attached
- ✅ All mandatory tags present

### 3.5: Apply Configuration
```bash
terraform apply
```

Type `yes` when prompted.

**Expected**: 
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

internal_web_server_id = "i-0123456789abcdef0"
internal_web_server_private_ip = "172.0.x.x"
internal_web_server_security_group_id = "sg-0123456789abcdef0"
```

**Deployment Time**: 3-5 minutes

---

## Step 4: Verify Deployment

### 4.1: Check Instance Status
```bash
# Get instance ID from outputs
INSTANCE_ID=$(terraform output -raw internal_web_server_id)

# Check instance state
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text

# Expected: "running"

# Check instance details
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[InstanceId, InstanceType, PrivateIpAddress, State.Name]' \
  --output table
```

### 4.2: Verify SSM Access
```bash
# Start SSM session
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# Once connected, verify nginx is running:
sudo systemctl status nginx

# Check nginx is listening on port 443:
sudo ss -tlnp | grep :443

# Exit the session:
exit
```

### 4.3: Verify Security Group Rules
```bash
# Get security group ID
SG_ID=$(terraform output -raw internal_web_server_security_group_id)

# List ingress rules
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions' \
  --output table

# Verify:
# ✅ Port 443 from 192.0.0.0/16
# ✅ Port 443 from 172.0.0.0/16
# ✅ Port 443 from 10.0.0.0/16
# ❌ NO port 22 (SSH)
# ❌ NO 0.0.0.0/0 ingress
```

### 4.4: Test HTTPS Connectivity (from another VPC)

**Option A**: From another EC2 instance in any internal VPC:
```bash
# Get private IP
PRIVATE_IP=$(terraform output -raw internal_web_server_private_ip)

# Test HTTPS connectivity (use -k to accept self-signed cert)
curl -k https://$PRIVATE_IP/

# Expected: "Internal Web Server - Ready for Dashboard Deployment"

# Test health endpoint
curl -k https://$PRIVATE_IP/health

# Expected: "OK"
```

**Option B**: From local machine (if VPN/DirectConnect to VPC):
```bash
curl -k https://172.0.x.x/
```

### 4.5: Verify Tags
```bash
aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" \
  --query 'Tags[*].[Key,Value]' \
  --output table

# Verify all mandatory tags are present:
# ✅ Environment = dev
# ✅ Project = AWS Infrastructure
# ✅ ManagedBy = Terraform
# ✅ Owner = DevOps Team
# ✅ CostCenter = dev
# ✅ VPC = dev
# ✅ Name = dev-internal-web-server
```

---

## Step 5: Post-Deployment Testing

### 5.1: Network Isolation Test
```bash
# Verify instance has NO public IP
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress'

# Expected: null or no output

# Verify SSH is blocked (should timeout or refuse connection)
ssh ec2-user@$PRIVATE_IP
# Expected: Connection refused or timeout
```

### 5.2: SSM Session Manager Test
```bash
# Test interactive session
aws ssm start-session --target $INSTANCE_ID

# Once connected, run some commands:
whoami           # Expected: ssm-user
hostname         # Expected: instance hostname
curl localhost   # Expected: nginx welcome or HTTPS redirect message

exit
```

### 5.3: Transit Gateway Connectivity Test

From an instance in **Inspection VPC (192.0.0.0/16)**:
```bash
curl -k https://172.0.x.x/
# Expected: Server response (proves TGW routing works)
```

From an instance in **Prod VPC (10.0.0.0/16)**:
```bash
curl -k https://172.0.x.x/
# Expected: Server response (proves TGW routing works)
```

---

## Troubleshooting

### Issue: Terraform Plan Fails

**Error**: "Error: No valid credential sources found"

**Solution**:
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

### Issue: Instance Fails to Launch

**Error**: "InsufficientInstanceCapacity"

**Solution**: Change instance type or availability zone:
```hcl
# In ec2.tf, try different instance type
instance_type = "t3.micro"  # or t3.medium
```

---

### Issue: Cannot Connect via SSM

**Error**: "TargetNotConnected"

**Possible Causes**:
1. SSM agent not running (unlikely on AL2023)
2. No route to SSM endpoints
3. IAM permissions incorrect

**Solution**:
```bash
# Check SSM agent status via SSH alternative
# Use EC2 Instance Connect or Serial Console

# Verify IAM role is attached
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Check SSM agent connectivity
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID"
```

---

### Issue: Cannot Access HTTPS Endpoint from Other VPCs

**Possible Causes**:
1. Security group rules incorrect
2. Transit Gateway routing misconfigured
3. nginx not running

**Solution**:
```bash
# 1. Verify security group allows your source CIDR
aws ec2 describe-security-groups --group-ids $SG_ID

# 2. Check Transit Gateway route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$DEV_VPC_ID"

# 3. Check nginx status via SSM
aws ssm start-session --target $INSTANCE_ID
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
```

---

### Issue: HTTPS Certificate Errors

**Error**: "SSL certificate problem: self signed certificate"

**Solution**: This is expected behavior. Use `-k` flag with curl:
```bash
curl -k https://$PRIVATE_IP/
```

For production, replace self-signed certificate with valid certificate from AWS Certificate Manager or Let's Encrypt.

---

## Cleanup (Optional)

To remove the infrastructure:

```bash
cd terraform/dev
terraform destroy -target=module.internal_web_server
```

Type `yes` when prompted.

**Warning**: This will permanently delete the EC2 instance and associated resources.

---

## Next Steps

1. **Deploy Client Dashboard Application**
   - Application deployment is out of scope for this infrastructure feature
   - Use SSM Session Manager to deploy application code
   - Update nginx configuration to proxy to application port

2. **Replace Self-Signed Certificate**
   - Generate CSR and obtain certificate from CA
   - Or use AWS Certificate Manager with Application Load Balancer

3. **Enable Monitoring and Logging**
   - Configure CloudWatch Logs for nginx logs
   - Set up CloudWatch Alarms for instance health
   - Enable VPC Flow Logs for network analysis

4. **Production Deployment**
   - Replicate configuration in `terraform/prod/`
   - Use production-grade instance type (e.g., t3.medium or larger)
   - Enable multi-AZ deployment for high availability
   - Configure automated backups

---

## Success Criteria Checklist

- ✅ SC-001: Server provisioned and operational within 5 minutes
- ✅ SC-002: Zero public internet accessibility
- ✅ SC-003: Accepts 100% of valid HTTPS connections from internal VPCs
- ✅ SC-004: SSH completely disabled
- ✅ SC-005: Minimal cost footprint (t3.small)
- ✅ SC-006: 100% of costs attributed to dev environment
- ✅ SC-007: All mandatory tags present
- ✅ SC-008: Internal services can establish HTTPS connections
- ✅ SC-009: Non-HTTPS traffic blocked
- ✅ SC-010: Deployment completed without manual intervention

---

## References

- [Feature Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Research Document](./research.md)
- [Data Model](./data-model.md)
- [Contracts](./contracts/)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
