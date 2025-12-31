variable "vpc_id" {
  description = "The ID of the VPC where the route table will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with this route table"
  type        = list(string)
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
  description = "The ID of the Internet Gateway for public subnet routing (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the route table"
  type        = map(string)
  default     = {}
}
