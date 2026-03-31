# Topic Contracts and Key Strategy

All topics are explicitly created in infra/compose/scripts/create-topics.sh with partition, RF, cleanup policy, and retention controls.

| Topic | Key Strategy | Partitions | RF | cleanup.policy | retention |
|---|---|---:|---:|---|---|
| orders.v1.events | order_id | 6 | 3 | delete | 7 days |
| payments.v1.events | order_id | 6 | 3 | delete | 7 days |
| inventory.v1.events | order_id | 6 | 3 | delete | 7 days |
| orders.v1.status | order_id | 6 | 3 | compact | latest by key |
| risk.v1.fraud_alerts | order_id | 3 | 3 | delete | 30 days |
| web.v1.clickstream | customer_id | 6 | 3 | delete | 2 days |
| analytics.v1.product_metrics | product_id | 6 | 3 | delete | 7 days |
| analytics.v1.web_path_metrics | path | 6 | 3 | delete | 7 days |
| dbz.orders.outbox_events | aggregate_id | 6 | 3 | delete | 7 days |
| retry.v1.notifications.5s | source key pass-through | 3 | 3 | delete | 1 day |
| retry.v1.notifications.1m | source key pass-through | 3 | 3 | delete | 1 day |
| dlq.v1.notifications | source key pass-through | 3 | 3 | delete | 14 days |
| connect-cluster.configs | internal | 1 | 3 | compact | n/a |
| connect-cluster.offsets | internal | 25 | 3 | compact | n/a |
| connect-cluster.status | internal | 5 | 3 | compact | n/a |
