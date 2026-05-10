#!/bin/bash

# Configuration
TOKEN="hsc-update-token"
PORT="8080"
ENDPOINT="http://localhost:$PORT/v1/update"

echo "Sending update request to Watchtower..."
RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" -X POST "$ENDPOINT")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "[SUCCESS] Update check triggered."
else
    echo "[ERROR] Failed to trigger update. HTTP Status: $HTTP_STATUS"
    echo "Response: $BODY"
    exit 1
fi
