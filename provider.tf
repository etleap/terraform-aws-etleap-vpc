terraform {
  required_version = ">= 1.0.5, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73"
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
