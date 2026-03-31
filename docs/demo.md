# Demo Script

## Objective

Show end-to-end event-driven order processing with CDC, transactional workers, stateful streaming joins, analytics, and operations visibility.

## Pre-Demo Setup

1. `make up`
2. `make topics`
3. `make schemas-compat`
4. `make schemas`
5. `make connectors`
6. `make ksqldb`
7. Start apps in separate terminals:
   - `make run-orders-api`
   - `make run-payments`
   - `make run-inventory`
   - `make run-streams`
   - `make run-notifications`
   - `make run-telemetry`

## Live Flow

1. Create order:
   - `curl -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"customerId":"c-100","productId":"sku-77","totalAmount":1299.0,"couponCode":null}'`
2. Show CDC event appears:
   - inspect `dbz.orders.outbox_events` (raw envelope)
   - inspect `orders.v1.events` (clean domain event)
3. Show derived outputs:
   - `payments.v1.events`
   - `inventory.v1.events`
   - `orders.v1.status`
   - `risk.v1.fraud_alerts` (trigger with high-value amount)
4. Show clickstream + analytics outputs:
   - `web.v1.clickstream`
   - `analytics.v1.product_metrics`
   - `analytics.v1.web_path_metrics`
5. Verify sink projections:
   - Postgres read model table `orders_status_readmodel`
   - OpenSearch indexes for raw event analytics

## Failure Drill

1. Stop `payments-worker` mid-run.
2. Restart it and replay pending records.
3. Explain transactional+idempotent semantics preventing duplicate committed outcomes.
4. Trigger a notification processing exception and show retry flow:
   - `retry.v1.notifications.5s`
   - `retry.v1.notifications.1m`
   - fallback to `dlq.v1.notifications` after retries.

## Lag and Monitoring Drill

1. Show consumer lag via CLI:
   - `make lag`
2. Walk Grafana dashboards:
   - broker throughput/latency
   - consumer lag trends
   - connector health
   - MM2 replication metrics (if DR profile enabled)

## DR Drill

1. Start DR services:
   - `make dr-up`
2. Show mirrored topics and group offset sync.
3. Verify offset checkpoints:
   - `docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env exec -T dr-kafka1 kafka-consumer-groups --bootstrap-server dr-kafka1:9092 --describe --group notifications-worker`
4. Consume from secondary cluster to demonstrate migration continuity.
