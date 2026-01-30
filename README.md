# AWS Infrastructure with Terraform

This repository contains Terraform configurations for deploying AWS infrastructure, including VPCs, subnets, EC2 instances, and Transit Gateways (TGW) with Resource Access Manager (RAM) sharing.

## Project Structure

- `environments/`: Environment-specific configurations (e.g., `dev/` for development).
  - `dev/`: Contains Terraform files for the dev environment, including VPCs, subnets, TGW, and outputs.
- `modules/`: Reusable Terraform modules.
  - `ec2/`: Module for EC2 instances.
  - `subnet/`: Module for subnets.
  - `tgw/`: Module for Transit Gateways, including VPC attachments and RAM sharing.
  - `vpc/`: Module for VPCs.
- `scripts/`: Utility scripts (if any).
- `LICENSE`: Apache License 2.0.
- `README.md`: This file.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- Access to Terraform Cloud (organization: "santhosh9349", workspace: "aws_infra")

## Usage

1. Navigate to the desired environment directory (e.g., `cd environments/dev`).
2. Initialize Terraform: `terraform init`
3. Plan the deployment: `terraform plan`
4. Apply the changes: `terraform apply`

### Key Features

- **VPCs**: Creates VPCs for prod, dev, and inspection environments.
- **Subnets**: Deploys public and private subnets in each VPC.
- **TGW**: Sets up a Transit Gateway in the inspection VPC, shared via RAM, with attachments to prod and dev VPCs.
- **EC2**: (Optional) Deploys EC2 instances in specified subnets.

## Modules

- **VPC Module**: Creates AWS VPCs with DNS support.
- **Subnet Module**: Creates subnets within VPCs.
- **TGW Module**: Manages Transit Gateways, attachments, and RAM sharing.
- **EC2 Module**: Provisions EC2 instances.

## Outputs

After deployment, key outputs include VPC IDs, subnet IDs, TGW ID, and RAM share ARN.

## Drift Detection & Notifications

This repository includes automated infrastructure drift detection with Telegram notifications.

### Features

- **Scheduled Drift Detection**: Daily checks at 6 AM UTC
- **Manual Trigger**: Run drift detection on-demand via GitHub Actions
- **Telegram Notifications**: Instant alerts when infrastructure drift is detected
- **Detailed Reports**: Message includes affected resources, change types, and workflow links

### Setup

1. Configure Telegram bot and channel (see [docs/drift-detection/telegram-setup.md](docs/drift-detection/telegram-setup.md))
2. Add GitHub secrets:
   - `TELEGRAM_BOT_TOKEN`: Your Telegram bot token
   - `TELEGRAM_CHANNEL_ID`: Target channel ID or username
3. The drift detection workflow will run automatically on schedule

### Manual Execution

1. Go to **Actions** → **Infrastructure Drift Detection**
2. Click **Run workflow**
3. Select environment (dev/prod)
4. Optionally enable notifications for no-drift results

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.