// Role Devops allows to be assumed by users from the account 841591717599 (vpcdeployments) logged with active MFA
resource "aws_iam_role" "etleap-role-devops" {
  count       = var.allow_iam_devops_role ? 1 : 0
  name        = "Etleap-${var.deployment_id}-Devops-Role"
  description = "Role for Etleap Devops users"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::841591717599:root"
          },
          "Action": "sts:AssumeRole",
          "Condition": {
            "Bool": {"aws:MultiFactorAuthPresent": "true"},
            "StringLike": { "sts:RoleSessionName": "$${aws:username}" }
          }
        }
    ]
}
EOF
}

output "iam_role_devops_arn" {
  description = "IAM Devops Role ARN to be used by Etleap Devops users"
  value       = var.allow_iam_devops_role ? aws_iam_role.etleap-role-devops[0].arn : null
}

resource "aws_iam_role_policy_attachment" "devops-admin-access" {
  count       = var.allow_iam_devops_role ? 1 : 0

  role       = aws_iam_role.etleap-role-devops[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
