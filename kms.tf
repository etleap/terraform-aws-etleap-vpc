provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

provider "aws" {
  alias  = "oregon"
  region = "us-west-2"
}

resource "aws_kms_key" "etleap_encryption_key_virginia" {
  provider                = aws.virginia
  description             = "Etleap secrets encryption key virginia region"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {account_id = var.account_id})

  tags = {
    Name = "Etleap KMS"
  }
}

resource "aws_kms_key" "etleap_encryption_key_oregon" {
  provider                = aws.oregon
  description             = "Etleap secrets encryption key oregon"
  deletion_window_in_days = 30
  policy                  = templatefile("${path.module}/kms-policy.json", {account_id = var.account_id})

  tags = {
    Name = "Etleap KMS Oregon"
  }
}

