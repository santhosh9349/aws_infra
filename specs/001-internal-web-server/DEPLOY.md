# Quick Deployment Guide

## Prerequisites
✅ All code completed and ready for deployment  
⚠️ Requires Terraform Cloud authentication

## Deployment Steps

### 1. Login to Terraform Cloud
```bash
terraform login
```

### 2. Navigate to Dev Environment
```bash
cd terraform/dev
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review Plan
```bash
terraform plan
```
**Expected**: 5 resources to be added (IAM role, instance profile, security group, EC2 instance)

### 5. Deploy Infrastructure
```bash
terraform apply
```

### 6. Get Instance Details
```bash
# Get instance ID
terraform output internal_web_server_instance_id

# Get private IP
terraform output internal_web_server_private_ip

# Get security group ID
terraform output internal_web_server_security_group_id
```

### 7. Test SSM Access
```bash
INSTANCE_ID=$(terraform output -raw internal_web_server_instance_id)
aws ssm start-session --target $INSTANCE_ID
```

### 8. Test HTTPS Connectivity (from within VPC)
```bash
PRIVATE_IP=$(terraform output -raw internal_web_server_private_ip)
curl -k https://$PRIVATE_IP/
curl -k https://$PRIVATE_IP/health
```

## What's Been Configured

### Infrastructure
- ✅ EC2 instance (t3.small) in private subnet
- ✅ Security group (HTTPS from internal VPCs only)
- ✅ IAM role for SSM Session Manager
- ✅ Encrypted 20GB gp3 EBS volume
- ✅ nginx web server with HTTPS (self-signed cert)

### Security
- ✅ No public IP address
- ✅ No SSH access (use SSM Session Manager)
- ✅ HTTPS only (port 443)
- ✅ Internal VPC traffic only

### Tagging
- ✅ All mandatory tags applied
- ✅ Cost tracking enabled (Environment=dev)

## Verification Checklist

After deployment, verify:
- [ ] Instance is running
- [ ] Instance has NO public IP
- [ ] SSM Session Manager works
- [ ] SSH is blocked (port 22 not in security group)
- [ ] HTTPS responds from internal VPCs
- [ ] All 7 mandatory tags present

## Troubleshooting

### Cannot connect to Terraform Cloud
```bash
terraform login
```

### Instance not starting
Check user data logs:
```bash
aws ssm start-session --target <instance-id>
sudo journalctl -u cloud-init-output.log
```

### nginx not responding
Check nginx status:
```bash
aws ssm start-session --target <instance-id>
sudo systemctl status nginx
sudo journalctl -u nginx
```

## Next Steps

1. Deploy the instance (`terraform apply`)
2. Verify all success criteria (see IMPLEMENTATION_SUMMARY.md)
3. Test HTTPS connectivity from other VPCs
4. Complete documentation (Phase 7 tasks)

## Complete Documentation

See [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) for:
- Complete task breakdown
- All verification commands
- Architecture details
- Cost analysis
- Success criteria tracking
