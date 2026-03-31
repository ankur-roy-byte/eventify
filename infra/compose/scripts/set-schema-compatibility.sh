#!/usr/bin/env bash
set -euo pipefail

SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"

curl -sS -X PUT "${SCHEMA_REGISTRY_URL}/config" \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"compatibility":"BACKWARD"}'

echo
echo "Global schema compatibility set to BACKWARD"
