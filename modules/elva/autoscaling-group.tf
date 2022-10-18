resource "aws_autoscaling_group" "elva" {
  vpc_zone_identifier       = [var.subnet_a_id, var.subnet_b_id]
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
  name = "Target Tracking Policy"
  autoscaling_group_name = aws_autoscaling_group.elva.name
  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 300
  target_tracking_configuration {
    target_value = 6000
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${var.load_balancer.arn_suffix}/${aws_lb_target_group.elva.arn_suffix}"
    }
  }
}

resource "aws_launch_configuration" "elva" {
  name_prefix          = "elva-vpc"
  image_id             = "ami-08389d60"
  instance_type        = "m1.medium"
  iam_instance_profile = aws_iam_instance_profile.elva.name
  key_name             = var.key_name
  security_groups      = [aws_security_group.elva-node.id]
  enable_monitoring    = true
  user_data            = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install ntp -y
export VERSION=18.06.1-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
curl https://get.docker.com | /bin/bash
sudo usermod -aG docker ubuntu

sudo apt-get install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws ecr get-login-password | sudo -H docker login --username AWS --password-stdin 841591717599.dkr.ecr.us-east-1.amazonaws.com && sudo -H docker pull 841591717599.dkr.ecr.us-east-1.amazonaws.com/elva

sudo docker run -d -e AWS_REGION=${var.region} -e ELVA_ENV=vpc -e CONFIG_BUCKET_NAME=${var.config_bucket.bucket} -e AWS_ACCESS_KEY=${aws_iam_access_key.elva.id} -e AWS_SECRET_KEY=${aws_iam_access_key.elva.secret} -p 3000:3000 -p 8889:8889 841591717599.dkr.ecr.us-east-1.amazonaws.com/elva 
EOF


  lifecycle {
    create_before_destroy = true
  }
}