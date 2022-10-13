version: '2'
services:
  zookeeper:
    image: 841591717599.dkr.ecr.us-east-1.amazonaws.com/zookeeper:${zookeeper_version}
    restart: always
    ports:
      - '2181:2181'
      - '2888:2888'
      - '3888:3888'
    volumes:
      - zookeeper_data:/tmp/zookeeper
      - /home/ubuntu/zookeeper-log4j.properties:/opt/zookeeper/conf/log4j.properties
    environment:
      SERVER_ID: ${zookeeper_id}
      SERVERS: %{ for id, addr in zookeeper_nodes ~}%{if tonumber(id) == tonumber(zookeeper_id)}server.${id}=0.0.0.0%{else}server.${id}=${addr}%{endif}:2888:3888,%{ endfor}
      JVMFLAGS: "-Xmx1G"
    logging:
      driver: "json-file"
      options:
        max-file: "1"
        max-size: "1024m"

volumes:
  zookeeper_data:
    driver: local
