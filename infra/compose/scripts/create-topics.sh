#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-infra/compose/docker-compose.yml}"
compose_cmd=(docker compose -f "${COMPOSE_FILE}")
bootstrap="kafka1:9092"

create_topic() {
  local topic="$1"
  local partitions="$2"
  local rf="$3"
  shift 3

  "${compose_cmd[@]}" exec -T kafka1 kafka-topics \
    --bootstrap-server "${bootstrap}" \
    --if-not-exists \
    --create \
    --topic "${topic}" \
    --partitions "${partitions}" \
    --replication-factor "${rf}" \
    "$@"
}

create_topic "orders.v1.events" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000 \
  --config min.insync.replicas=2

create_topic "payments.v1.events" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000 \
  --config min.insync.replicas=2

create_topic "inventory.v1.events" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000 \
  --config min.insync.replicas=2

create_topic "orders.v1.status" 6 3 \
  --config cleanup.policy=compact \
  --config min.cleanable.dirty.ratio=0.2 \
  --config min.insync.replicas=2

create_topic "risk.v1.fraud_alerts" 3 3 \
  --config cleanup.policy=delete \
  --config retention.ms=2592000000

create_topic "web.v1.clickstream" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=172800000

create_topic "analytics.v1.product_metrics" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

create_topic "analytics.v1.web_path_metrics" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

create_topic "dbz.orders.outbox_events" 6 3 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

create_topic "dlq.v1.notifications" 3 3 \
  --config cleanup.policy=delete \
  --config retention.ms=1209600000

create_topic "retry.v1.notifications.5s" 3 3 \
  --config cleanup.policy=delete \
  --config retention.ms=86400000

create_topic "retry.v1.notifications.1m" 3 3 \
  --config cleanup.policy=delete \
  --config retention.ms=86400000

create_topic "connect-cluster.configs" 1 3 \
  --config cleanup.policy=compact

create_topic "connect-cluster.offsets" 25 3 \
  --config cleanup.policy=compact

create_topic "connect-cluster.status" 5 3 \
  --config cleanup.policy=compact

echo "Topic bootstrap completed."
