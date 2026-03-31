# Operations Runbook

## Lag Spikes: What to Check

1. Inspect consumer lag:
   - `make lag`
2. Verify worker health/logs for backpressure or retry storms.
3. Check broker IO/network saturation in Grafana.
4. Scale consumer instances or tune poll/process batch sizing.
5. Validate no stuck connector task is backlogging upstream topics.

## ISR Shrink: What to Check

1. Inspect under-replicated partitions in broker metrics.
2. Check broker restarts or network instability.
3. Confirm disk pressure and replication fetch health.
4. Validate topic `min.insync.replicas` against current broker availability.
5. Avoid unsafe producer downgrade (`acks=1`) for critical topics.

## Replay from Earliest Safely

1. Use a new consumer group for replay jobs.
2. Set `auto.offset.reset=earliest`.
3. Isolate replay output to sandbox topics or idempotent upsert sinks.
4. Monitor lag and side effects before cutting over.

## Connect Incidents

1. Check `/connectors/<name>/status` for failed tasks.
2. Inspect DLQ volume in `dlq.v1.notifications`.
3. Review `errors.*` context headers for root cause.
4. Restart only failed connector/task when possible.

## DR Failover Drill

1. Start DR profile: `make dr-up`.
2. Confirm mirrored topics in secondary cluster.
3. Verify checkpoints and offset sync topics are advancing.
4. Start consumer against secondary bootstrap and validate offset continuity.
