#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DBZ_REPLICATION_PASSWORD:-}" || "${DBZ_REPLICATION_PASSWORD}" == CHANGE_ME* ]]; then
  echo "Error: DBZ_REPLICATION_PASSWORD must be set to a non-placeholder value." >&2
  exit 1
fi

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<EOSQL
DO \
\$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dbz_user') THEN
    CREATE ROLE dbz_user WITH REPLICATION LOGIN PASSWORD '${DBZ_REPLICATION_PASSWORD}';
  ELSE
    ALTER ROLE dbz_user WITH REPLICATION LOGIN PASSWORD '${DBZ_REPLICATION_PASSWORD}';
  END IF;
END
\$\$;

GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO dbz_user;
GRANT USAGE ON SCHEMA public TO dbz_user;
GRANT SELECT ON TABLE orders, outbox_events TO dbz_user;
EOSQL
