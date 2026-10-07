#!/bin/bash
# Quick test request against Laya server

PORT="${LAYA_PORT:-8000}"
API_KEY="${LAYA_API_KEY:-}"

AUTH_HEADER=()
if [ -n "$API_KEY" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${API_KEY}")
fi

curl -s -X POST "http://localhost:${PORT}/v1/systemone" \
  "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d '{
    "state": "The user encountered an error 500 when saving account settings.",
    "questions": {
      "category": {
        "type": "choice",
        "instructions": "Classify the problem",
        "criteria": {
          "server_error": "500, crash, unhandled exception",
          "user_error": "invalid form input, bad password",
          "feature_request": "new functionality desired"
        }
      }
    }
  }' | jq .
