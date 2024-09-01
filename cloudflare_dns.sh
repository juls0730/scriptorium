#!/bin/bash

cloudflare_api_key="" # Your api key
cloudflare_zone_id="" # Your domain zone ID

# Get the public IP address
public_ip=$(curl -s https://checkip.amazonaws.com)

# Set headers
auth_header="Authorization: Bearer $cloudflare_api_key"
content_type_header="Content-Type: application/json"

# Fetch DNS records
dns_records_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records" \
  -H "$content_type_header" \
  -H "$auth_header")

# Check if the response is successful
if [[ $(echo "$dns_records_response" | jq -r '.success') != "true" ]]; then
  echo "Failed to fetch DNS records."
  exit 1
fi

# Extract A record IDs and names
dns_records_ids=($(echo "$dns_records_response" | jq -r '.result[] | select(.type == "A") | .id'))
dns_records_names=($(echo "$dns_records_response" | jq -r '.result[] | select(.type == "A") | .name'))

# Update DNS records
for i in "${!dns_records_ids[@]}"; do
  record_id="${dns_records_ids[$i]}"
  record_name="${dns_records_names[$i]}"

  payload=$(jq -n --arg content "$public_ip" --arg name "$record_name" '{"type": "A", "content": $content, "name": $name}')

  update_response=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$cloudflare_zone_id/dns_records/$record_id" \
    -H "$content_type_header" \
    -H "$auth_header" \
    --data "$payload")

  if [[ $(echo "$update_response" | jq -r '.success') != "true" ]]; then
    echo "Failed to update DNS record $record_name."
    exit 1
  fi

  echo "Changed IP on record $record_name"
done
