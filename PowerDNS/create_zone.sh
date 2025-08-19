#!/bin/sh

# Czekanie na uruchomienie usług
echo "Czekam na uruchomienie PowerDNS Authoritative i PowerDNS Admin..."
sleep 20

# Dane do utworzenia strefy
ZONE_NAME="in.mailx.com.pl"
PDNS_API_URL="http://pdns-authoritative:8081"
PDNS_API_KEY="QqyTpVc9y*8vFcaLUSUDZGTr"

echo "Tworzenie strefy $ZONE_NAME..."

curl -X POST \
  -H "X-API-Key: $PDNS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "{
    \"name\": \"$ZONE_NAME.\",
    \"kind\": \"Native\",
    \"masters\": [],
    \"nameservers\": [\"dns1.$ZONE_NAME.\"]
  }" \
  $PDNS_API_URL/api/v1/servers/localhost/zones

echo "Strefa została utworzona. Dodawanie rekordów..."

# Dane do utworzenia rekordu A
RECORD_NAME="dns1"
RECORD_TYPE="A"
RECORD_CONTENT="172.16.8.250"

curl -X PATCH \
  -H "X-API-Key: $PDNS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "{
    \"rrsets\": [
      {
        \"name\": \"$RECORD_NAME.$ZONE_NAME.\",
        \"type\": \"$RECORD_TYPE\",
        \"ttl\": 3600,
        \"records\": [
          {
            \"content\": \"$RECORD_CONTENT\"
          }
        ]
      }
    ]
  }" \
  $PDNS_API_URL/api/v1/servers/localhost/zones/$ZONE_NAME.