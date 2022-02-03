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
apt-cache policy docker-ce
cat /etc/apt/sources.list
sudo apt-get install docker-ce docker-compose -q -y

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
log4j.rootLogger=WARN, CONSOLE

log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=WARN
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
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

# Install ZK Stats Script
cat <<"ZOOKEEPERSTAT" > /home/ubuntu/zookeeper-stat.sh
#!/bin/bash

ZK_CONTAINER="zookeeper"
ZK_HOST="localhost"
ZK_PORT=2181
RETRIES=5

function zk_cmd() {
  n=0
  RESULT=`echo "$1" | nc $ZK_HOST $ZK_PORT`
  while [[ $n -le $RETRIES && -z "$RESULT" ]]
  do
    sleep 3; n=$[$n+1];
    RESULT=`echo "$1" | nc $ZK_HOST $ZK_PORT`
  done

  if [[ ! -z "$RESULT" ]]; then
    echo "$RESULT"
  fi
}


check_zk_running() {
  if [[ -z `zk_cmd ruok` ]]; then
    echo "ZooKeeper node is down"
    exit 1
  else
    echo "Zookeeper node is up"
  fi
}

zk_stats() {
  STAT=`zk_cmd stat`
  if [[ -z "$STAT" ]]; then
    echo "Couldn't get stats from ZooKeeper node"
    exit 2
  else
    echo "$STAT"
  fi
}

memory_usage() {
  ZK_CONTAINER_ID_AND_NAME=`docker ps | tail -n +2 | sed 's/\([^ ]\+\).* \([^ ]\+\)$/\1,\2/' | grep zookeeper`
  ZK_CONTAINER_ID=`echo $ZK_CONTAINER_ID_AND_NAME | cut -d, -f1`
  # Get full-length container ID
  ZK_CONTAINER_ID=`docker ps -q --no-trunc | grep "$ZK_CONTAINER_ID"`
  ZK_CONTAINER_NAME=`echo $ZK_CONTAINER_ID_AND_NAME | cut -d, -f2`

  RSS=`cat /sys/fs/cgroup/memory/docker/$ZK_CONTAINER_ID/memory.stat | grep -Eo "^rss (.*)$" | sed -n -r 's/rss (.*)/\1/p'`
  SWAP=`cat /sys/fs/cgroup/memory/docker/$ZK_CONTAINER_ID/memory.stat | grep -Eo "^swap (.*)$" | sed -n -r 's/swap (.*)/\1/p'`

  echo    "RSS:  $RSS"
  echo -n "SWAP: "
  if [[ ! -z "$SWAP" ]]; then
    echo -e "$SWAP\n"
  else
    echo -e "No swap memory data found for Zookeeper node\n"
  fi
}

function docker_stats() {
  docker stats --no-stream $ZK_CONTAINER
}

if [ -n "`docker ps -q -f name="$ZK_CONTAINER"`" ]; then
  echo -e "`check_zk_running`\n"
  echo -e "`zk_stats`\n"
  echo -e "Memory Usage:\n`memory_usage`\n"
  echo -e "Docker Stats:\n`docker_stats`\n"
fi
ZOOKEEPERSTAT

chmod +x /home/ubuntu/zookeeper-stat.sh
