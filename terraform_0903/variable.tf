# variable.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the Subnet"
  type        = list(map(string))
  default = [
    { "ca-central-1a" = "10.0.1.0/24", "ca-central-1b" = "10.0.2.0/24", "ca-central-1d" = "10.0.3.0/24" },
    { "ca-central-1a" = "10.0.11.0/24", "ca-central-1b" = "10.0.12.0/24", "ca-central-1d" = "10.0.13.0/24" }
  ]
}

variable "default_name" {
  description = "Tag header for resources"
  type        = string
  default     = ""
}

