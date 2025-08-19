#!/bin/sh

# Waiting for PowerDNS container start
echo "Czekam na uruchomienie PowerDNS Authoritative i PowerDNS Admin..."
sleep 20

# variable for zone creation
ZONE_NAME="in.mailx.com.pl"
PDNS_API_URL="http://pdns-authoritative:8081"
PDNS_API_KEY=`cat .env | grep SECRET_KEY | awk -f "=" '{print $2}' | tr -d "'"`

declare -A RECORDS
RECORDS+=(
  ["dns1"]="172.16.8.250"
  ["dns2"]="172.16.8.251"
  ["powerdns"]="172.16.8.254"
)

echo "Tworzenie strefy $ZONE_NAME..."

for key in ${RECORDS[@]}; do
  if [ $key == "dns1" ] || [ $key == "dns2" ]; then
    curl -X POST \
      -H "X-API-Key: $PDNS_API_KEY" \
      -H "Content-Type: application/json" \
      --data-binary "{
        \"name\": \"$ZONE_NAME.\",
        \"kind\": \"Native\",
        \"masters\": [],
        \"nameservers\": [\"$key.$ZONE_NAME\"]
      }" \
      $PDNS_API_URL/api/v1/servers/localhost/zones
  fi
done

echo "Strefa została utworzona. Dodawanie rekordów..."

# Update A records
for key in ${!RECORDS[@]}; do
  curl -X PATCH \
    -H "X-API-Key: $PDNS_API_KEY" \
    -H "Content-Type: application/json" \
    --data-binary "{
      \"rrsets\": [
      {
        # for A records
        \"name\": \"$ZONE_NAME.\",
        \"type\": \"A\",
        \"ttl\": 3600,
        \"records\": [
          { \"content\": \"$key.$ZONE_NAME.\" }
        ]
      },
      ]
    }"
    $PDNS_API_URL/api/v1/servers/localhost/zones/$ZONE_NAME.
done

# Update of NS records
for key in ${!RECORDS[@]}; do
  if [ $key == "dns1" ] || [ $key == "dns2" ]; then
    curl -X PATCH \
      -H "X-API-Key: $PDNS_API_KEY" \
      -H "Content-Type: application/json" \
      --data-binary "{
        \"rrsets\": [
        {
          # for NS records
          \"name\": \"$ZONE_NAME.\",
          \"type\": \"A\",
          \"ttl\": 3600,
          \"records\": [
            { \"content\": \"$key.$ZONE_NAME.\" }
          ]
        },
        ]
      }"
      $PDNS_API_URL/api/v1/servers/localhost/zones/$ZONE_NAME.
  fi
done