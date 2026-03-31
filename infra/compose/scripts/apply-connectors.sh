#!/usr/bin/env bash
set -euo pipefail

CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

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
    echo "Error: ${name} must be set to a non-placeholder value before applying connectors." >&2
    exit 1
  fi
}

load_env_file "infra/compose/.env"
load_env_file "infra/compose/.env.local"

DBZ_REPLICATION_PASSWORD="${DBZ_REPLICATION_PASSWORD:-}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"

ensure_secure_secret "DBZ_REPLICATION_PASSWORD" "${DBZ_REPLICATION_PASSWORD}"
ensure_secure_secret "POSTGRES_PASSWORD" "${POSTGRES_PASSWORD}"

config_payload() {
  local config_file="$1"
  case "${config_file}" in
    connectors/debezium-orders-outbox.json|connectors/debezium-orders-outbox-raw.json)
      jq -c --arg dbzPass "${DBZ_REPLICATION_PASSWORD}" '.config + {"database.password": $dbzPass}' "${config_file}"
      ;;
    connectors/sink-orders-status-readmodel.json)
      jq -c --arg dbPass "${POSTGRES_PASSWORD}" '.config + {"connection.password": $dbPass}' "${config_file}"
      ;;
    *)
      jq -c '.config' "${config_file}"
      ;;
  esac
}

register_connector() {
  local config_file="$1"
  local name
  name=$(jq -r '.name' "${config_file}")

  echo "Applying connector ${name} from ${config_file}"

  curl -sS -X PUT "${CONNECT_URL}/connectors/${name}/config" \
    -H 'Content-Type: application/json' \
    --data "$(config_payload "${config_file}")" >/dev/null
}

register_connector connectors/debezium-orders-outbox.json
register_connector connectors/debezium-orders-outbox-raw.json
register_connector connectors/sink-orders-status-readmodel.json
register_connector connectors/sink-raw-events-analytics.json

echo "Connectors applied."
