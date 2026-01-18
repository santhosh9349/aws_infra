# Research & Technical Decisions
**Feature**: Internal Web Server for Client Dashboard  
**Branch**: 001-internal-web-server  
**Date**: 2026-01-17

## Overview
This document captures research findings and technical decisions made during the planning phase for deploying a secure internal web server in the Development VPC.

---

## 1. EC2 Instance Type Selection

### Decision
**Use t3.small (2 vCPU, 2 GB RAM)** as the default instance type with variable override capability.

### Rationale
- **Requirement**: Minimal resource footprint for development workload (FR-007, SC-005)
- **Options Evaluated**:
  - **t3.micro** (2 vCPU, 1 GB RAM, ~$8/month): Very cost-effective but may be underpowered for a web dashboard with API calls
  - **t3.small** (2 vCPU, 2 GB RAM, ~$15/month): Balanced cost/performance for web applications
  - **t3.medium** (2 vCPU, 4 GB RAM, ~$30/month): Over-provisioned for development needs
- **Testing Approach**: Deploy with t3.small, monitor resource utilization via CloudWatch
- **Cost Impact**: ~$15/month for 24/7 operation in development environment

### Alternatives Considered
- **t3.micro rejected**: Risk of memory constraints causing performance issues for dashboard application
- **Graviton-based instances (t4g family) rejected**: Requires ARM-compatible software, adds complexity for development environment

---

## 2. No-SSH Management with AWS Systems Manager

### Decision
**Use AWS Systems Manager Session Manager** with IAM instance profile for secure shell access without SSH.

### Rationale
- **Requirement**: Prohibit traditional shell access protocols (FR-004, SC-004)
- **SSM Session Manager Capabilities**:
  - Secure shell access via AWS console or AWS CLI
  - No need for SSH keys, bastion hosts, or open inbound ports
  - Full audit logging in CloudTrail
  - Supports shell, PowerShell, and port forwarding
- **Prerequisites**:
  - IAM instance profile with `AmazonSSMManagedInstanceCore` managed policy
  - SSM agent (pre-installed on Amazon Linux 2023)
  - Network connectivity to SSM endpoints (via VPC endpoints or NAT Gateway)

### Implementation Details
- **IAM Role**: Create instance profile with SSM policy attachment
- **SSM Agent**: Pre-installed on Amazon Linux 2023, no additional setup
- **Connectivity**: Dev VPC has Transit Gateway connectivity; SSM endpoints reachable via private routing
- **Access Pattern**: `aws ssm start-session --target <instance-id> --region us-east-1`

### Alternatives Considered
- **SSH with restrictive security groups rejected**: Violates organizational no-SSH policy
- **AWS Systems Manager Run Command rejected**: Good for one-off commands but doesn't provide interactive shell for troubleshooting

---

## 3. Security Group Configuration

### Decision
**Allow HTTPS (port 443) ingress from all internal VPC CIDRs**: 192.0.0.0/16 (Inspection VPC), 172.0.0.0/16 (Dev VPC), 10.0.0.0/16 (Prod VPC).

### Rationale
- **Requirement**: Accept HTTPS traffic from internal networks via Transit Gateway mesh (FR-005, FR-006, SC-003, SC-008)
- **Current Architecture**: 3 VPCs with full mesh connectivity via Transit Gateway
- **Security Posture**: Least-privilege access (no 0.0.0.0/0), HTTPS only (no HTTP or other protocols)

### Security Group Rules
**Ingress**:
- Port 443 TCP from 192.0.0.0/16 (Inspection VPC)
- Port 443 TCP from 172.0.0.0/16 (Dev VPC - intra-VPC communication)
- Port 443 TCP from 10.0.0.0/16 (Prod VPC)

**Egress**:
- All traffic to 0.0.0.0/0 (required for OS updates, SSM agent communication)

### Alternatives Considered
- **Allow only Dev VPC CIDR rejected**: Client dashboard needs to communicate with services in other VPCs
- **Allow all private RFC1918 ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) rejected**: Over-permissive, includes ranges not in our architecture

---

## 4. EBS Volume Configuration

### Decision
**Use 20 GB gp3 general purpose SSD** with encryption enabled.

