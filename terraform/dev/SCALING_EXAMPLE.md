# Example: Scaling to 10 VPCs

## Scenario
You need to expand from 3 VPCs (inspection, dev, prod) to 10 VPCs by adding:
- staging
- qa
- uat
- sandbox
- training
- dr
- partner

## Step-by-Step Implementation

### 1. Update `variables.tf`

Replace the `vpcs` variable with:

```terraform
variable "vpcs" {
  description = "Map of VPC names to their CIDR blocks"
  type        = map(string)
  default = {
    # Existing VPCs
    "prod"       = "10.0.0.0/16"
    "dev"        = "172.0.0.0/16"
    "inspection" = "192.0.0.0/16"
    
    # New VPCs - Just add them!
    "staging"    = "10.1.0.0/16"
    "qa"         = "10.2.0.0/16"
    "uat"        = "10.3.0.0/16"
    "sandbox"    = "10.4.0.0/16"
    "training"   = "10.5.0.0/16"
    "dr"         = "10.6.0.0/16"
    "partner"    = "10.7.0.0/16"
  }
}
```

Replace the `subnets` variable with:

```terraform
variable "subnets" {
  description = "Map of VPC names to their subnet CIDRs"
  type        = map(map(string))
  default = {
    # Existing VPCs
    prod = {
      pub_sub1  = "10.0.100.0/24"
      pub_sub2  = "10.0.200.0/24"
      priv_sub1 = "10.0.1.0/24"
      priv_sub2 = "10.0.2.0/24"
    }
    dev = {
      pub_sub1  = "172.0.100.0/24"
      pub_sub2  = "172.0.200.0/24"
      priv_sub1 = "172.0.1.0/24"
      priv_sub2 = "172.0.2.0/24"
    }
    inspection = {
      pub_sub1  = "192.0.100.0/24"
      pub_sub2  = "192.0.200.0/24"
      priv_sub1 = "192.0.1.0/24"
      priv_sub2 = "192.0.2.0/24"
    }
    
    # New VPCs - Following the same pattern
    staging = {
      pub_sub1  = "10.1.100.0/24"
      pub_sub2  = "10.1.200.0/24"
      priv_sub1 = "10.1.1.0/24"
      priv_sub2 = "10.1.2.0/24"
    }
    qa = {
      pub_sub1  = "10.2.100.0/24"
      pub_sub2  = "10.2.200.0/24"
      priv_sub1 = "10.2.1.0/24"
      priv_sub2 = "10.2.2.0/24"
    }
    uat = {
      pub_sub1  = "10.3.100.0/24"
      pub_sub2  = "10.3.200.0/24"
      priv_sub1 = "10.3.1.0/24"
      priv_sub2 = "10.3.2.0/24"
    }
    sandbox = {
      pub_sub1  = "10.4.100.0/24"
      pub_sub2  = "10.4.200.0/24"
      priv_sub1 = "10.4.1.0/24"
      priv_sub2 = "10.4.2.0/24"
    }
    training = {
      pub_sub1  = "10.5.100.0/24"
      pub_sub2  = "10.5.200.0/24"
      priv_sub1 = "10.5.1.0/24"
      priv_sub2 = "10.5.2.0/24"
    }
    dr = {
      pub_sub1  = "10.6.100.0/24"
      pub_sub2  = "10.6.200.0/24"
      priv_sub1 = "10.6.1.0/24"
      priv_sub2 = "10.6.2.0/24"
    }
    partner = {
      pub_sub1  = "10.7.100.0/24"
      pub_sub2  = "10.7.200.0/24"
      priv_sub1 = "10.7.1.0/24"
      priv_sub2 = "10.7.2.0/24"
    }
  }
}
```

### 2. Run Terraform Plan

```bash
cd terraform/dev
terraform plan
```

**Expected Output Summary:**
```
Plan: 117 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ vpc_ids = {
      + dr         = (known after apply)
      + partner    = (known after apply)
      + qa         = (known after apply)
      + sandbox    = (known after apply)
      + staging    = (known after apply)
      + training   = (known after apply)
      + uat        = (known after apply)
    }
```

**Resources Being Created:**
- 7 new VPCs
- 28 new subnets (7 VPCs × 4 subnets each)
- 7 new Internet Gateways
- 7 new TGW VPC attachments
- 14 new route tables (7 public + 7 private)
- 126 new routes (each of 10 VPCs routes to 9 others, both public & private RTs)

### 3. Apply Changes

```bash
terraform apply
```

Type `yes` when prompted.

### 4. Verify Connectivity

After deployment, verify full mesh connectivity:

```bash
# Test from any VPC instance to any other VPC instance
# Example: From dev VPC (172.0.1.10) ping staging VPC (10.1.1.10)

# SSH to dev instance
ssh ec2-user@<dev-instance-ip>

# Ping staging private subnet
ping 10.1.1.10

# Ping qa private subnet
ping 10.2.1.10

# All should work via Transit Gateway!
```

