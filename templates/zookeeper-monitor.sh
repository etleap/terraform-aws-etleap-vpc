#!/bin/bash -e
# Reports outstanding requests, avg latency, RSS and swap usage for running ZooKeeper container
export AWS_DEFAULT_REGION=us-east-1

# Zookeeper might catch more than 1 security group, so let's fetch the first one
IMDS_TOKEN=$(curl -X PUT "http://instance-data/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
SECURITY_GROUP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/security-groups | grep 'app\|monitor\|job\|customervpc\|zookeeper' | head -n1)
ZK_HOST="localhost"
RETRIES=5

# Identify Zookeeper container
INSTANCE_NAME=$(cat /etc/hostname)
ZK_CONTAINER_ID_AND_NAME=`docker ps | tail -n +2 | sed 's/\([^ ]\+\).* \([^ ]\+\)$/\1,\2/' | grep zookeeper`
ZK_CONTAINER_ID=`echo $ZK_CONTAINER_ID_AND_NAME | cut -d, -f1`
# Get full-length container ID
ZK_CONTAINER_ID=`docker ps -q --no-trunc | grep "$ZK_CONTAINER_ID"`

check_zk_running() {
  n=0
  while [[ $n -le $RETRIES &&  -z "$IMOK" ]]
  do
    sleep 3; n=$[$n+1];
    IMOK=`echo ruok | nc "$ZK_HOST" 2181`
  done

  if [[ "$IMOK" == "imok" ]]; then
    RUOK="1"
  else
    RUOK="0"
  fi

  echo "[ZooKeeperMonitor] $INSTANCE_NAME: Etleap/ZooKeeper Ruok IMOK=$IMOK RUOK=$RUOK"

  aws cloudwatch put-metric-data \
    --namespace "Etleap/ZooKeeper" \
    --metric-data "[
      {\"MetricName\":\"Ruok\",\"Value\":$RUOK,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]}
    ]"

  if [[ -z "$IMOK" ]]; then
    echo "ZooKeeper node '$INSTANCE_NAME-$SECURITY_GROUP' is down"
    exit 1
  fi
}

submit_memory_usage() {
  CGROUP="/sys/fs/cgroup/system.slice/docker-$ZK_CONTAINER_ID.scope"
  RSS=$(cat "$CGROUP/memory.current")
  SWAP=$(cat "$CGROUP/memory.swap.current")

  echo "[ZooKeeperMonitor] $INSTANCE_NAME: Etleap/ZooKeeper RSS $RSS"

  aws cloudwatch put-metric-data \
    --namespace "Etleap/ZooKeeper" \
    --metric-data "[
      {\"MetricName\":\"RSS\",\"Value\":$RSS,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]}
    ]"

  if [[ ! -z "$SWAP" ]]; then
    echo "[ZooKeeperMonitor] $INSTANCE_NAME: Etleap/ZooKeeper Swap $SWAP"
    aws cloudwatch put-metric-data \
      --namespace "Etleap/ZooKeeper" \
      --metric-data "[
        {\"MetricName\":\"Swap\",\"Value\":$SWAP,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]}
      ]"
  fi
}

submit_zk_stats() {
  STAT=`echo stat | nc "$ZK_HOST" 2181`
  n=0
  while [[ $n -le $RETRIES &&  -z "$STAT" ]]
  do
    sleep 3; n=$[$n+1];
    STAT=`echo stat | nc "$ZK_HOST" 2181`
  done

  if [[ -z "$STAT" ]]; then
    echo "Couldn't get stats from ZooKeeper node '$SECURITY_GROUP'"
    exit 2
  fi

  MODE=`echo "$STAT" | grep -Eo "Mode: (.*)$" | sed -n -r 's/Mode: (.*)/\1/p'`
  OUTSTANDING=`echo "$STAT"  | grep -Eo "Outstanding: (.*)$" | sed -n -r 's/Outstanding: (.*)/\1/p'`
  AVG_LATENCY=`echo "$STAT"  | grep -Eo "Latency min/avg/max: (.*)$" | sed -n -r 's/Latency min\/avg\/max: (.*)/\1/p' | cut -d'/' -f2`

  if [[ "$MODE" == "leader" ]]; then
    LEADER="1"
  else
    LEADER="0"
  fi

  echo "[ZooKeeperMonitor] $INSTANCE_NAME: Etleap/ZooKeeper Leader $LEADER"
  aws cloudwatch put-metric-data \
    --namespace "Etleap/ZooKeeper" \
    --metric-data "[
      {\"MetricName\":\"OutstandingRequests\",\"Value\":$OUTSTANDING,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]},
      {\"MetricName\":\"AvgLatency\",\"Value\":$AVG_LATENCY,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]},
      {\"MetricName\":\"Leader\",\"Value\":$LEADER,\"Dimensions\":[{\"Name\":\"Instance\",\"Value\":\"$INSTANCE_NAME\"},{\"Name\":\"Node\",\"Value\":\"$SECURITY_GROUP\"}]}
    ]"
}

# MAIN
# Check if ZooKeeper node is running and put its stats to CloudWatch
echo "[ZooKeeperMonitor] Checking status of ZooKeeper node '$INSTANCE_NAME' at $ZK_HOST"

# Always submit zookeeper container memory usage
submit_memory_usage
check_zk_running
submit_zk_stats
