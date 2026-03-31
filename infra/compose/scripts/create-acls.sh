#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-infra/compose/docker-compose.yml}"
compose_cmd=(docker compose -f "${COMPOSE_FILE}")

# Example ACLs for SCRAM principals in Stage B.
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation Write \
  --topic payments.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation Write \
  --topic inventory.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation IdempotentWrite \
  --cluster

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation IdempotentWrite \
  --cluster

echo "ACL bootstrap applied for Stage B principals."
