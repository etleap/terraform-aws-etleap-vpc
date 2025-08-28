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

  CGROUP="/sys/fs/cgroup/system.slice/docker-$ZK_CONTAINER_ID.scope"
  RSS=$(cat "$CGROUP/memory.current")
  SWAP=$(cat "$CGROUP/memory.swap.current")

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
