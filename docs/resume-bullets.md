# Resume Bullets

- Built an event-driven microservices platform with Kafka using CDC (Debezium + Kafka Connect), schema governance (Schema Registry), and stateful stream processing (Kafka Streams `exactly_once_v2`).
- Implemented multi-cluster disaster recovery with MirrorMaker 2 replicating topics, consumer groups/offsets, and ACL metadata across clusters.
- Operationalized Kafka with Prometheus/Grafana metrics and lag monitoring, plus runbooks for lag spikes, ISR shrink events, and replay safety.
- Implemented transactional/idempotent producer flows for high-value domains and `read_committed` consumers for transaction-aware downstream processing.
- Designed a KRaft-first architecture with explicit topic governance (partitioning, RF, compaction/retention, key strategy) and Connect distributed-mode correctness.
