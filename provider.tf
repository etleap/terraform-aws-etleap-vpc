terraform {
  required_version = ">= 1.0.5, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.28"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = merge({
      Deployment = var.deployment_id
    }, var.resource_tags)
  }
}
