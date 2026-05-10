terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = "rizal"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "security_groups" {
  source      = "../../modules/security_groups"
  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  admin_cidr  = var.admin_cidr
}

module "s3" {
  source      = "../../modules/s3"
  project     = var.project
  environment = var.environment
}

module "iam" {
  source        = "../../modules/iam"
  project       = var.project
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}