### Rationale
- **Requirement**: Encryption at rest (Constitution IV), minimal resources (FR-007)
- **gp3 Advantages**:
  - 20% lower cost than gp2 (predecessor)
  - Baseline 3,000 IOPS and 125 MiB/s throughput
  - Sufficient for web server OS and application
- **Size**: 20 GB covers Amazon Linux 2023 (~3 GB) + web server software + application files + logs

### Configuration
- **Volume Type**: gp3
- **Size**: 20 GB
- **Encryption**: Enabled (AWS managed key)
- **Delete on Termination**: True (development environment, no data persistence needed)

### Alternatives Considered
- **gp2 volumes rejected**: Higher cost, no performance benefit for this workload
- **io1/io2 provisioned IOPS rejected**: Over-provisioned for development web server
- **Magnetic (st1) rejected**: Legacy, slower performance

---

## 5. Amazon Machine Image (AMI) Selection

### Decision
**Use latest Amazon Linux 2023 AMI** (retrieved dynamically via Terraform data source).

### Rationale
- **AWS-Optimized**: Tuned for AWS EC2 performance
- **SSM Agent**: Pre-installed, no additional setup required
- **Security Updates**: Long-term support with regular security patches
- **Free Tier Eligible**: No OS licensing costs
- **Stable**: Enterprise-grade Linux distribution based on Fedora

### Data Source Configuration
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

### Alternatives Considered
- **Ubuntu 22.04 LTS rejected**: Good alternative but requires SSM agent installation, less AWS-optimized
- **Amazon Linux 2 (AL2) rejected**: End of support 2025-06-30, AL2023 is the successor
- **Windows Server rejected**: Higher cost, unnecessary for web server workload

---

## 6. Private Subnet Selection

### Decision
**Use `priv_sub1` in Dev VPC** as default, with variable override capability for multi-AZ deployment.

### Rationale
- **Requirement**: Place server in private network zone with no public IP (FR-002, FR-003, SC-002)
- **Dev VPC Subnets**:
  - `priv_sub1`: Private subnet in AZ 1
  - `priv_sub2`: Private subnet in AZ 2
- **Single Instance**: Development workload doesn't require multi-AZ high availability
- **Future Scalability**: Module supports variable-driven subnet selection for multi-AZ deployment

### Network Isolation
- **No Public IP**: Private subnet instances do not receive public IPv4 addresses
- **No Internet Gateway Routes**: Private route tables only have routes to Transit Gateway
- **Outbound Connectivity**: Via Transit Gateway to other VPCs or NAT Gateway (if configured)

### Alternatives Considered
- **Public subnet rejected**: Violates requirement for complete public internet isolation (FR-002, SC-002)
- **Multi-AZ deployment rejected for MVP**: Single instance sufficient for development; adds complexity without benefit

---

## 7. User Data Script for Initial Configuration

### Decision
**Minimal user data script** to install nginx web server and enable HTTPS for connectivity testing.

### Rationale
- **Requirement**: Enable HTTPS connectivity testing (SC-003, SC-008)
- **Out of Scope**: Client dashboard application deployment (per specification)
- **Purpose**: Validate infrastructure is working before application deployment

### User Data Script
```bash
#!/bin/bash
yum update -y
yum install -y nginx
systemctl enable nginx
systemctl start nginx

# Generate self-signed certificate for HTTPS testing
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx.key \
  -out /etc/nginx/ssl/nginx.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=internal-dashboard"

# Configure nginx for HTTPS
cat > /etc/nginx/conf.d/https.conf <<EOF
server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    location / {
        return 200 'Internal Web Server - Ready for Dashboard Deployment\n';
        add_header Content-Type text/plain;
    }
}
EOF

systemctl restart nginx
```

### Alternatives Considered
- **No user data rejected**: Instance would have no running service to test HTTPS connectivity
- **Apache httpd rejected**: Nginx is lighter weight and more common for modern web applications
- **Pre-built AMI with web server rejected**: Adds AMI management overhead for development environment

---

## 8. Tagging Strategy

### Decision
**Apply all mandatory tags** per Constitution IV requirements.

