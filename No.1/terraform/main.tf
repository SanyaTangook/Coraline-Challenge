terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# The public tier intentionally contains one subnet. Two private database
# subnets are required because AWS RDS DB subnet groups must span at least two
# Availability Zones.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = var.name
  cidr = var.vpc_cidr

  azs             = [var.availability_zone, var.secondary_availability_zone]
  public_subnets  = [var.public_subnet_cidr]
  private_subnets = [var.private_db_subnet_cidr_a, var.private_db_subnet_cidr_b]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # A public subnet needs an Internet Gateway and a default route. The module
  # creates both when public_subnets is specified.
  map_public_ip_on_launch = true

  # Leave the default security group closed. Workload security groups should
  # explicitly allow only the traffic each workload needs.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_in_days
  flow_log_max_aggregation_interval               = 60

  public_subnet_tags = merge(var.tags, {
    Name = "${var.name}-${var.availability_zone}-public"
    Tier = "public"
  })

  private_subnet_tags = merge(var.tags, {
    Tier = "database"
  })

  tags = merge(var.tags, {
    Name = var.name
  })
}
