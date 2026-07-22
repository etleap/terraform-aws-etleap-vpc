// Automated OS patching with AWS Systems Manager Patch Manager. Enabled by
// default; disabled by setting patch_manager_maintenance_window_schedule to
// null. Applies to the instances tagged with PatchGroup=etleap-<deployment_id>.
locals {
  patch_manager_count = var.patch_manager_maintenance_window_schedule == null ? 0 : 1
}

resource "aws_ssm_patch_baseline" "al2023" {
  count = local.patch_manager_count

  name             = "Etleap-${var.deployment_id}-AL2023-Baseline"
  description      = "AL2023 baseline - Security (Critical/Important/Medium/Low) and Bugfix, 7-day auto-approval"
  operating_system = "AMAZON_LINUX_2023"

  rejected_patches        = ["docker*"]
  rejected_patches_action = "BLOCK"

  # Rule 1: Security patches
  approval_rule {
    approve_after_days  = 7
    compliance_level    = "UNSPECIFIED"
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important", "Medium", "Low"]
    }
  }

  # Rule 2: Bugfix patches (no severity filter, all bugfixes)
  approval_rule {
    approve_after_days  = 7
    compliance_level    = "UNSPECIFIED"
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix"]
    }
  }
}

resource "aws_ssm_patch_group" "etleap" {
  count = local.patch_manager_count

  baseline_id = aws_ssm_patch_baseline.al2023[0].id
  patch_group = "etleap-${var.deployment_id}"
}

resource "aws_iam_role" "ssm_maintenance_window" {
  count = local.patch_manager_count

  tags = local.default_tags
  name = "Etleap-${var.deployment_id}-MaintenanceWindow-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_maintenance_window" {
  count = local.patch_manager_count

  role       = aws_iam_role.ssm_maintenance_window[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

resource "aws_iam_role_policy" "ssm_maintenance_window_pass_role" {
  count = local.patch_manager_count

  name = "Etleap-${var.deployment_id}-MaintenanceWindow-PassRole-Policy"
  role = aws_iam_role.ssm_maintenance_window[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowRolePassing"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
        ]
        Resource = [
          aws_iam_role.ssm_maintenance_window[0].arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = ["ssm.amazonaws.com"]
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ssm_patching" {
  count = local.patch_manager_count

  tags              = local.default_tags
  name              = "/etleap/${var.deployment_id}/patch_manager"
  retention_in_days = 365
}

resource "aws_ssm_maintenance_window" "etleap" {
  count = local.patch_manager_count

  name              = "Etleap-${var.deployment_id}-MaintenanceWindow"
  schedule          = var.patch_manager_maintenance_window_schedule
  schedule_timezone = "Etc/UTC"
  cutoff            = 1 # Systems Manager stops issuing new tasks 1 hour before the end of the maintenance window
  duration          = 2 # A 2 hour window, meaning Systems Manager has 1 hour to issue new tasks
}

resource "aws_ssm_maintenance_window_target" "etleap" {
  count = local.patch_manager_count

  window_id     = aws_ssm_maintenance_window.etleap[0].id
  name          = "Etleap-${var.deployment_id}-PatchTargets"
  description   = "Instances in the etleap-${var.deployment_id} patch group"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:PatchGroup"
    values = ["etleap-${var.deployment_id}"]
  }
}

resource "aws_ssm_maintenance_window_task" "install_patches" {
  count = local.patch_manager_count

  window_id        = aws_ssm_maintenance_window.etleap[0].id
  name             = "Apply_Patch_Baseline"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.ssm_maintenance_window[0].arn
  max_concurrency  = "1"
  max_errors       = "1"
  cutoff_behavior  = "CONTINUE_TASK"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.etleap[0].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["NoReboot"]
      }

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.ssm_patching[0].name
        cloudwatch_output_enabled = true
      }
    }
  }
}

// Allows the instances to write patching output to the CloudWatch log group.
resource "aws_iam_policy" "patch_manager_instance_logs" {
  count = local.patch_manager_count

  tags = local.default_tags
  name = "Etleap-${var.deployment_id}-PatchManager-Logs-Limited-Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeLogGroups"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMRunCommandCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          aws_cloudwatch_log_group.ssm_patching[0].arn,
          "${aws_cloudwatch_log_group.ssm_patching[0].arn}:*",
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "patch_manager_instance_logs" {
  count = local.patch_manager_count

  name = "Etleap Patch Manager Instance Logs"
  roles = concat(
    [aws_iam_role.app.name, aws_iam_role.zookeeper.name],
    local.created_vpc_count > 0 ? [aws_iam_role.nat[0].name] : []
  )
  policy_arn = aws_iam_policy.patch_manager_instance_logs[0].arn
}
