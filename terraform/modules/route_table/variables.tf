variable "vpc_id" {
  description = "The ID of the VPC where the route table will be created"
  type        = string
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway for inter-VPC routing"
  type        = string
  default     = null
}

variable "destination_cidr_blocks" {
  description = "Set of destination CIDR blocks to route through Transit Gateway"
  type        = set(string)
  default     = []
}

variable "internet_gateway_id" {
  description = "The ID of the Internet Gateway for public subnet routing (optional - use empty string for none)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the route table"
  type        = map(string)
  default     = {}
}
