variable "name" {
}

variable "length" {
  type = number
}

variable "tags" {
  type = map(string)
  default = {}
}

resource "aws_secretsmanager_secret" "secret" {
  tags                    = var.tags
  name                    = var.name
  recovery_window_in_days = 30

  lifecycle {
    # Deletion Protection
    prevent_destroy = true
  }
}

resource "random_password" "secret_value" {
  length  = var.length
  special = false
  lifecycle {
    ignore_changes = [length, lower, min_lower, min_numeric, min_special, min_upper, numeric, special, upper, keepers]
  }
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = random_password.secret_value.result

  lifecycle {
    ignore_changes = [ secret_string ]
  }
}

output "arn" {
  value = aws_secretsmanager_secret.secret.arn
}

output "secret_string" {
  sensitive = true
  value     = aws_secretsmanager_secret_version.secret.secret_string
}
