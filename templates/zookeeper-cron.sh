#!/bin/bash

set -o xtrace
set -o errexit
set -o pipefail

# Load .env
source /home/ubuntu/.etleap
deploymentId=$ETLEAP_DEPLOYMENT_ID
secretKey=$ETLEAP_SECRET_APPLICATION_SECRET

# Pull an ECR authentication token and store it locally
printf "[ZOOKEEPER_CRON] Starting docker-compose"
export AWS_DEFAULT_REGION=us-east-1
BEARER=$(echo -n "$ETLEAP_DEPLOYMENT_ID:$ETLEAP_SECRET_APPLICATION_SECRET" | openssl base64 -A)
EC2_IDENTITY_DOCUMENT=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | openssl base64 -A)
curl \
   --header "Authorization: Basic $BEARER" \
   --header "Ec2Metadata: $EC2_IDENTITY_DOCUMENT" \
   --header "Accept-Encoding: gzip" \
   -s -L -f --compressed -o "/home/ubuntu/.deployScript" \
   https://deployment.etleap.com/deployment/v1/deploy.py

ECR_AUTH_TOKEN_JSON=$(grep -A7 "docker_config.write" /home/ubuntu/.deployScript | sed -n '2,7p')

mkdir -p /home/ubuntu/.docker
echo "{$ECR_AUTH_TOKEN_JSON" > /home/ubuntu/.docker/config.json

# Start docker-compose
printf "[ZOOKEEPER_CRON] Starting docker-compose"
docker-compose -f /home/ubuntu/docker-compose.yml up -d

# Clean up unused images
docker rmi $(docker images -q --filter "dangling=true") > /dev/null || true

# Logging setup
printf "[ZOOKEEPER_CRON] Logging setup"
function should_enable_logging_agent {
  SEND_LOGS=`docker exec zookeeper_zookeeper_1 bin/zkCli.sh get /deployment/enableLogsAndMetrics 2> /dev/null | tail -n 1`
  if [ "$SEND_LOGS" == "true" ]; then
    # Log and Metric reporting is enabled in Zookeeper
    return 0
  elif [ "$SEND_LOGS" == "false" ]; then
    # Log and Metric reporting is disabled in Zookeeper
    return 1
  elif [ "$MARKETPLACE_DEPLOYMENT" == "true" ]; then
    # Log and Metric reporting hasn't been set in Zookeeper, but this is a Marketplace deployment so don't send logs by default
    return 1
  else
    # Log and Metric reporting hasn't been set in Zookeeper, and this is a Non-Marketplace deployment so send logs by default
    return 0
  fi
}

# Arguments:
#   $1 - The host name to add to log metadata
#   $2 - The deployment id to add to log metadata
function setup_logging {
  # Don't fail deployment if there is an error while setting up logs
  set +e

  if should_enable_logging_agent; then
    echo "Starting log delivery"
    cat /home/ubuntu/kinesis-agent-json-template.json \
      | sed "s/{STREAM}/log/g"\
      | sed "s/{HOST}/$1/g"\
      | sed "s/{DEPLOYMENT_ID}/$2/g"\
      | sudo tee /etc/aws-kinesis/agent.json\
    && sudo service aws-kinesis-agent start

  else
    echo "Stopping log delivery"
    sudo service aws-kinesis-agent stop
  fi

  if [[ $? != 0 ]]; then
    echo "Error while setting up logs. See previous log message."
  fi

  # Reactivate errexit flag
  set -e
}

if [ ! "$deploymentId" ]; then
  echo "Deployment ID not available in ETLEAP_DEPLOYMENT_ID environment variable."
  exit 1
fi

if [ ! "$secretKey" ]; then
  echo "Secret Key not available in ETLEAP_SECRET_APPLICATION_SECRET environment variable."
  exit 1
fi

if [ ! `command -v openssl` ]; then
  echo "Dependency not found: it's required to 'openssl' be available in your system"
  exit 2
fi

hostAddress="`curl --connect-timeout 3 -s http://169.254.169.254/latest/meta-data/local-ipv4`"

# Enable or disable Kinesis Logging Agent
setup_logging $HOSTNAME $deploymentId
