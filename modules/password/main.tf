variable "name" {
}

variable "length" {
  type = number
}

resource "aws_secretsmanager_secret" "secret" {
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
    ignore_changes = [id, length, lower, min_lower, min_numeric, min_special, min_upper, number, special, upper, keepers]
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
