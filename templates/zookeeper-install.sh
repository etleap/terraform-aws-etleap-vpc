#!/bin/bash -e

# Docker, the AWS CLI, the Kinesis Agent and kernel live patching are all
# pre-baked into the Amazon Linux 2023 app AMI. Here we only install what is
# missing: the Docker Compose v2 plugin and netcat (used by the ZK health
# checks), then configure the Zookeeper-specific cron jobs and logging.
printf "[ZOOKEEPER_INIT] Starting instance init"

printf "[ZOOKEEPER_INIT] Installing Docker Compose plugin"
COMPOSE_VERSION="2.39.4"
PLUGIN_DIR=/usr/local/lib/docker/cli-plugins
sudo mkdir -p "$PLUGIN_DIR"
sudo curl -SL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64" -o "$PLUGIN_DIR/docker-compose"
sudo chmod +x "$PLUGIN_DIR/docker-compose"

printf "[ZOOKEEPER_INIT] Installing dependencies"
sudo dnf install nc -y

sudo gpasswd -a ec2-user docker

printf "[ZOOKEEPER_INIT] Restarting Docker"
sudo service docker stop
sudo service docker start

## Configure Monitoring and Cron Jobs
cat << EOF > /home/ec2-user/crontab.list
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SHELL=/bin/bash

#zookeeper-install.sh: Zookeeper Cloudwatch Monitoring
* * * * * /home/ec2-user/zookeeper-monitor.sh &> /home/ec2-user/logs/zk/zk-monitor.log.\`date +\%M\`

#zookeeper-install.sh: Log Zookeeper Stats
*/5 * * * * /home/ec2-user/zookeeper-stat.sh &> /home/ec2-user/logs/zk/zk-stat.log.\`date +\%M\`

#zookeeper-install.sh: ZooKeeper Cron
*/5 * * * * /home/ec2-user/zookeeper-cron.sh &> /home/ec2-user/logs/zk/zk-cron.log.\`date +\%M\`

#zookeeper-install.sh: Zookeeper Zxid overflow safeguard, every hour
1 * * * * /home/ec2-user/zookeeper-zxid-check.sh &> /home/ec2-user/logs/zk/zk-zxid-check.log.\`date +\%M\`

EOF

crontab -u ec2-user /home/ec2-user/crontab.list

# Logging Configuration
cat << EOF > /home/ec2-user/zookeeper-log4j.properties
# Define some default values that can be overridden by system properties
zookeeper.root.logger=WARN, CONSOLE
zookeeper.console.threshold=WARN
zookeeper.log.dir=.
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=DEBUG
zookeeper.tracelog.dir=.
zookeeper.tracelog.file=zookeeper_trace.log

# DEFAULT: console appender only
log4j.rootLogger=INFO, CONSOLE
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=INFO
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C@%L] - %m%n

log4j.logger.org.apache.zookeeper.server.NIOServerCnxn=ERROR
log4j.logger.org.apache.zookeeper.server.command=WARN
log4j.logger.org.apache.zookeeper.server.ContainerManager=WARN
EOF

chown ec2-user:ec2-user /home/ec2-user/zookeeper-log4j.properties

# Configure Kinesis Agent
cat <<"KINESIS_AGENT_JSON_TEMPLATE" > /home/ec2-user/kinesis-agent-json-template.json
{
    "checkpointFile": "/tmp/aws-kinesis-agent-checkpoints.log",
    "cloudwatch.emitMetrics": false,
    "kinesis.endpoint": "https://kinesis.us-east-1.amazonaws.com",
    "assumeRoleARN": "arn:aws:iam::841591717599:role/kinesis_producer",
    "flows": [
        {
            "filePattern": "/home/ec2-user/logs/zk/zk-stat.log.*",
            "kinesisStream": "{STREAM}",
            "maxBufferAgeMillis": 5000,
            "dataProcessingOptions": [
                {
                    "optionName": "ADDMETADATA",
                    "timestamp": "false",
                    "metadata": {
                        "host": "{HOST}",
                        "filepath": "/home/ec2-user/logs/zk/zk-stat.log",
                        "deploymentId": "{DEPLOYMENT_ID}",
                        "role": "customervpc",
                        "service": "zookeeper-stat"
                    }
                }
            ]
        },
        {
            "filePattern": "/home/ec2-user/logs/zk/zk-cron.log.*",
            "kinesisStream": "{STREAM}",
            "maxBufferAgeMillis": 5000,
            "dataProcessingOptions": [
                {
                    "optionName": "ADDMETADATA",
                    "timestamp": "false",
                    "metadata": {
                        "host": "{HOST}",
                        "filepath": "/home/ec2-user/logs/zk/zk-cron.log",
                        "deploymentId": "{DEPLOYMENT_ID}",
                        "role": "customervpc",
                        "service": "zookeeper-cron"
                    }
                }
            ]
        }
    ]
}
KINESIS_AGENT_JSON_TEMPLATE
