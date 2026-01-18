# Data Model: Internal Web Server Infrastructure

**Feature**: Internal Web Server for Client Dashboard  
**Branch**: 001-internal-web-server  
**Date**: 2026-01-17

## Overview
This document defines the AWS resources and their relationships for the internal web server infrastructure. All resources are defined in Terraform and follow the Constitution's module-first architecture.

---

## Resource Definitions

### 1. EC2 Instance

**Resource Type**: `aws_instance`  
**Module**: `terraform/modules/ec2/`  
**Purpose**: Compute server for hosting the client dashboard application

#### Attributes

| Attribute              | Type     | Value/Source                                    | Rationale                                      |
|------------------------|----------|-------------------------------------------------|------------------------------------------------|
| ami                    | string   | data.aws_ami.amazon_linux_2023.id              | Latest AL2023 AMI, AWS-optimized               |
| instance_type          | string   | var.instance_type (default: "t3.small")        | Minimal resources for dev workload             |
| subnet_id              | string   | var.subnet_id (priv_sub1 in Dev VPC)           | Private subnet, no public IP                   |
| vpc_security_group_ids | list     | [aws_security_group.web_server.id]             | HTTPS-only access from internal VPCs           |
| iam_instance_profile   | string   | aws_iam_instance_profile.ssm_instance.name     | SSM Session Manager access                     |
| user_data              | string   | file("user-data.sh")                            | Install nginx, configure HTTPS                 |
| monitoring             | bool     | true                                            | Enable detailed CloudWatch monitoring          |
| ebs_optimized          | bool     | true                                            | Better EBS performance                         |

#### Root Block Device

| Attribute              | Type     | Value                                           | Rationale                                      |
|------------------------|----------|-------------------------------------------------|------------------------------------------------|
| volume_type            | string   | "gp3"                                           | Cost-effective general purpose SSD             |
| volume_size            | number   | 20                                              | Sufficient for OS + web server + app           |
| encrypted              | bool     | true                                            | Encryption at rest (Constitution requirement)  |
| delete_on_termination  | bool     | true                                            | Development env, no data persistence needed    |

#### Tags

| Tag Key       | Tag Value                              | Source                    |
|---------------|----------------------------------------|---------------------------|
| Name          | var.name (e.g., "dev-internal-web-server") | Variable              |
| Environment   | var.environment (e.g., "dev")          | Variable                  |
| Project       | "AWS Infrastructure"                   | Hardcoded (per constitution) |
| ManagedBy     | "Terraform"                            | Hardcoded (per constitution) |
| Owner         | "DevOps Team"                          | Hardcoded (per constitution) |
| CostCenter    | var.environment                        | Variable                  |
| VPC           | var.vpc_name                           | Variable                  |

#### State Transitions
1. **Pending** → Instance launching
2. **Running** → Instance operational, accepting HTTPS traffic
3. **Stopping** → Graceful shutdown initiated
4. **Stopped** → Instance stopped (can be restarted)
5. **Terminated** → Instance deleted (EBS volume also deleted)

---

### 2. Security Group

**Resource Type**: `aws_security_group`  
**Module**: `terraform/modules/ec2/` or `terraform/dev/ec2.tf`  
**Purpose**: Control inbound/outbound traffic for the web server

#### Attributes

| Attribute       | Type     | Value                                           | Rationale                                      |
|-----------------|----------|-------------------------------------------------|------------------------------------------------|
| name            | string   | "${var.name}-sg"                                | Descriptive name with resource prefix          |
| description     | string   | "Security group for internal web server"       | Human-readable purpose                         |
| vpc_id          | string   | var.vpc_id (Dev VPC ID)                         | Security group belongs to Dev VPC              |

#### Ingress Rules

| Rule ID | Protocol | Port | Source CIDR     | Description                              |
|---------|----------|------|-----------------|------------------------------------------|
| https-1 | tcp      | 443  | 192.0.0.0/16    | HTTPS from Inspection VPC                |
| https-2 | tcp      | 443  | 172.0.0.0/16    | HTTPS from Dev VPC (intra-VPC)           |
| https-3 | tcp      | 443  | 10.0.0.0/16     | HTTPS from Prod VPC                      |

#### Egress Rules

| Rule ID | Protocol | Port | Destination CIDR | Description                              |
|---------|----------|------|------------------|------------------------------------------|
| all     | all      | all  | 0.0.0.0/0        | All outbound (OS updates, SSM endpoints) |

#### Validation Rules
- **No SSH**: Port 22 must NOT be present in ingress rules
- **No HTTP**: Port 80 must NOT be present in ingress rules (HTTPS only)
- **No Public Access**: 0.0.0.0/0 must NOT be present in ingress rules
- **HTTPS Only**: Only port 443 TCP allowed for ingress

