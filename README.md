[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)


# AWS Terraform module to create an S3 Squid proxy farm on AWS

This repository contains Terraform code to create a [Squid](http://www.squid-cache.org/) proxy in front of S3 on AWS, including:

- An AutoScalingGroup (ASG)
- Network Load Balancer (NLB)
- A SecurityGroup (SG) for the instances
- CloudWatch autoscaling polices
- An SSH keypair for access to the proxy instances
- Appropriate names and tags on all resources

The stack uses an existing official CentOS AMI by default. The Squid proxy is installed and configured via a user data script on the ASG LaunchConfiguration. You should be able to easily replace the AMI with any CentOs/RedHat compatible AMI.

## Usage as a Terraform module

This module is designed to be used in an existing VPC with existing subnets. You must provide the identifiers for these (plus a couple other variables) in order to utilize the module. Required and optional inputs are [described below](#inputs). An example usage is as follows (see also the `example` directory):

```hcl
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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vpc_id | The ID of the VPC where resources will be created. | string | `` | yes |
| subnet_ids | A list of IDs of subnets inside the VPC. | list | `[]` | yes |
| proxy_allowed_cidr | The CIDR range that should be allowed to access the proxy. | string | `` | yes |
| ssh_allowed_cidr | The CIDR range that should be allowed to SSH to the EC2 instances. | string | `` | yes |
| environment | The environment name (ex: dev, prod) which will be used in resources names and tags. | string | `` | yes |
| extra_tags | A map of extra AWS Tags which should be applied to resources. | map | `{}` | `no` |
| proxy_port | The desired Squid proxy port | string | `3128` | `no` |
| egress_allowed_cidr | The CIDR range that will be allowed to ping the proxy instances.  | list | `["0.0.0.0/0"]` | `no` |
| min_size | Minimum Auto Scaling Group size. | string | `3` | `no` |
| max_size | Maximum Auto Scaling Group size. | string | `9` | `no` |
| ami_id | EC2 AMI ID -- requires ENI support for m5 instance types. | string | `ami-9887c6e7` | `no` |
| instance_type | Instance type for proxy instances. | string | `m5.xlarge` | `no` |

## Outputs

| Name | Description |
|------|-------------|
| private_key | The SSH private key in OpenSSH format. |
| nlb_dns | The AWS created DNS entry for the Network Load Balancer. |

## License

[MIT](https://opensource.org/licenses/MIT). A copy is also availble in the [LICENSE](./LICENSE.md) file in the repository.
