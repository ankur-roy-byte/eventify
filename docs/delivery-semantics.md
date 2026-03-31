# Delivery Semantics

## Semantics Matrix

- At-most-once: consume and commit before processing.
- At-least-once: process then commit; retry may duplicate.
- Exactly-once: transactional write + offset commit atomically.

## Implemented Profiles

### High-value profile

Used by:
- `services/payments-worker/src/main/java/com/example/payments/PaymentsWorkerApplication.java`
- `services/inventory-worker/src/main/java/com/example/inventory/InventoryWorkerApplication.java`

Settings and behaviors:
- `enable.idempotence=true`
- `acks=all`
- `transactional.id` configured
- `sendOffsetsToTransaction(...)` for consume-process-produce EOS pattern

### Low-value clickstream profile

Used by:
- `services/payments-worker/src/main/java/com/example/payments/TelemetryProducerApplication.java`

Settings and behaviors:
- at-least-once profile (non-transactional producer)
- throughput tuning with `linger.ms`, `batch.size`, and `compression.type=zstd`
- published to `web.v1.clickstream`

### Transaction-aware consumers

Used by:
- `services/notifications-worker/app.py`

Settings and behaviors:
- `isolation.level=read_committed`
- manual offset commit only after successful handling
- retry tiers via `retry.v1.notifications.5s` and `retry.v1.notifications.1m` before DLQ

### Streams exactly-once

Used by:
- `services/streams-order-status/src/main/java/com/example/streams/OrderStatusStreamsApplication.java`

Settings:
- `processing.guarantee=exactly_once_v2`
- tuned `commit.interval.ms` for EOS flow
