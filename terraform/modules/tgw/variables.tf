variable "description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "Transit Gateway for multi-VPC connectivity"
}

variable "tags" {
  description = "Tags for the Transit Gateway"
  type        = map(string)
  default     = {}
}

variable "vpc_attachments" {
  description = "Map of VPC attachments with their configuration"
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
    tags       = map(string)
  }))
  default = {}
}