## What Happens Automatically

### Before (3 VPCs):
```
inspection ←→ TGW ←→ dev
      ↓              ↓
   prod ←────────────┘
```

**Routing:**
- inspection → 2 TGW routes (dev, prod)
- dev → 2 TGW routes (inspection, prod)
- prod → 2 TGW routes (inspection, dev)
- **Total: 6 TGW routes**

### After (10 VPCs):
```
     TGW (Hub)
    /  |  |  \
   /   |  |   \
  ↓    ↓  ↓    ↓
[10 VPCs in full mesh]
```

**Routing:**
- Each VPC → 9 TGW routes (to all other 9 VPCs)
- 10 VPCs × 9 routes each = 90 TGW routes
- **Total: 90 TGW routes** (automatically created)

## Infrastructure Created (10 VPCs)

| Resource Type | Count | Details |
|---------------|-------|---------|
| VPCs | 10 | One per environment |
| Subnets | 40 | 4 per VPC (2 public, 2 private) |
| Internet Gateways | 10 | One per VPC |
| Transit Gateway | 1 | Shared by all VPCs |
| TGW Attachments | 10 | One per VPC |
| Route Tables | 20 | 10 public, 10 private |
| TGW Routes | 90 | Full mesh (each VPC to 9 others) |
| IGW Routes | 10 | One default route per public RT |

## Cost Estimate (Monthly)

| Item | Unit Cost | Count | Monthly Cost |
|------|-----------|-------|--------------|
| Transit Gateway | $36/month | 1 | $36 |
| TGW Attachments | $36/month | 10 | $360 |
| IGW | Free | 10 | $0 |
| Route Tables | Free | 20 | $0 |
| **Total Fixed** | | | **~$396/month** |
| Data Transfer | $0.02/GB | Variable | Variable |

## Route Table Example: Dev VPC

### Dev Public Route Table (`dev-public-rt`)
```
Destination         Target
0.0.0.0/0          igw-dev           # Internet access
10.0.0.0/16        tgw-xxx           # To prod
192.0.0.0/16       tgw-xxx           # To inspection
10.1.0.0/16        tgw-xxx           # To staging
10.2.0.0/16        tgw-xxx           # To qa
10.3.0.0/16        tgw-xxx           # To uat
10.4.0.0/16        tgw-xxx           # To sandbox
10.5.0.0/16        tgw-xxx           # To training
10.6.0.0/16        tgw-xxx           # To dr
10.7.0.0/16        tgw-xxx           # To partner
```

### Dev Private Route Table (`dev-private-rt`)
```
Destination         Target
10.0.0.0/16        tgw-xxx           # To prod
192.0.0.0/16       tgw-xxx           # To inspection
10.1.0.0/16        tgw-xxx           # To staging
10.2.0.0/16        tgw-xxx           # To qa
10.3.0.0/16        tgw-xxx           # To uat
10.4.0.0/16        tgw-xxx           # To sandbox
10.5.0.0/16        tgw-xxx           # To training
10.6.0.0/16        tgw-xxx           # To dr
10.7.0.0/16        tgw-xxx           # To partner
```

## Rollback (If Needed)

If you need to rollback:

```bash
# Remove the 7 new VPCs from variables.tf
# Keep only: prod, dev, inspection

terraform plan   # Shows 117 resources to destroy
terraform apply  # Removes the 7 new VPCs safely
```

The original 3 VPCs remain untouched!

## Key Takeaways

✅ **Zero Code Changes Required** - Just update variables  
✅ **Automatic Route Creation** - All 90 TGW routes created automatically  
✅ **Full Mesh Connectivity** - Every VPC can reach every other VPC  
✅ **Idempotent** - Can add/remove VPCs without affecting others  
✅ **Type Safe** - Terraform validates CIDR blocks and naming  

## Next Steps

1. **Update Security Groups** to allow traffic from new VPC CIDRs
2. **Add VPC Flow Logs** for monitoring
3. **Configure AWS Network Firewall** if using inspection VPC
4. **Set up CloudWatch Dashboards** for TGW metrics
5. **Document IP addressing** for teams
6. **Test connectivity** between all VPCs

## Architecture Diagram (10 VPCs)

```
                    Internet
                       |
        ┌──────────────┼──────────────┐
        |              |              |
       IGW           IGW            IGW
        |              |              |
   [prod VPC]     [dev VPC]   [inspection VPC]
        |              |              |
        └──────────────┼──────────────┘
                       |
                  Transit Gateway
                       |
        ┌──────────────┼──────────────────────┐
        |              |              |        |
   [staging]        [qa VPC]      [uat]   [sandbox]
        
   [training]      [dr VPC]    [partner]
        
     Full Mesh Connectivity via TGW
     90 Routes (10 VPCs × 9 destinations)
```

All done! 🚀
