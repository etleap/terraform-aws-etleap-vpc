// Used for triggering the replacement of an EMR cluster when configuration changes require it, but we can't do it via TF alone
// e.g. changes that require replacing Instance Fleets, should replace the entire cluster, as Instance Fleets can't be deleted (1), and 
// we don't support multiple Spot Instance Fleets per cluster.
// 
// (1) https://registry.terraform.io/providers/hashicorp/aws/5.59.0/docs/resources/emr_instance_fleet
resource "null_resource" "emr_configuration_change" {
  triggers = {
    emr_instance_fleet_smallest_instance_size = var.emr_instance_fleet_smallest_instance_size
  }
}

resource "aws_emr_cluster" "emr" {
  depends_on = [
    aws_instance.nat
  ]
  tags                              = merge({Name = "Etleap EMR ${var.deployment_id}"}, local.default_tags)
  name                              = "Etleap EMR"
  release_label                     = "emr-5.35.0"
  applications                      = ["Hadoop", "Spark"]
  keep_job_flow_alive_when_no_steps = true
  log_uri                           = "s3://${aws_s3_bucket.intermediate.id}/emr-logs/"
  service_role                      = aws_iam_role.emr_default_role.name
  security_configuration            = var.emr_security_configuration_name

  ec2_attributes {
    key_name                          = var.key_name
    subnet_id                         = local.subnet_b_private_id
    emr_managed_master_security_group = aws_security_group.emr-master-managed.id
    emr_managed_slave_security_group  = aws_security_group.emr-slave-managed.id
    service_access_security_group     = aws_security_group.emr-service-access-managed.id
    additional_master_security_groups = join(",", concat([aws_security_group.emr.id], var.extra_security_groups))
    additional_slave_security_groups  = join(",", concat([aws_security_group.emr.id], var.extra_security_groups))
    instance_profile                  = aws_iam_instance_profile.emr_profile.name
  }

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [ null_resource.emr_configuration_change ]
  }

  master_instance_fleet {
    name = "MASTER"

    launch_specifications {
      on_demand_specification {
        allocation_strategy = "lowest-price"
      }
    }

    instance_type_configs {
      instance_type = "m5.xlarge"
      ebs_config {
        size                 = "128"
        type                 = "gp2"
        volumes_per_instance = 1
      }
    }

    target_on_demand_capacity = 1
  }

  core_instance_fleet {
    name = "CORE"

    launch_specifications {
      on_demand_specification {
        allocation_strategy = "lowest-price"
      }
    }

    instance_type_configs {
      instance_type = "r5.xlarge"

      # /mnt and /mnt1
      ebs_config {
        size                 = "512"
        type                 = "gp2"
        volumes_per_instance = 2
      }
    }

    target_on_demand_capacity = var.emr_core_node_count
  }

  bootstrap_action {
    name = "Configure Fair Scheduler"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/download-fair-scheduler-config.sh"
  }

  bootstrap_action {
    name = "Add Etleap-provided JARs"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/add-app-provided-libs.sh"
  }

  bootstrap_action {
    name = "Replace the Java keystore with Etleap's"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/install-etleap-keystore.sh"
  }

  bootstrap_action {
    name = "Install Kinesis Agent"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/install-kinesis-agent.sh"
    args = [var.deployment_id, local.app_main_private_ip, "false"]
  }

  bootstrap_action {
    name = "Set TCP keepalive"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/set-tcp-keepalive.sh"
  }

  bootstrap_action {
    name = "Copy HDFS init script"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/copy-hdfs-init.sh"
  }

  bootstrap_action {
    name = "Apply EMR hotfix for autoscaling bug"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/replace_hadoop_rpms.sh"
    args = ["etleap-emr-${local.region}"]
  }

  bootstrap_action {
    name = "Install HDFS crontab"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/install-hdfs-crontab.sh"
  }

  bootstrap_action {
    name = "Install DBT"
    path = "s3://etleap-emr-${local.region}/conf-hadoop2/install-dbt.sh"
  }

  step {
    action_on_failure = "CANCEL_AND_WAIT"
    name = "Initialize HDFS"
    hadoop_jar_step {
      jar = "command-runner.jar"
      args = ["bash", "/hdfs-init.sh"]
    }
  }

  step {
    action_on_failure = "CANCEL_AND_WAIT"
    name = "Install Flink History Server"
    hadoop_jar_step {
      jar = "s3://${local.region}.elasticmapreduce/libs/script-runner/script-runner.jar"
      args = ["s3://etleap-emr-${local.region}/conf-hadoop2/install-flink-historyserver.sh"]
    }
  }

  configurations_json = <<EOF
  [
    {
      "Classification": "hadoop-env",
      "Properties": {
      },
      "Configurations": [{
        "Classification": "export",
        "Properties": {
          "HADOOP_USER_CLASSPATH_FIRST": "true"
        }
      }]
    },
    {
      "Classification": "yarn-site",
      "Properties": {
        "yarn.resourcemanager.scheduler.class": "org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler",
        "yarn.scheduler.fair.preemption": "${var.enable_emr_preemption ? "true" : "false"}",
        "yarn.log-aggregation-enable": "true",
        "yarn.log-aggregation.retain-seconds": "7200",
        "yarn.nodemanager.remote-app-log-dir": "/log",
        "yarn.node-labels.am.default-node-label-expression": "CORE_OR_TASK",
        "yarn.nodemanager.node-labels.provider": "config",
        "yarn.nodemanager.node-labels.provider.configured-node-partition": "CORE_OR_TASK",
        "yarn.system-metrics-publisher.enabled": "false",
        "yarn.timeline-service.enabled": "false",
        "yarn.nodemanager.local-dirs": "/mnt/yarn",
        "yarn.resourcemanager.nodemanager-graceful-decommission-timeout-secs": "-1"
      }
    },
    {
      "Classification": "yarn-env",
      "Properties": {
      },
      "Configurations": [
        {
          "Classification": "export",
          "Properties": {
            "YARN_RESOURCEMANAGER_OPTS": "\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=8001 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/mnt/tmp\"",
            "YARN_RESOURCEMANAGER_HEAPSIZE": "4832"
          }
        }
      ]
    },
    {
      "Classification": "capacity-scheduler",
      "Properties": {
        "yarn.scheduler.capacity.root.accessible-node-labels.CORE.capacity": "0",
        "yarn.scheduler.capacity.root.accessible-node-labels.CORE_OR_TASK.capacity": "100",
        "yarn.scheduler.capacity.root.default.accessible-node-labels.CORE.capacity": "0",
        "yarn.scheduler.capacity.root.default.accessible-node-labels.CORE_OR_TASK.capacity": "100"
      }
    },
    {
      "Classification": "core-site",
      "Properties": {
        "fs.s3.buffer.dir": "/mnt/s3"
      }
    },
    {
      "Classification": "hdfs-site",
      "Properties": {
        "dfs.datanode.data.dir": "file:///mnt1/hdfs",
        "dfs.namenode.name.dir": "file:///mnt/namenode",
        "dfs.namenode.num.extra.edits.retained": "100000",
        "dfs.namenode.max.extra.edits.segments.retained": "1000"
      }
    },
    {
      "Classification": "mapred-site",
      "Properties": {
        "mapreduce.job.counters.limit": "512",
        "mapreduce.client.submit.file.replication": "2",
        "mapreduce.job.counters.counter.name.max": "255",
        "mapred.local.dir": "/mnt/mapred"
      }
    },
    {
      "Classification": "emrfs-site",
      "Properties": {
        "fs.s3.enableServerSideEncryption": "true"
      }
    },
    {
      "Classification": "spark-defaults",
      "Properties": {
        "spark.history.fs.cleaner.enabled": "true",
        "spark.history.fs.cleaner.interval": "1h",
        "spark.history.fs.cleaner.maxAge": "3h"
      }
    },
    {
      "Classification": "container-log4j",
      "Properties": {
        "log4j.threshold": "WARN"
      }
    }
  ]
