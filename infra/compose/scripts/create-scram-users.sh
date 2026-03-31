#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-infra/compose/docker-compose.yml}"
compose_cmd=(docker compose -f "${COMPOSE_FILE}")

load_env_file() {
  local file_path="$1"
  if [[ -f "${file_path}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${file_path}"
    set +a
  fi
}

ensure_secure_secret() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" || "${value}" == CHANGE_ME* ]]; then
    echo "Error: ${name} must be set to a non-placeholder value." >&2
    exit 1
  fi
}

load_env_file "infra/compose/.env"
load_env_file "infra/compose/.env.local"

SCRAM_ADMIN_PASSWORD="${SCRAM_ADMIN_PASSWORD:-}"
SCRAM_PAYMENTS_PASSWORD="${SCRAM_PAYMENTS_PASSWORD:-}"
SCRAM_INVENTORY_PASSWORD="${SCRAM_INVENTORY_PASSWORD:-}"
SCRAM_NOTIFICATIONS_PASSWORD="${SCRAM_NOTIFICATIONS_PASSWORD:-}"
SCRAM_STREAMS_PASSWORD="${SCRAM_STREAMS_PASSWORD:-}"

ensure_secure_secret "SCRAM_ADMIN_PASSWORD" "${SCRAM_ADMIN_PASSWORD}"
ensure_secure_secret "SCRAM_PAYMENTS_PASSWORD" "${SCRAM_PAYMENTS_PASSWORD}"
ensure_secure_secret "SCRAM_INVENTORY_PASSWORD" "${SCRAM_INVENTORY_PASSWORD}"
ensure_secure_secret "SCRAM_NOTIFICATIONS_PASSWORD" "${SCRAM_NOTIFICATIONS_PASSWORD}"
ensure_secure_secret "SCRAM_STREAMS_PASSWORD" "${SCRAM_STREAMS_PASSWORD}"

create_user() {
  local username="$1"
  local password="$2"

  "${compose_cmd[@]}" exec -T kafka1 kafka-configs \
    --bootstrap-server kafka1:9092 \
    --alter \
    --add-config "SCRAM-SHA-512=[password=${password}]" \
    --entity-type users \
    --entity-name "${username}"
}

create_user admin "${SCRAM_ADMIN_PASSWORD}"
create_user payments-worker "${SCRAM_PAYMENTS_PASSWORD}"
create_user inventory-worker "${SCRAM_INVENTORY_PASSWORD}"
create_user notifications-worker "${SCRAM_NOTIFICATIONS_PASSWORD}"
create_user streams-order-status "${SCRAM_STREAMS_PASSWORD}"

echo "SCRAM users created from environment-provided secrets."
