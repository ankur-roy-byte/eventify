# Project Checklist Completion Matrix

This matrix maps the requested build plan to concrete repository implementation files.

## Repository and Standards

1. Monorepo layout: completed
- infra/compose/
- infra/k8s/
- schemas/
- services/orders-api/
- services/payments-worker/
- services/inventory-worker/
- services/streams-order-status/
- services/notifications-worker/
- connectors/
- ksqldb/
- docs/
- Makefile

2. Primary language decision: completed
- Java services for Streams and core workers
- Python non-Streams consumer with manual offset handling in services/notifications-worker/app.py

3. Consistent contract strategy: completed
- Avro schemas in schemas/avro/
- Subject policy in schemas/compatibility.json and docs/topic-contracts.md

## KRaft Infrastructure

4. KRaft-first strategy: completed
- infra/compose/docker-compose.yml

5. Three-node KRaft cluster with required env vars: completed
- infra/compose/docker-compose.yml

6. Combined mode and optional separated controllers milestone: completed
- combined in infra/compose/docker-compose.yml
- optional separated topology in infra/compose/docker-compose.separated-controllers.yml

7. Broker baseline posture: completed
- KAFKA_AUTO_CREATE_TOPICS_ENABLE=false
- internal replication settings in infra/compose/docker-compose.yml

## Topics and Configuration

8. Explicit topic creation script with partitions/RF: completed
- infra/compose/scripts/create-topics.sh

9. Topic retention and compaction policy controls: completed
- infra/compose/scripts/create-topics.sh
- docs/decisions.md

## Schema Registry and Evolution

10. Schema Registry service and required settings: completed
- infra/compose/docker-compose.yml

11. Schemas defined and naming strategy documented: completed
- schemas/avro/*.avsc
- schemas/README.md

12. Backward-compatibility governance and demo: completed
- infra/compose/scripts/set-schema-compatibility.sh
- docs/schema-evolution-demo.md

## Kafka Connect and CDC

13. Connect distributed mode with internal topics and plugin path: completed
- infra/compose/docker-compose.yml
- infra/compose/scripts/create-topics.sh

14. Manual Connect internal topics with compaction: completed
- infra/compose/scripts/create-topics.sh

15. Debezium Postgres CDC + outbox + least-privileged replication user: completed
- infra/compose/postgres/init/001_init.sql
- connectors/debezium-orders-outbox-raw.json
- connectors/debezium-orders-outbox.json

16. Raw CDC output + transformed domain events + keying/routing SMT: completed
- raw topic dbz.orders.outbox_events via connectors/debezium-orders-outbox-raw.json
- domain routing via connectors/debezium-orders-outbox.json

17. Two sink connectors + DLQ/error context: completed
- connectors/sink-orders-status-readmodel.json
- connectors/sink-raw-events-analytics.json
- optional data-lake sink template:
  - connectors/sink-raw-events-datalake.template.json

## Producers/Consumers Correctness

18. Producer reliability profiles: completed
- transactional high-value workers:
  - services/payments-worker/src/main/java/com/example/payments/PaymentsWorkerApplication.java
  - services/inventory-worker/src/main/java/com/example/inventory/InventoryWorkerApplication.java
- at-least-once clickstream profile:
  - services/payments-worker/src/main/java/com/example/payments/TelemetryProducerApplication.java

19. Consumer offset strategies: completed
- manual commit + read_committed in services/notifications-worker/app.py
- retry-tier pattern with retry.v1.notifications.5s and retry.v1.notifications.1m in services/notifications-worker/app.py
- transaction-aware offset handling in worker consume-process-produce loops

## Streams and ksqlDB

20. Kafka Streams stateful joins and derived outputs: completed
- services/streams-order-status/src/main/java/com/example/streams/OrderStatusStreamsApplication.java

21. Streams exactly-once v2 enabled: completed
- processing.guarantee=exactly_once_v2 in streams app

22. ksqlDB SQL migrations for stream/table and metrics: completed
- ksqldb/001_create_streams.sql
- ksqldb/002_metrics.sql

## Observability and Operations

23. Prometheus/Grafana + JMX exporter + lag monitoring: completed
- infra/compose/docker-compose.yml (jmx-kafka1/2/3, prometheus, grafana, kafka-exporter)
- infra/compose/prometheus/prometheus.yml
- infra/compose/grafana/dashboards/kafka-platform-overview.json
- Makefile lag target

24. Runbook with lag/ISR/replay procedures: completed
- docs/runbook.md

## Security and Authorization

25. Stage A TLS-only and Stage B SASL/SCRAM+TLS+ACL: completed
- infra/compose/docker-compose.stage-a-tls.yml
- infra/compose/docker-compose.stage-b-sasl-acl.yml
- infra/compose/security/README.md

26. StandardAuthorizer in KRaft and ACL bootstrapping scripts: completed
- stage-b overlay uses org.apache.kafka.metadata.authorizer.StandardAuthorizer
- infra/compose/scripts/create-acls.sh
- infra/compose/scripts/create-scram-users.sh

## Multi-Cluster DR

27. Secondary DR cluster: completed
- dr-kafka1 profile in infra/compose/docker-compose.yml

28. MirrorMaker2 replication flow and offset sync: completed
- infra/compose/mm2/connect-mirror-maker.properties
- docs/demo.md DR drill

## Recruiter-Facing Narrative

29. Configuration rationale and semantics docs: completed
- docs/configuration.md
- docs/delivery-semantics.md
- docs/topic-contracts.md

30. Demo narrative and resume bullets: completed
- docs/demo.md
- docs/resume-bullets.md
