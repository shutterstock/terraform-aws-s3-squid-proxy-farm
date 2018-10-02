provider "aws" {
  region = "us-east-1"
}

module "s3-proxy-dev" {
  source = "../"
  vpc_id = "vpc-abc123"

  subnet_ids = [
    "subnet-abc123",
    "subnet-def456",
    "subnet-ghi789",
  ]

  environment        = "dev"
  proxy_allowed_cidr = "10.0.0.0/8"
  ssh_allowed_cidr   = "10.0.0.0/8"

  extra_tags = {
    "CostCenter" = "Stuff"
    "More"      = "tags"
  }
}

## Expose the module outputs.
output "private_key" {
  value = "${module.s3-proxy-dev.private_key}"
}

output "nlb_dns" {
  value = "${module.s3-proxy-dev.nlb_dns}"
}
