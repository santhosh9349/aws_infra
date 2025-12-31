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