EOF

}

resource "aws_emr_instance_fleet" "task_spot_xlarge" {
  count = var.emr_instance_fleet_smallest_instance_size == "xlarge" ? 1 : 0
  cluster_id           = aws_emr_cluster.emr.id
  name                 = "TASK SPOT"
  target_spot_capacity = 2

  lifecycle {
    ignore_changes = [
      target_spot_capacity,
      launch_specifications[0].spot_specification["allocation_strategy"] // Workaround for bug: https://github.com/hashicorp/terraform-provider-aws/issues/34151
    ]
  }

  launch_specifications {
    spot_specification {
      allocation_strategy      = "price-capacity-optimized"
      timeout_action           = "SWITCH_TO_ON_DEMAND"
      timeout_duration_minutes = 30
    }
  }

  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 96
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m6i.xlarge"
    weighted_capacity = 3
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 224
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m6i.2xlarge"
    weighted_capacity = 7
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m6i.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5.xlarge"
    weighted_capacity = 4
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 256
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5.2xlarge"
    weighted_capacity = 8
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5a.xlarge"
    weighted_capacity = 4
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 256
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5a.2xlarge"
    weighted_capacity = 8
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5a.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 224
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c6i.4xlarge"
    weighted_capacity = 7
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 64
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5.xlarge"
    weighted_capacity = 2
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5.2xlarge"
    weighted_capacity = 4
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 256
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5.4xlarge"
    weighted_capacity = 8
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 224
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5a.4xlarge"
    weighted_capacity = 7
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "r6i.xlarge"
    weighted_capacity = 4
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "r5.xlarge"
    weighted_capacity = 4
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 128
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "r5a.xlarge"
    weighted_capacity = 4
  }
}

moved {
  from = aws_emr_instance_fleet.task_spot
  to   = aws_emr_instance_fleet.task_spot_xlarge[0]
}

