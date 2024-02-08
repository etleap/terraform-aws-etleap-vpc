#!/bin/bash -e

# Install Docker
printf "[ZOOKEEPER_INIT] Starting instance init"
[ -e /usr/lib/apt/methods/https ] || {
  printf "[ZOOKEEPER_INIT] Installing https transport"
  sudo apt-get update -q -y
  sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -q -y
}

printf "[ZOOKEEPER_INIT] Installing Docker, docker-compose"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y -u "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt-get update
printf "[ZOOKEEPER_INIT] Available docker-ce packages"
apt-cache policy docker-ce
printf "[ZOOKEEPER_INIT] Available docker-compose packages"
apt-cache policy docker-compose
cat /etc/apt/sources.list
sudo apt-get install docker-ce=5:24.0.7-1~ubuntu.20.04~focal docker-compose=1.25.0-1 -q -y --allow-downgrades

printf "[ZOOKEEPER_INIT] Installing pass gnupg2 awscli"
sudo apt-get install pass gnupg2 awscli -q -y

printf "{ \"userland-proxy\": false, \"dns\": [\"10.0.0.2\"] }" | sudo tee /etc/docker/daemon.json
sudo gpasswd -a ubuntu docker

printf "[ZOOKEEPER_INIT] Reinstall docker-py"
pip uninstall -y docker-py; pip uninstall -y docker; pip install docker

printf "[ZOOKEEPER_INIT] Restarting Docker"
sudo service docker stop
sudo service docker start

## Configure Monitoring and Cron Jobs
cat << EOF > /home/ubuntu/crontab.list
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
SHELL=/bin/bash

#zookeeper-install.sh: Zookeeper Cloudwatch Monitoring
* * * * * /home/ubuntu/zookeeper-monitor.sh &> /home/ubuntu/logs/zk/zk-monitor.log.\`date +\%M\`

#zookeeper-install.sh: Log Zookeeper Stats
*/5 * * * * /home/ubuntu/zookeeper-stat.sh &> /home/ubuntu/logs/zk/zk-stat.log.\`date +\%M\`

#zookeeper-install.sh: ZooKeeper Cron
*/5 * * * * /home/ubuntu/zookeeper-cron.sh &> /home/ubuntu/logs/zk/zk-cron.log.\`date +\%M\`

#zookeeper-install.sh: Zookeeper Zxid overflow safeguard, every hour
1 * * * * /home/ubuntu/zookeeper-zxid-check.sh &> /home/ubuntu/logs/zk/zk-zxid-check.log.\`date +\%M\`

EOF

crontab -u ubuntu /home/ubuntu/crontab.list

# Logging Configuration
cat << EOF > /home/ubuntu/zookeeper-log4j.properties
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

chown ubuntu:ubuntu /home/ubuntu/zookeeper-log4j.properties

# Configure Kinesis Agent
cat <<"KINESIS_AGENT_JSON_TEMPLATE" > /home/ubuntu/kinesis-agent-json-template.json
{
    "checkpointFile": "/tmp/aws-kinesis-agent-checkpoints.log",
    "cloudwatch.emitMetrics": false,
    "kinesis.endpoint": "https://kinesis.us-east-1.amazonaws.com",
    "assumeRoleARN": "arn:aws:iam::841591717599:role/kinesis_producer",
    "flows": [
        {
            "filePattern": "/home/ubuntu/logs/zk/zk-stat.log.*",
            "kinesisStream": "{STREAM}",
            "maxBufferAgeMillis": 5000,
            "dataProcessingOptions": [
                {
                    "optionName": "ADDMETADATA",
                    "timestamp": "false",
                    "metadata": {
                        "host": "{HOST}",
                        "filepath": "/home/ubuntu/logs/zk/zk-stat.log",
                        "deploymentId": "{DEPLOYMENT_ID}",
                        "role": "customervpc",
                        "service": "zookeeper-stat"
                    }
                }
            ]
        },
        {
            "filePattern": "/home/ubuntu/logs/zk/zk-cron.log.*",
            "kinesisStream": "{STREAM}",
            "maxBufferAgeMillis": 5000,
            "dataProcessingOptions": [
                {
                    "optionName": "ADDMETADATA",
                    "timestamp": "false",
                    "metadata": {
                        "host": "{HOST}",
                        "filepath": "/home/ubuntu/logs/zk/zk-cron.log",
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
