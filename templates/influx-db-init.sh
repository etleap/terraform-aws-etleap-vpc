# Script to automatically generate an InfluxDB API token given the InfluxDB instance hostname, username, and password

INFLUX_HOSTNAME=$1
INFLUX_USERNAME=$2
INFLUX_PASSWORD=$3
API_TOKEN_SECRET_ARN=$4

# Attempt to retrieve the existing API token
EXISTING_API_TOKEN=$(aws secretsmanager get-secret-value --secret-id $API_TOKEN_SECRET_ARN 2>/dev/null | jq -r .SecretString)

# Check if the API token was successfully retrieved
if [ $? -eq 0 ] && [ -n "$EXISTING_API_TOKEN" ]; then
    exit 0
fi

# Obtain session cookie to make API requests without API token
SESSION_COOKIE=$(curl -s -S -k -i -X POST "https://$INFLUX_HOSTNAME:8086/api/v2/signin" --user "$INFLUX_USERNAME":"$INFLUX_PASSWORD" \
                | grep 'set-cookie: influxdb-oss-session' \
                | awk '{print $2}' | tr -d ';')

# Obtain organization id since this is required to generate an API token
ORG_ID=$(curl -s -S -k -X GET "https://$INFLUX_HOSTNAME:8086/api/v2/orgs" -H "Cookie: $SESSION_COOKIE" | jq -r '.orgs[0].id')

# Generate API token
TOKEN_GENERATION_RESPONSE=$(curl -s -S -k -X POST "https://$INFLUX_HOSTNAME:8086/api/v2/authorizations" \
  --cookie "$SESSION_COOKIE" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Read/Write Buckets API Token",
    "orgID": "'"$ORG_ID"'",
    "permissions": [
      {
        "action": "read",
        "resource": {
          "type": "buckets"
        }
      },
      {
        "action": "write",
        "resource": {
          "type": "buckets"
        }
      }
    ]
  }')

# Extract and output API token from response
echo "$TOKEN_GENERATION_RESPONSE" | jq -r '.token'
aws secretsmanager put-secret-value --secret-id $API_TOKEN_SECRET_ARN --secret-string $(echo "$TOKEN_GENERATION_RESPONSE" | jq -r '.token')