#!/bin/bash
# Quick test request against Laya CUDA, Laya CPU, or TypeSafe Jev
# Usage:
#   ./test_request.sh        # Queries CUDA (default, port 8111)
#   ./test_request.sh cuda   # Queries CUDA
#   ./test_request.sh cpu    # Queries CPU (port 8112)
#   ./test_request.sh jev    # Queries Native TypeSafe Jev (api.typesafe.ai)

TARGET="${1:-cuda}"

if [ -f "docker-compose/.env" ]; then
  eval "$(grep -E '^(LAYA_PORT|LAYA_CPU_PORT|LAYA_API_KEY|TYPESAFE_API_KEY)=' docker-compose/.env)"
fi

case "$TARGET" in
  cpu)
    URL="http://localhost:${LAYA_CPU_PORT:-8112}/v1/systemone"
    API_KEY="${LAYA_API_KEY:-}"
    EXTRA_FIELDS=""
    echo ">> Querying Local Laya CPU (port ${LAYA_CPU_PORT:-8112})..."
    ;;
  jev)
    URL="https://api.typesafe.ai/v1/systemone"
    API_KEY="${TYPESAFE_API_KEY:-}"
    if [ -z "$API_KEY" ]; then
      echo "Error: TYPESAFE_API_KEY environment variable is not set."
      echo "Run: TYPESAFE_API_KEY='apikey_...' ./test_request.sh jev"
      exit 1
    fi
    EXTRA_FIELDS='"model": "jev-latest",'
    echo ">> Querying Native TypeSafe Jev Cloud (api.typesafe.ai)..."
    ;;
  cuda|*)
    URL="http://localhost:${LAYA_PORT:-8111}/v1/systemone"
    API_KEY="${LAYA_API_KEY:-}"
    EXTRA_FIELDS=""
    echo ">> Querying Local Laya CUDA (port ${LAYA_PORT:-8111})..."
    ;;
esac

AUTH_HEADER=()
if [ -n "$API_KEY" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${API_KEY}")
fi

cat << EOF | curl -s -X POST "$URL" \
  "${AUTH_HEADER[@]}" \
  -H "Content-Type: application/json" \
  -d @- | jq .
{
  "state": "The user encountered an error 500 when saving account settings.",
  ${EXTRA_FIELDS}
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
}
EOF
