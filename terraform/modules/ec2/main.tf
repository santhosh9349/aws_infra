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
  ami                    = var.ami != "" ? var.ami : data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance.name
  user_data              = var.user_data
  monitoring             = true
  ebs_optimized          = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = var.tags
}