### Tag Values
| Tag Key       | Tag Value           | Rationale                                    |
|---------------|---------------------|----------------------------------------------|
| Environment   | dev                 | Development environment designation          |
| Project       | AWS Infrastructure  | Project name per constitution                |
| ManagedBy     | Terraform           | IaC tool for auditability                    |
| Owner         | DevOps Team         | Ownership for accountability                 |
| CostCenter    | dev                 | Cost allocation to development budget        |
| VPC           | dev                 | VPC association for network-specific queries |
| Name          | dev-internal-web-server | Human-readable instance identifier      |

### Compliance Verification
- Tags enable cost tracking (SC-006)
- Tags enable ownership attribution (SC-007)
- Tags meet Constitution IV requirements

### Alternatives Considered
- **Application-specific tags rejected**: Client dashboard application deployment is out of scope
- **Automated tagging via AWS Config rejected**: Terraform-based tagging is simpler and more explicit

---

## 9. Transit Gateway Routing

### Decision
**Leverage existing Transit Gateway configuration** with no modifications required.

### Rationale
- **Current State**: Dev VPC already has Transit Gateway attachment with routes to all other VPCs
- **Connectivity**: Instance in private subnet automatically inherits TGW routes
- **Testing**: HTTPS connectivity from other VPCs will work immediately after deployment

### Verification Steps
1. Deploy EC2 instance in `priv_sub1`
2. Verify route table has TGW route (already configured in `terraform/dev/route_tables.tf`)
3. Test HTTPS from Inspection VPC or Prod VPC instances

### Alternatives Considered
- **VPC Peering rejected**: Transit Gateway provides scalable mesh connectivity, already implemented
- **VPN connections rejected**: Adds complexity, TGW is the standard for inter-VPC communication

---

## 10. Monitoring and Logging (Future Enhancement)

### Decision
**Out of scope for MVP** but documented for future phases.

### Future Enhancements
- **CloudWatch Logs**: Capture nginx access/error logs
- **CloudWatch Metrics**: CPU, memory, disk, network utilization
- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch Alarms**: Alert on high CPU, memory, or failed health checks

### Rationale
- **Requirement**: Specification marks monitoring/alerting as out of scope
- **Best Practice**: Should be added in production-ready phase

---

## Summary of Key Technologies

| Component               | Technology Choice           | Version/Type    |
|-------------------------|-----------------------------|-----------------|
| Compute                 | AWS EC2 t3.small            | 2 vCPU, 2 GB    |
| Operating System        | Amazon Linux 2023           | Latest AMI      |
| Storage                 | EBS gp3                     | 20 GB encrypted |
| Management              | AWS Systems Manager         | Session Manager |
| Network Security        | Security Group              | HTTPS only      |
| Web Server              | Nginx                       | Latest stable   |
| Access Control          | IAM Instance Profile        | SSM policy      |
| Tags                    | AWS Resource Tags           | 7 mandatory     |

---

## Open Questions / Future Decisions

1. **NAT Gateway**: Does Dev VPC have NAT Gateway for outbound internet (OS updates, SSM endpoints)?
   - **Resolution**: Check `terraform/dev/` configuration; if not present, consider VPC endpoints for SSM

2. **HTTPS Certificate**: Self-signed cert for testing; production dashboard needs valid certificate
   - **Resolution**: Out of scope (application deployment), document in handoff

3. **Application Port**: Dashboard may run on different port (e.g., 8080) behind nginx reverse proxy
   - **Resolution**: Out of scope, nginx config can be updated during application deployment

4. **Backup Strategy**: No EBS snapshots or backup policy defined
   - **Resolution**: Development environment, acceptable; production would require backup

5. **Auto-scaling**: Single instance, no scaling policy
   - **Resolution**: Out of scope (specification marks horizontal scaling as out of scope)

---

## References

- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Amazon Linux 2023 Documentation](https://docs.aws.amazon.com/linux/al2023/)
- [AWS VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Constitution (Constitution IV - Security & Compliance)](.specify/memory/constitution.md)
- [TGW Connectivity Guide](../../terraform/dev/TGW_CONNECTIVITY_GUIDE.md)
