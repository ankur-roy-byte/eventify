#!/usr/bin/env bash
set -euo pipefail

SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL:-http://localhost:8081}"

register_schema() {
  local subject="$1"
  local schema_file="$2"

  local schema_json
  schema_json=$(jq -Rs . < "${schema_file}")

  curl -sS -X POST "${SCHEMA_REGISTRY_URL}/subjects/${subject}/versions" \
    -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    -d "{\"schema\":${schema_json}}" >/dev/null

  echo "Registered ${subject} from ${schema_file}"
}

register_schema "orders.v1.events-value" "schemas/avro/OrderCreated.avsc"
register_schema "payments.v1.events-value" "schemas/avro/PaymentAuthorized.avsc"
register_schema "inventory.v1.events-value" "schemas/avro/InventoryReserved.avsc"
register_schema "orders.v1.status-value" "schemas/avro/OrderStatus.avsc"
register_schema "risk.v1.fraud_alerts-value" "schemas/avro/PaymentRequested.avsc"
register_schema "web.v1.clickstream-value" "schemas/avro/ClickstreamEvent.avsc"

echo "Schema registration complete."
