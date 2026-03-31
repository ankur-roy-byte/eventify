# Architecture Decisions

## KRaft-First Strategy

- Chosen mode: KRaft combined mode (`broker,controller`) for local experimentation.
- Rationale: modern Kafka operation model without ZooKeeper and recruiter-visible KRaft fluency.
- Advanced milestone: optional separated controller and broker topology in `infra/compose/docker-compose.separated-controllers.yml`.

## Retention and Cleanup Policy

- `orders.v1.status`: `cleanup.policy=compact` to maintain latest status by key.
- Event topics (`orders.v1.events`, `payments.v1.events`, `inventory.v1.events`): `cleanup.policy=delete` with 7-day retention baseline (`retention.ms=604800000`).
- Risk and DLQ topics: delete policy with longer retention for incident triage.

## Key Strategy

- Domain key standard: `order_id`.
- Why: preserves order-level ordering, enables stable partitioning, and supports efficient table-style compaction for status streams.

## Delivery Semantics Strategy

- High-value operations (payments/inventory): idempotent + transactional producer and transactional consume-process-produce.
- Status notifications: manual offset commit after successful processing.
- Stream processing: `exactly_once_v2` in Kafka Streams.

## Connector Internal Topics

- Manually created topics for Connect distributed mode:
  - `connect-cluster.configs` (1 partition, compact)
  - `connect-cluster.offsets` (25 partitions, compact)
  - `connect-cluster.status` (5 partitions, compact)

## Observability Decision

- Use both exporter layers:
  - broker JMX exporter sidecars for JVM/broker internals
  - kafka-exporter for consumer lag and topic/group operational visibility

## Security Rollout Plan

- Stage A: TLS encryption in development/staging.
- Stage B: SASL/SCRAM + TLS + ACL enforcement via StandardAuthorizer in KRaft.
