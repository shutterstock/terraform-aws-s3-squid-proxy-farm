###
# Required variables.
###
variable "vpc_id" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "proxy_allowed_cidr" {
  type = "string"
}

variable "ssh_allowed_cidr" {
  type = "string"
}

# Environment (ex: dev or prod) gets appended to names and tags.
variable "environment" {
  type = "string"
}

###
# Optional variables. Generally okay to leave at the default.
###

# Additional tags to apply to all tagged resources.
variable "extra_tags" {
  type = "map"
}

variable "proxy_port" {
  default = 3128
}

variable "egress_allowed_cidr" {
  default = [
    "0.0.0.0/0",
  ]
}

variable "min_size" {
  default = 3
}

variable "max_size" {
  default = 9
}

variable "ami_id" {
  # Centos 7 w/ENI. ENI is required for the m5 instance type.
  default = "ami-9887c6e7"
}

variable "instance_type" {
  default = "m5.xlarge"
}