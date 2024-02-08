#!/bin/bash -e
export PATH=$PATH:/usr/local/bin:/usr/sbin

# Zookeeper zxid is a 64 bit number, where lower 32 bit represents the "count" (maximum 4294967295)
# Restart Zookeeper Leader if zxid count is over 3G (3000000000) to avoid int32 overflow and ZK cluster downtime

ZK_HOST="localhost"
for i in 1 2 3 4 5; do
  ZK_STAT=$(echo "srvr" | nc $ZK_HOST 2181)
  [ "$ZK_STAT" != "" ] && break
  echo "."; sleep 2
done
ZK_MODE=$(echo "$ZK_STAT" | grep -Eo "Mode: (.*)$" | sed -n -r 's/Mode: (.*)/\1/p')
ZXID_COUNT=$(echo "$ZK_STAT" | grep -i zxid | awk '{print $2}' | python3 -c 'zxid=int(input(),16);print(zxid & 0xFFFFFFFF)')
# Prevent ZK cluster from exceeding zxid count over 3G
# Restart leader to prevent this
echo "[ZOOKEEPER Zxid Check] Mode: $ZK_MODE ZxidCount: $ZXID_COUNT"
if [ "$ZK_MODE" = "leader" ] && [ "$ZXID_COUNT" -gt 3000000000 ];then
    echo "WARN: Node is leader and Zxid count exceedes 3G, restarting local ZK node"
    docker restart ubuntu_zookeeper_1
fi