resource "aws_emr_instance_fleet" "task_spot_4xlarge" {
  count = var.emr_instance_fleet_smallest_instance_size == "4xlarge" ? 1 : 0
  cluster_id           = aws_emr_cluster.emr.id
  name                 = "TASK SPOT"
  target_spot_capacity = 2

  lifecycle {
    ignore_changes = [
      target_spot_capacity,
      launch_specifications[0].spot_specification["allocation_strategy"] // Workaround for bug: https://github.com/hashicorp/terraform-provider-aws/issues/34151
    ]
  }

  launch_specifications {
    spot_specification {
      allocation_strategy      = "price-capacity-optimized"
      timeout_action           = "SWITCH_TO_ON_DEMAND"
      timeout_duration_minutes = 30
    }
  }

  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m6i.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 512
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m5a.4xlarge"
    weighted_capacity = 16
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 224
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c6i.4xlarge"
    weighted_capacity = 7
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 256
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5.4xlarge"
    weighted_capacity = 8
  }
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 224
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "c5a.4xlarge"
    weighted_capacity = 7
  }
}

resource "aws_security_group" "emr" {
  tags        = merge({ Name = "Etleap EMR" }, local.default_tags)
  name        = "Etleap EMR"
  description = "Etleap EMR Security Group"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "emr-ingress-app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.app-to-emr
  to   = aws_security_group_rule.emr-ingress-app
}

resource "aws_security_group_rule" "emr-egress-app" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "emr-ingress-emr" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.emr.id
}

moved {
  from = aws_security_group_rule.emr-to-emr
  to   = aws_security_group_rule.emr-ingress-emr
}

resource "aws_security_group_rule" "emr-egress-emr" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.emr.id
}

resource "aws_security_group_rule" "emr-egress-8086-influxdb" {
  count                    = var.is_influx_db_in_secondary_region ? 0 : 1
  type                     = "egress"
  from_port                = 8086
  to_port                  = 8086
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.influxdb[0].id
}

resource "aws_security_group_rule" "emr-egress-2181-zookeeper" {
  type                     = "egress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.zookeeper.id
}

# Required to access apt and other install resources
resource "aws_security_group_rule" "emr-egress-80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.emr.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Required to access apt and other install resources and AWS APIs
resource "aws_security_group_rule" "emr-egress-443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.emr.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "emr-egress-external" {
  // the "for_each" argument must be a map, or set of strings; converting the list of maps 
  // to a single map with unique keys.
  // We can have multiple ports for the same cidr_block; to get around this, we use the list 
  // index as the key
  for_each                 = { for idx, c in var.outbound_access_destinations : idx => c }
  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.emr.id
  cidr_blocks              = contains(keys(each.value), "cidr_block") ? [each.value.cidr_block] : null
  source_security_group_id = lookup(each.value, "target_security_group_id", null)
}

# Managed by EMR
resource "aws_security_group" "emr-master-managed" {
  tags                   = merge({ Name = "Etleap EMR Master (managed by EMR)" }, local.default_tags)
  name                   = "EMR Master Managed"
  description            = "Rules managed by EMR for EMR master"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true
}

resource "aws_security_group" "emr-slave-managed" {
  tags                   = merge({ Name = "Etleap EMR Slave (managed by EMR)" }, local.default_tags)
  name                   = "EMR Slave Managed"
  description            = "Rules managed by EMR for EMR slave"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true
}

resource "aws_security_group" "emr-service-access-managed" {
  tags                   = merge({ Name = "Etleap EMR Service Access (managed by EMR)" }, local.default_tags)
  name                   = "EMR Service Access Managed"
  description            = "Rules managed by EMR for EMR service access"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "emr-service-access-managed-ingress-9443-emr-master-managed" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr-service-access-managed.id
  source_security_group_id = aws_security_group.emr-master-managed.id
}

moved {
  from = aws_security_group_rule.emr_master_service_access
  to   = aws_security_group_rule.emr-service-access-managed-ingress-9443-emr-master-managed
}

resource "aws_security_group_rule" "emr-service-master-managed-egress-9443-emr-access-managed" {
  type                     = "egress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr-master-managed.id
  source_security_group_id = aws_security_group.emr-service-access-managed.id
}

resource "aws_ssm_parameter" "emr_public_dns" {
  tags        = local.default_tags
  name        = local.context.emr_cluster_config_name
  description = "Etleap ${var.deployment_id} - EMR public DNS"
  type        = "String"
  value       = aws_emr_cluster.emr.master_public_dns
}

resource "aws_ssm_parameter" "emr_cluster_id" {
  tags        = local.default_tags
  name        = "${local.ssm_parameter_prefix}/emr_cluster_id"
  description = "The ID of the current active EMR cluster"
  type        = "String"
  value       = aws_emr_cluster.emr.id
}

data "aws_instance" "emr-master" {
  filter {
    name   = "network-interface.private-dns-name"
    values = [aws_emr_cluster.emr.master_public_dns]
  }
}
