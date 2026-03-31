# Architecture

## Core Runtime Topology

Primary cluster (KRaft, combined mode for local):
- `kafka1`, `kafka2`, `kafka3` (broker+controller)
- Schema Registry
- Kafka Connect (distributed mode)
- Postgres (`orders`, `outbox_events`)
- ksqlDB
- Kafka Streams application (`streams-order-status`)
- Worker consumers/producers (`payments-worker`, `inventory-worker`, `notifications-worker`)
- Prometheus + Grafana + Kafka exporter

DR topology:
- `dr-kafka1` as secondary cluster
- MirrorMaker2 flow from primary to secondary

## Data Flow

1. `orders-api` writes order business state + outbox row in one DB transaction.
2. Debezium captures `outbox_events` changes and routes to `orders.v1.events`.
	- raw envelope records are also published to `dbz.orders.outbox_events`.
3. `payments-worker` and `inventory-worker` consume order events and emit transactional outcomes.
4. `streams-order-status` joins latest payment + inventory state into `orders.v1.status` and emits risk alerts.
5. Sinks persist status and analytics copies for read/query systems.
6. `notifications-worker` consumes committed status updates with manual offset control.

## Monitoring Plane

- broker JVM/JMX metrics via JMX exporter sidecars
- consumer lag and topic/group metrics via kafka-exporter
- Prometheus scrape and Grafana dashboards for throughput, lag, ISR health, and replication indicators

## Event Contract Governance

- All domain topics use Avro + Schema Registry.
- Subject naming strategy: `<topic>-value`.
- Global compatibility: `BACKWARD`.

## Operational Goals

- Explicit topic lifecycle management (`auto.create.topics.enable=false`)
- RF=3 for critical topics and internal metadata topics
- min ISR protections for high-value event streams
- EOS for critical consume-process-produce workflows
