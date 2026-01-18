variable "name" {
  description = "Name for the EC2 instance and associated resources"
  type        = string
}

variable "ami" {
  description = "AMI ID for the EC2 instance (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group creation"
  type        = string
}

variable "ingress_cidrs" {
  description = "List of CIDR blocks allowed HTTPS ingress access"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
