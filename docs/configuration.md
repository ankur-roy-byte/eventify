# Configuration Highlights

## Replication and Partitions

| Topic | Partitions | RF | Cleanup | Retention |
|---|---:|---:|---|---|
| orders.v1.events | 6 | 3 | delete | 7 days |
| payments.v1.events | 6 | 3 | delete | 7 days |
| inventory.v1.events | 6 | 3 | delete | 7 days |
| orders.v1.status | 6 | 3 | compact | key-last-wins |
| risk.v1.fraud_alerts | 3 | 3 | delete | 30 days |
| web.v1.clickstream | 6 | 3 | delete | 2 days |
| analytics.v1.product_metrics | 6 | 3 | delete | 7 days |
| analytics.v1.web_path_metrics | 6 | 3 | delete | 7 days |
| dbz.orders.outbox_events | 6 | 3 | delete | 7 days |
| retry.v1.notifications.5s | 3 | 3 | delete | 1 day |
| retry.v1.notifications.1m | 3 | 3 | delete | 1 day |
| dlq.v1.notifications | 3 | 3 | delete | 14 days |

Critical topic posture:
- `acks=all` for high-value producers
- `min.insync.replicas=2` on critical topics

## KRaft Container Mapping

Required KRaft env vars are explicitly configured per broker:
- `KAFKA_PROCESS_ROLES`
- `KAFKA_NODE_ID`
- `KAFKA_CONTROLLER_QUORUM_VOTERS`
- `KAFKA_CONTROLLER_LISTENER_NAMES`
- `KAFKA_LISTENERS`
- `KAFKA_ADVERTISED_LISTENERS`
- `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP`

## Connect Distributed Mode Correctness

Configured in `infra/compose/docker-compose.yml`:
- `CONNECT_CONFIG_STORAGE_TOPIC`
- `CONNECT_OFFSET_STORAGE_TOPIC`
- `CONNECT_STATUS_STORAGE_TOPIC`
- key/value converters + Schema Registry URL
- connector plugin path

CDC connectors:
- `connectors/debezium-orders-outbox-raw.json` emits raw envelope records to `dbz.orders.outbox_events`
- `connectors/debezium-orders-outbox.json` applies Debezium outbox SMT routing for clean domain events

## Schema Governance

- Subject naming strategy: `<topic>-value`
- Global compatibility: `BACKWARD`
- Registration helpers:
  - `infra/compose/scripts/set-schema-compatibility.sh`
  - `infra/compose/scripts/register-schemas.sh`

## MirrorMaker2

`infra/compose/mm2/connect-mirror-maker.properties` configures:
- source/target clusters
- topic + group replication
- offset checkpoint synchronization
- topic config and ACL synchronization

## Observability

- JMX exporter sidecars per broker:
  - `jmx-kafka1`, `jmx-kafka2`, `jmx-kafka3`
- Prometheus scrape jobs include:
  - `kafka_exporter`
  - `kafka_jmx_brokers`
- Grafana provisioning includes datasource and preloaded platform dashboard.

## Security Activation

- TLS-only stage:
  - `make up-tls`
- SASL/SCRAM + TLS + ACL stage:
  - `make up-sasl`
  - `make scram-users`
  - `make acls`
