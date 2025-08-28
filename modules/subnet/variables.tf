variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = null
}

variable "map_public_ip_on_launch" {
  description = "Assign public IPs to instances in this subnet"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the subnet"
  type        = map(string)
  default     = {}
}