#### Tags
Same as EC2 instance tags above.

---

### 3. IAM Role for SSM Access

**Resource Type**: `aws_iam_role`  
**Module**: `terraform/modules/ec2/`  
**Purpose**: Grant EC2 instance permission to communicate with AWS Systems Manager

#### Attributes

| Attribute              | Type     | Value                                           | Rationale                                      |
|------------------------|----------|-------------------------------------------------|------------------------------------------------|
| name                   | string   | "${var.name}-ssm-role"                          | Descriptive role name                          |
| assume_role_policy     | json     | EC2 service principal trust policy              | Allow EC2 to assume this role                  |
| managed_policy_arns    | list     | ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"] | SSM Session Manager permissions |

#### Trust Policy (Assume Role Policy)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Attached Managed Policies
- **AmazonSSMManagedInstanceCore**: AWS-managed policy providing SSM Session Manager, Run Command, and Patch Manager permissions

#### Tags
Same as EC2 instance tags above.

---

### 4. IAM Instance Profile

**Resource Type**: `aws_iam_instance_profile`  
**Module**: `terraform/modules/ec2/`  
**Purpose**: Attach IAM role to EC2 instance

#### Attributes

| Attribute       | Type     | Value                                           | Rationale                                      |
|-----------------|----------|-------------------------------------------------|------------------------------------------------|
| name            | string   | "${var.name}-instance-profile"                  | Descriptive profile name                       |
| role            | string   | aws_iam_role.ssm_role.name                      | Associate role with profile                    |

---

### 5. AMI Data Source

**Resource Type**: `data "aws_ami"`  
**Module**: `terraform/modules/ec2/` or `terraform/dev/ec2.tf`  
**Purpose**: Dynamically retrieve latest Amazon Linux 2023 AMI

#### Filter Criteria

| Attribute       | Value                                           | Rationale                                      |
|-----------------|------------------------------------------------|------------------------------------------------|
| most_recent     | true                                            | Always use latest AMI with security patches    |
| owners          | ["amazon"]                                      | Official Amazon AMIs only                      |
| name filter     | "al2023-ami-*-x86_64"                           | Amazon Linux 2023, x86_64 architecture         |

---

## Resource Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                        Dev VPC (172.0.0.0/16)               │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Private Subnet (priv_sub1)                         │    │
│  │                                                     │    │
│  │   ┌─────────────────────────────────────────┐      │    │
│  │   │ EC2 Instance (t3.small)                 │      │    │
│  │   │ - AMI: Amazon Linux 2023                │      │    │
│  │   │ - Private IP: 172.0.x.x                 │      │    │
│  │   │ - No Public IP                          │      │    │
│  │   │ - EBS: 20GB gp3 encrypted               │      │    │
│  │   │                                         │      │    │
│  │   │ Attached:                               │      │    │
│  │   │ ├─ Security Group ───────────┐          │      │    │
│  │   │ └─ IAM Instance Profile      │          │      │    │
│  │   │         │                    │          │      │    │
│  │   └─────────┼────────────────────┼──────────┘      │    │
│  │             │                    │                 │    │
│  └─────────────┼────────────────────┼─────────────────┘    │
│                │                    │                       │
│      Ingress Rules:       Attached IAM Role:               │
│      • Port 443 from      AmazonSSMManagedInstanceCore     │
│        192.0.0.0/16                                        │
│        172.0.0.0/16                                        │
│        10.0.0.0/16                                         │
│                                                            │
└────────────────┬───────────────────────────────────────────┘
                 │
                 │ Transit Gateway Routes
                 │
         ┌───────┴────────┐
         │                │
    ┌────▼────┐     ┌────▼────┐
    │Inspection│     │  Prod   │
    │   VPC    │     │   VPC   │
    │192.0/16  │     │ 10.0/16 │
    └──────────┘     └─────────┘
