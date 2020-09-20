resource "aws_instance" "app" {
  depends_on = [
    aws_route53_record.db,
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  instance_type               = "t3.large"
  ami                         = var.amis["app"]
  subnet_id                   = aws_subnet.b_public.id
  key_name                    = aws_key_pair.ops.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data                   = <<EOF
#cloud-config
# -*- YAML -*-
apt_upgrade: true
locale: en_US.UTF-8
packages:
- mysql-client-core-5.7

write_files:
- path: /home/ubuntu/ssl_certificate/ssl.pem
  content: |
    ${indent(4, data.aws_ssm_parameter.self_signed_cert_pem.value)}
  owner: ubuntu:ubuntu
- path: /home/ubuntu/ssl_certificate/ssl.key
  content: |
    ${indent(4, data.aws_ssm_parameter.self_signed_cert_key.value)}
  owner: ubuntu:ubuntu
- path: /tmp/db-init.sh
  content: |
    ${indent(4, file("${path.module}/db-init.sh"))}
  owner: ubuntu:ubuntu
  permissions: "0755"
- path: /home/ubuntu/.etleap
  content: |
    export CUSTOMER_VPC=1
    export ETLEAP_DEPLOYMENT_ID=${var.deployment_id}
    export USE_PROD_SECRETS=0
    export JOB_ROLE=customer_job,monitor
    export ETLEAP_DB_PASSWORD=${random_password.etleap-db-password.result}
    export SALESFORCE_DB_PASSWORD=${random_password.salesforce-db-password.result}
    export ETLEAP_HOSTS_ALLOWED=".${var.subdomain}"
    export FRONT_END_HOSTNAME="app.${var.subdomain}"
    export ETLEAP_FRONT_END_URL="https://$FRONT_END_HOSTNAME/"
    export ETLEAP_CORS_ALLOWED_ORIGINS="https://app.${var.subdomain}"
    export API_HOSTNAME="app.${var.subdomain}"
    export API_URL="https://$API_HOSTNAME/"
    export ETLEAP_BASE_URL=$API_URL
    export ETLEAP_CONF_FILE=/opt/etleap/prod-customervpc.conf
    export ETLEAP_HTTP_SESSION_DOMAIN="app.${var.subdomain}"
    export ETLEAP_KMS_KEY_VIRGINIA="${aws_kms_key.etleap_encryption_key_virginia.key_id}"
    export ETLEAP_KMS_KEY_OREGON="${aws_kms_key.etleap_encryption_key_oregon.key_id}"
    export ETLEAP_SETUP_FIRST_NAME="${var.first_name}"
    export ETLEAP_SETUP_LAST_NAME="${var.last_name}"
    export ETLEAP_SETUP_EMAIL="${var.email}"
    export ETLEAP_SETUP_PASSWORD="${random_password.temp-user-password.result}"
    export ETLEAP_SETUP_ADMIN_PASSWORD="${data.aws_ssm_parameter.etleap_admin_password.value}"
    export ETLEAP_SETUP_INTERMEDIATE_BUCKET="${aws_s3_bucket.intermediate.id}"
    export ETLEAP_SETUP_INTERMEDIATE_ROLE_ARN="${aws_iam_role.intermediate.arn}"
    export ETLEAP_DMS_ROLE_ARN="${aws_iam_role.dms.arn}"
    export ETLEAP_DMS_INSTANCE_ARN="${aws_dms_replication_instance.dms.replication_instance_arn}"
    export ETLEAP_AWS_ACCOUNT_ID="${var.account_id}"
    export MARKETPLACE_DEPLOYMENT="false"
    export ETLEAP_SECRET_APPLICATION_SECRET="$(aws secretsmanager get-secret-value --secret-id ${var.deployment_secret_arn} | jq -r .SecretString)"

runcmd:
- "sed -i 's/\"dns\": \\[\".*\"\\]/\"dns\": [\"${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.0.2\"]/g' /etc/docker/daemon.json"
- "service docker restart"
- "/tmp/db-init.sh ${data.aws_ssm_parameter.root_db_password.value} ${random_password.etleap-db-password.result} ${random_password.salesforce-db-password.result} ${var.deployment_id}"
- yes | ssh-keygen -f /home/ubuntu/.ssh/id_rsa -N ''
- cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
- ". /home/ubuntu/.etleap && /home/ubuntu/cron-deploy-customervpc.sh"
EOF

  tags = {
    Name = "Etleap App"
  }

  volume_tags = {
    Name = "Etleap App"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "EtleapApp"
  role = aws_iam_role.app.name
}

resource "aws_iam_role" "app" {
  name               = "EtleapApp"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "random_password" "temp-user-password" {
  length  = 16
  special = false
}

output "login-info" {
  value       = random_password.temp-user-password.result
  description = "Temp Password"
}

output "app-ip-address" {
  value       = aws_instance.app.public_ip
  description = "App IP Address"
}
