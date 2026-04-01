#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-infra/compose/docker-compose.yml}"
compose_cmd=(docker compose -f "${COMPOSE_FILE}")

# ── payments-worker ──────────────────────────────────────────────────────────
# Consume from orders.v1.events
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation Read \
  --topic orders.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation Read \
  --group payments-worker

# Produce to payments.v1.events
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation Write \
  --topic payments.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:payments-worker \
  --operation IdempotentWrite \
  --cluster

# ── inventory-worker ─────────────────────────────────────────────────────────
# Consume from orders.v1.events
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation Read \
  --topic orders.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation Read \
  --group inventory-worker

# Produce to inventory.v1.events
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation Write \
  --topic inventory.v1.events

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:inventory-worker \
  --operation IdempotentWrite \
  --cluster

# ── streams-order-status ─────────────────────────────────────────────────────
# Consume input topics
for topic in orders.v1.events payments.v1.events inventory.v1.events; do
  "${compose_cmd[@]}" exec -T kafka1 kafka-acls \
    --bootstrap-server kafka1:9092 \
    --add \
    --allow-principal User:streams-order-status \
    --operation Read \
    --topic "${topic}"
done

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:streams-order-status \
  --operation Read \
  --group streams-order-status-v1

# Produce to output topics
for topic in orders.v1.status risk.v1.fraud_alerts; do
  "${compose_cmd[@]}" exec -T kafka1 kafka-acls \
    --bootstrap-server kafka1:9092 \
    --add \
    --allow-principal User:streams-order-status \
    --operation Write \
    --topic "${topic}"
done

# Kafka Streams needs Create permission for internal changelog/repartition topics
"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:streams-order-status \
  --operation Create \
  --topic streams-order-status-v1 \
  --resource-pattern-type prefixed

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:streams-order-status \
  --operation IdempotentWrite \
  --cluster

# ── notifications-worker ─────────────────────────────────────────────────────
# Consume primary and retry topics
for topic in orders.v1.status risk.v1.fraud_alerts retry.v1.notifications.5s retry.v1.notifications.1m; do
  "${compose_cmd[@]}" exec -T kafka1 kafka-acls \
    --bootstrap-server kafka1:9092 \
    --add \
    --allow-principal User:notifications-worker \
    --operation Read \
    --topic "${topic}"
done

"${compose_cmd[@]}" exec -T kafka1 kafka-acls \
  --bootstrap-server kafka1:9092 \
  --add \
  --allow-principal User:notifications-worker \
  --operation Read \
  --group notifications-worker

# Produce to retry and DLQ topics
for topic in retry.v1.notifications.5s retry.v1.notifications.1m dlq.v1.notifications; do
  "${compose_cmd[@]}" exec -T kafka1 kafka-acls \
    --bootstrap-server kafka1:9092 \
    --add \
    --allow-principal User:notifications-worker \
    --operation Write \
    --topic "${topic}"
done

echo "ACL bootstrap applied for all Stage B principals."