```

---

## Entity Relationships

### Composition
- **EC2 Instance** HAS-A **Root EBS Volume** (1:1, required)
- **EC2 Instance** HAS-A **IAM Instance Profile** (1:1, required)
- **EC2 Instance** HAS-MANY **Security Groups** (1:N, min 1)
- **IAM Instance Profile** HAS-A **IAM Role** (1:1, required)
- **IAM Role** HAS-MANY **IAM Policies** (1:N, min 1)

### Association
- **EC2 Instance** DEPLOYED-IN **Subnet** (N:1, required)
- **Subnet** BELONGS-TO **VPC** (N:1, required)
- **Security Group** BELONGS-TO **VPC** (N:1, required)
- **VPC** ATTACHED-TO **Transit Gateway** (N:1, existing)

---

## Variable Inputs

### Required Variables

| Variable Name | Type   | Description                                      | Example Value              |
|---------------|--------|--------------------------------------------------|----------------------------|
| vpc_id        | string | VPC ID where instance will be deployed           | vpc-0123456789abcdef0      |
| subnet_id     | string | Subnet ID for instance placement                 | subnet-0123456789abcdef0   |
| vpc_name      | string | VPC name for tagging                             | dev                        |
| environment   | string | Environment designation (dev/prod)               | dev                        |

### Optional Variables

| Variable Name | Type   | Default    | Description                                |
|---------------|--------|------------|--------------------------------------------|
| name          | string | (required) | Instance name (e.g., "dev-internal-web-server") |
| instance_type | string | t3.small   | EC2 instance type                          |
| volume_size   | number | 20         | EBS volume size in GB                      |
| ingress_cidrs | list   | [192.0.0.0/16, 172.0.0.0/16, 10.0.0.0/16] | Allowed HTTPS source CIDRs |

---

## Resource Outputs

### Module Outputs

| Output Name           | Type   | Description                                 | Used By                          |
|-----------------------|--------|---------------------------------------------|----------------------------------|
| instance_id           | string | EC2 instance ID                             | SSM Session Manager, monitoring  |
| instance_private_ip   | string | Private IP address of instance              | Application configuration        |
| security_group_id     | string | Security group ID                           | Additional rule management       |
| instance_profile_arn  | string | IAM instance profile ARN                    | Audit, compliance reporting      |
| instance_arn          | string | EC2 instance ARN                            | CloudWatch, resource tagging     |

---

## Validation Rules

### Instance Validation
- ✅ Instance MUST be in private subnet (no public IP auto-assignment)
- ✅ Instance MUST have IAM instance profile attached
- ✅ Instance MUST have at least one security group
- ✅ Root volume MUST be encrypted
- ✅ Root volume MUST be gp3 type

### Security Group Validation
- ✅ Security group MUST have only port 443 TCP ingress
- ✅ Security group MUST NOT allow 0.0.0.0/0 ingress
- ✅ Security group MUST NOT allow port 22 (SSH)
- ✅ Security group MUST NOT allow port 80 (HTTP)

### IAM Validation
- ✅ IAM role MUST have EC2 service principal in trust policy
- ✅ IAM role MUST have AmazonSSMManagedInstanceCore policy attached
- ✅ IAM instance profile MUST reference the SSM IAM role

### Tagging Validation
- ✅ All resources MUST have Environment tag
- ✅ All resources MUST have Project tag = "AWS Infrastructure"
- ✅ All resources MUST have ManagedBy tag = "Terraform"
- ✅ All resources MUST have Owner tag = "DevOps Team"
- ✅ All resources MUST have CostCenter tag
- ✅ All resources MUST have VPC tag

---

## State Management

### Terraform State
- **Backend**: Terraform Cloud (remote state)
- **Workspace**: development
- **State Locking**: Enabled via Terraform Cloud

### State Resources
- `module.internal_web_server.aws_instance.this`
- `module.internal_web_server.aws_security_group.web_server`
- `module.internal_web_server.aws_iam_role.ssm_role`
- `module.internal_web_server.aws_iam_instance_profile.ssm_instance`
- `data.aws_ami.amazon_linux_2023`

---

## Testing Scenarios

### 1. Instance Launch Test
**Given**: Valid VPC and subnet IDs  
**When**: `terraform apply` is executed  
**Then**: EC2 instance reaches "running" state within 5 minutes

### 2. Network Isolation Test
**Given**: Instance is running  
**When**: Public internet attempts to connect  
**Then**: All connections are blocked (no public IP, no public routes)

### 3. HTTPS Connectivity Test
**Given**: Instance is running with nginx  
**When**: HTTPS request from Inspection VPC (192.0.0.0/16)  
**Then**: Request is accepted and returns 200 OK

### 4. SSH Blocking Test
**Given**: Instance is running  
**When**: SSH connection attempt on port 22  
**Then**: Connection is refused (port not in security group)

### 5. SSM Access Test
**Given**: Instance is running with SSM role  
**When**: `aws ssm start-session --target <instance-id>`  
**Then**: Session starts successfully

### 6. Tagging Compliance Test
**Given**: Instance is deployed  
**When**: Query instance tags via AWS CLI  
**Then**: All 7 mandatory tags are present with correct values

---

## References

- [EC2 Module](../../terraform/modules/ec2/)
- [Research Document](./research.md)
- [Feature Specification](./spec.md)
- [AWS EC2 Instance Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS Security Group Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [AWS IAM Role Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
