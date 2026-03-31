SET 'auto.offset.reset' = 'earliest';

CREATE TABLE top_products_per_minute WITH (
  KAFKA_TOPIC='analytics.v1.product_metrics',
  VALUE_FORMAT='JSON'
) AS
SELECT
  product_id,
  WINDOWSTART AS window_start,
  WINDOWEND AS window_end,
  COUNT(*) AS orders_per_minute,
  SUM(total_amount) AS revenue_per_minute
FROM orders_events_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY product_id
EMIT CHANGES;

CREATE TABLE top_paths_per_minute WITH (
  KAFKA_TOPIC='analytics.v1.web_path_metrics',
  VALUE_FORMAT='JSON'
) AS
SELECT
  path,
  WINDOWSTART AS window_start,
  WINDOWEND AS window_end,
  COUNT(*) AS hits_per_minute,
  COUNT_DISTINCT(customer_id) AS unique_customers
FROM web_clickstream_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY path
EMIT CHANGES;
