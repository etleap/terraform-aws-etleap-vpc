resource "aws_autoscaling_group" "elva" {
  depends_on                = [aws_lb_listener.elva_https, aws_lb_listener.elva_http]
  vpc_zone_identifier       = [var.subnet_a_private_id, var.subnet_b_private_id]
  min_size                  = 4
  max_size                  = 100
  health_check_type         = "ELB"
  health_check_grace_period = 900
  launch_configuration      = aws_launch_configuration.elva.name
  target_group_arns         = [aws_lb_target_group.elva.arn]
  enabled_metrics           = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"]
}

resource "aws_autoscaling_policy" "elva" {
  name = "Etleap Elva Target Tracking Policy ${var.deployment_id}"
  autoscaling_group_name = aws_autoscaling_group.elva.name
  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 300
  target_tracking_configuration {
    target_value = 6000
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${aws_lb.elva.arn_suffix}/${aws_lb_target_group.elva.arn_suffix}"
    }
  }
}

resource "aws_launch_configuration" "elva" {
  name_prefix          = "etleap-${var.deployment_id}-elva-vpc"
  image_id             = var.ami
  instance_type        = "t3.medium"
  iam_instance_profile = aws_iam_instance_profile.elva.name
  security_groups      = [aws_security_group.elva-node.id]
  enable_monitoring    = true
  user_data = <<EOF
#!/bin/bash
set -euo pipefail

gpasswd -a ec2-user docker
systemctl enable --now docker

for i in 1 2 3; do
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 841591717599.dkr.ecr.us-east-1.amazonaws.com && docker pull 841591717599.dkr.ecr.us-east-1.amazonaws.com/elva && break || sleep 3;
done

docker run -d -e AWS_REGION=${var.region} -e ELVA_ENV=vpc -e CONFIG_BUCKET_NAME=${var.config_bucket.bucket} -e AWS_ACCESS_KEY=${aws_iam_access_key.elva.id} -e AWS_SECRET_KEY=${aws_iam_access_key.elva.secret} -p 3000:3000 -p 8889:8889 841591717599.dkr.ecr.us-east-1.amazonaws.com/elva

EOF

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}