variable "region" {
  default = "us-east-1"
}

// Configurable variables begin here
// ---------------------------------

variable "deployment_id" {
  default = "test"
}

variable "account_id" {
  default = "959096951266"
}

variable "vpc_cidr_block_1" {
  default = "10"
}

variable "vpc_cidr_block_2" {
  default = "10"
}

variable "subdomain" {
  default = "dev.etleap.com"
}

variable "route53_zone_id" {
  default = "ZANDWKR8HMQO4"
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDlDHFDLsQwpRli0Hfvbl1r08AY52HpC2lyCqYyWtIVIw6KUyRwqFVWVuxOqE5mCiQylxDRH8t3Xtgan1FF5bZN3fcyA+tr3ShT+Lg4Vz/RGtrYS29kTr4o+ZtJfa0GEhxCa3EgyJdEebeJfFu1CJlSEVUF6DajF32Rmyg/lqHbV5RN4HyO6s8+ZVNFuQw+WWyU1H2oaDsYqp9ojMJ/jQEFnI4iN9btzzViG19R0uUX4QaSWwAmZkrGE2InhhxyWObEsvIgigkS/tFT7E8LckYH+53/umtiRKBv1KRaRJQWTLOFIrDp7Xrh9d4Jj8csCoqHRtr0UG5HprL16e9pepPq60HY6BUNEhxb56v/uERi3epOt+hqtJYVUq89FyxhBgtIHSz6wKoIpQ7YInOCoO2LE06y1+Inf07cuDOCaodeCAqgvtR8U3or7CNr2uT0ZhhTLPuVoy1VNEbaGQkCVG197JXNWEdPNMVPPPkgCoVT14RdOsxZSBcqQ+yqMtJyFAyuL9A9Ix6/qnnV7u93KN6Yia0gza2SKIp+WmVpTWHANAnzJ/v/eQIPbOIKOblqrPLTeu1aDnewoQInoO/mXjS7Rwl7u63efqNKe0a9X2EmNnlf8aEUyqjH5KrccPvUdi16m88nuveYKLkqevEUb+/xPKt+Pl8DgtpygNpZbwdSrw== caius@ip-192-168-7-110.ec2.internal"
}

variable "first_name" {
  default = "Caius"
}

variable "last_name" {
  default = "Brindescu"
}

variable "email" {
  default = "caius@etleap.com"
}

// -----------------------------
// End of configurable variables

variable "vpn_cidr_block" {
  default = "0.0.0.0/32"
}

data "aws_ssm_parameter" "root_db_password" {
  name = "/etleap/root_db_password"
}

data "aws_ssm_parameter" "etleap_admin_password" {
  name = "/etleap/etleap_admin_password"
}

data "aws_ssm_parameter" "self_signed_cert_key" {
  name = "/etleap/self_signed_cert_key"
}

data "aws_ssm_parameter" "self_signed_cert_pem" {
  name = "/etleap/self_signed_cert_pem"
}

data "aws_ssm_parameter" "github_access_token" {
  name = "/etleap/github_access_token"
}

data "aws_caller_identity" "current" {}

variable "amis" {
  default = {
    app          = "ami-046ce6172c7e24849"
    nat          = "ami-00a9d4a05375b2763"
  }
}

provider "aws" {
   version = ">= 2.37.0"
}
