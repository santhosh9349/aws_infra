// filepath: c:\Users\santh\OneDrive\Documents\git\aws_infra\modules\tgw\variables.tf
variable "description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "Transit Gateway for inspection VPC"
}

variable "tags" {
  description = "Tags for the Transit Gateway"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID to attach to the Transit Gateway"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the VPC attachment (e.g., private subnets)"
  type        = list(string)
}

variable "attachment_tags" {
  description = "Tags for the VPC attachment"
  type        = map(string)
  default     = {}
}

variable "ram_share_name" {
  description = "Name of the RAM resource share for the TGW"
  type        = string
  default     = "inspection-tgw-share"
}

variable "allow_external_principals" {
  description = "Allow sharing with external principals"
  type        = bool
  default     = false
}

variable "ram_tags" {
  description = "Tags for the RAM resource share"
  type        = map(string)
  default     = {}
}