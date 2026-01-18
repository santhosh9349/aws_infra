# Contracts Directory

This directory contains interface definitions, security policies, and configuration contracts for the internal web server infrastructure.

## Files

### security-group-rules.json
**Purpose**: Defines security group ingress/egress rules for the web server  
**Format**: JSON  
**Usage**: Reference for implementing security group in Terraform  

**Key Rules**:
- ✅ HTTPS (port 443) ingress from internal VPC CIDRs only
- ✅ All outbound traffic for OS updates and SSM
- ❌ No SSH (port 22) allowed
- ❌ No HTTP (port 80) allowed for external access
- ❌ No public internet (0.0.0.0/0) ingress

---

### iam-ssm-policy.json
**Purpose**: IAM policy granting SSM Session Manager permissions  
**Format**: JSON (AWS IAM policy document)  
**Usage**: Embedded in Terraform or use AWS-managed policy `AmazonSSMManagedInstanceCore`  

**Permissions**:
- SSM Session Manager (ssm:*, ssmmessages:*)
- EC2 Messages (ec2messages:*)
- S3 encryption configuration (for SSM logging)

**Note**: This is equivalent to AWS-managed policy `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`

---

### iam-trust-policy.json
**Purpose**: IAM trust policy allowing EC2 service to assume the SSM role  
**Format**: JSON (AWS IAM assume role policy)  
**Usage**: Attached to IAM role as assume_role_policy  

**Principal**: EC2 service (ec2.amazonaws.com)

---

### user-data.sh
**Purpose**: Instance initialization script executed at first boot  
**Format**: Bash shell script  
**Usage**: Passed to EC2 instance via user_data parameter  

**Actions**:
1. Update system packages (yum update)
2. Install nginx web server
3. Generate self-signed SSL certificate for HTTPS
4. Configure nginx for HTTPS on port 443
5. Enable and start nginx service
6. Create status file for troubleshooting

**Testing Endpoints**:
- `https://<private-ip>/` - Returns server info and ready message
- `https://<private-ip>/health` - Returns "OK" for health checks
- `http://<private-ip>/` - Returns "HTTPS only" message (port 80 info only)

---

## Usage in Terraform

### Security Group Rules
```hcl
resource "aws_security_group" "web_server" {
  name        = "internal-web-server-sg"
  description = "Security group for internal web server - HTTPS only from internal VPCs"
  vpc_id      = var.vpc_id

  # Ingress: HTTPS from Inspection VPC
  ingress {
    description = "HTTPS from Inspection VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.0.0.0/16"]
  }

  # Ingress: HTTPS from Dev VPC
  ingress {
    description = "HTTPS from Dev VPC (intra-VPC communication)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.0.0.0/16"]
  }

  # Ingress: HTTPS from Prod VPC
  ingress {
    description = "HTTPS from Prod VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Egress: All outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "internal-web-server-sg"
    Environment = "dev"
    Project     = "AWS Infrastructure"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "dev"
    VPC         = "dev"
  }
}
```

### IAM Role and Policy
```hcl
# Trust policy
resource "aws_iam_role" "ssm_role" {
  name = "internal-web-server-ssm-role"

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

  tags = {
    Name        = "internal-web-server-ssm-role"
    Environment = "dev"
    Project     = "AWS Infrastructure"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    CostCenter  = "dev"
    VPC         = "dev"
  }
}

# Attach AWS-managed SSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ssm_instance" {
  name = "internal-web-server-instance-profile"
  role = aws_iam_role.ssm_role.name
}
```

### User Data
```hcl
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance.name
  
  user_data = file("${path.module}/../../specs/001-internal-web-server/contracts/user-data.sh")
  
  # ... other configuration
}
```

---

## Testing the Contracts

### 1. Verify Security Group Rules
```bash
# List security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify no SSH (port 22) in ingress
# Verify HTTPS (port 443) from internal CIDRs only
# Verify no 0.0.0.0/0 in ingress
```

### 2. Test HTTPS Connectivity from Internal VPC
```bash
# From another instance in Inspection VPC (192.0.0.0/16)
curl -k https://<web-server-private-ip>/

# Expected: "Internal Web Server - Ready for Dashboard Deployment"

# From another instance in Prod VPC (10.0.0.0/16)
curl -k https://<web-server-private-ip>/health

# Expected: "OK"
```

### 3. Verify SSM Access
```bash
# Start SSM session
aws ssm start-session --target <instance-id> --region us-east-1

# Expected: Interactive shell session opens

# Verify no SSH access
ssh ec2-user@<private-ip>

# Expected: Connection refused (port not open in security group)
```

### 4. Verify IAM Role Attachment
```bash
# Get instance profile
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Verify SSM policy is attached
aws iam list-attached-role-policies --role-name internal-web-server-ssm-role
```

---

## Compliance Checklist

- ✅ Security group allows ONLY HTTPS (port 443) ingress
- ✅ Security group ingress limited to internal VPC CIDRs (no 0.0.0.0/0)
- ✅ Security group prohibits SSH (port 22)
- ✅ Security group prohibits HTTP (port 80) from external sources
- ✅ IAM role has minimal permissions (SSM only, no admin access)
- ✅ IAM trust policy limited to EC2 service principal
- ✅ User data installs HTTPS-capable web server
- ✅ User data generates self-signed certificate for testing
- ✅ All resources have mandatory tags

---

## References

- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Feature Specification](../spec.md)
- [Data Model](../data-model.md)
