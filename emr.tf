resource "aws_emr_cluster" "emr" {
  depends_on = [
    aws_instance.nat
  ]
  name                              = "Etleap EMR"
  release_label                     = "emr-5.20.0"
  applications                      = ["Hadoop", "Spark"]
  keep_job_flow_alive_when_no_steps = true
  service_role                      = aws_iam_role.emr_default_role.name
  autoscaling_role                  = aws_iam_role.emr_autoscaling_default_role.name

  ec2_attributes {
    key_name                          = var.key_name
    subnet_id                         = aws_subnet.b_private.id
    emr_managed_master_security_group = aws_security_group.emr-master-managed.id
    emr_managed_slave_security_group  = aws_security_group.emr-slave-managed.id
    service_access_security_group     = aws_security_group.emr-service-access-managed.id
    additional_master_security_groups = aws_security_group.internal.id
    additional_slave_security_groups  = aws_security_group.internal.id
    instance_profile                  = aws_iam_instance_profile.emr_profile.name
  }

  tags = {
    Name = "Etleap EMR"
  }

  master_instance_group {
    instance_type = "m5.xlarge"
    ebs_config {
      size                 = "128"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    name           = "CORE"
    instance_type  = "c5.xlarge"
    instance_count = "1"

    # /mnt
    ebs_config {
      size                 = "64"
      type                 = "gp2"
      volumes_per_instance = 1
    }

    # /mnt1
    ebs_config {
      size                 = "512"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  bootstrap_action {
    name = "Configure Fair Scheduler"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/download-fair-scheduler-config.sh"
  }

  bootstrap_action {
    name = "Add Etleap-provided JARs"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/add-app-provided-libs.sh"
  }

  bootstrap_action {
    name = "Replace the Java keystore with Etleap's"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/install-etleap-keystore.sh"
  }

  bootstrap_action {
    name = "Install Kinesis Agent"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/install-kinesis-agent.sh"
    args = [var.deployment_id, element(tolist(aws_network_interface.main_app.private_ips[*]), 0), "false"]
  }

  bootstrap_action {
    name = "Set TCP keepalive"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/set-tcp-keepalive.sh"
  }

  bootstrap_action {
    name = "Copy HDFS init script"
    path = "s3://etleap-emr-${var.region}/conf-hadoop2/copy-hdfs-init.sh"
  }

  step {
    action_on_failure = "CANCEL_AND_WAIT"
    name = "Initialize HDFS"
    hadoop_jar_step {
      jar = "command-runner.jar"
      args = ["bash", "/hdfs-init.sh"]
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
        "yarn.scheduler.fair.preemption": "true",
        "yarn.log-aggregation-enable": "true",
        "yarn.log-aggregation.retain-seconds": "7200",
        "yarn.nodemanager.remote-app-log-dir": "/log",
        "yarn.node-labels.am.default-node-label-expression": "CORE_OR_TASK",
        "yarn.nodemanager.node-labels.provider": "config",
        "yarn.nodemanager.node-labels.provider.configured-node-partition": "CORE_OR_TASK",
        "yarn.nodemanager.local-dirs": "/mnt/yarn"
      }
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
        "dfs.namenode.name.dir": "file:///mnt/namenode"
      }
    },
    {
      "Classification": "mapred-site",
      "Properties": {
        "mapreduce.job.counters.limit": "512",
        "mapreduce.client.submit.file.replication": "2",
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
    }
  ]
EOF

}

resource "aws_emr_instance_group" "task_spot" {
  cluster_id     = aws_emr_cluster.emr.id
  name           = "TASK SPOT"
  instance_type  = "c5.xlarge"
  instance_count = "1"
  ebs_config {
    size                 = "64"
    type                 = "gp2"
    volumes_per_instance = 1
  }
  bid_price          = "0.21"
  lifecycle { 
    ignore_changes = [
      instance_count
    ]  
  }
  autoscaling_policy = <<EOF
{
  "Constraints": {
    "MinCapacity": 1,
    "MaxCapacity": 100
  },
  "Rules": [
    {
      "Name": "ScaleOutOnContainersPendingRatio",
      "Description": "Scale out if ContainerPendingRatio is more than 1",
      "Action": {
        "SimpleScalingPolicyConfiguration": {
          "AdjustmentType": "CHANGE_IN_CAPACITY",
          "ScalingAdjustment": 1,
          "CoolDown": 300
        }
      },
      "Trigger": {
        "CloudWatchAlarmDefinition": {
          "ComparisonOperator": "GREATER_THAN",
          "EvaluationPeriods": 1,
          "MetricName": "ContainerPendingRatio",
          "Namespace": "AWS/ElasticMapReduce",
          "Period": 300,
          "Statistic": "AVERAGE",
          "Threshold": 1.0,
          "Unit": "COUNT"
        }
      }
    },
    {
      "Name": "ScaleInOnContainersPendingRatio",
      "Description": "Scale in if ContainerPendingRatio is less than 0.5",
      "Action": {
        "SimpleScalingPolicyConfiguration": {
          "AdjustmentType": "CHANGE_IN_CAPACITY",
          "ScalingAdjustment": -1,
          "CoolDown": 300
        }
      },
      "Trigger": {
        "CloudWatchAlarmDefinition": {
          "ComparisonOperator": "LESS_THAN",
          "EvaluationPeriods": 1,
          "MetricName": "ContainerPendingRatio",
          "Namespace": "AWS/ElasticMapReduce",
          "Period": 300,
          "Statistic": "AVERAGE",
          "Threshold": 0.5,
          "Unit": "COUNT"
        }
      }
    }
  ]
}
EOF

}
