SET 'auto.offset.reset' = 'earliest';

CREATE STREAM orders_events_stream (
  order_id VARCHAR KEY,
  customer_id VARCHAR,
  product_id VARCHAR,
  total_amount DOUBLE,
  created_at VARCHAR
) WITH (
  KAFKA_TOPIC='orders.v1.events',
  VALUE_FORMAT='AVRO'
);

CREATE STREAM payments_events_stream (
  order_id VARCHAR KEY,
  payment_status VARCHAR,
  authorized_at VARCHAR
) WITH (
  KAFKA_TOPIC='payments.v1.events',
  VALUE_FORMAT='AVRO'
);

CREATE STREAM inventory_events_stream (
  order_id VARCHAR KEY,
  inventory_status VARCHAR,
  reserved_at VARCHAR
) WITH (
  KAFKA_TOPIC='inventory.v1.events',
  VALUE_FORMAT='AVRO'
);

CREATE TABLE payments_latest WITH (
  KAFKA_TOPIC='payments.v1.latest',
  VALUE_FORMAT='JSON'
) AS
SELECT order_id, LATEST_BY_OFFSET(payment_status) AS payment_status
FROM payments_events_stream
GROUP BY order_id
EMIT CHANGES;

CREATE TABLE inventory_latest WITH (
  KAFKA_TOPIC='inventory.v1.latest',
  VALUE_FORMAT='JSON'
) AS
SELECT order_id, LATEST_BY_OFFSET(inventory_status) AS inventory_status
FROM inventory_events_stream
GROUP BY order_id
EMIT CHANGES;

CREATE STREAM web_clickstream_stream (
  customer_id VARCHAR KEY,
  event_id VARCHAR,
  session_id VARCHAR,
  path VARCHAR,
  event_at VARCHAR
) WITH (
  KAFKA_TOPIC='web.v1.clickstream',
  VALUE_FORMAT='AVRO'
);
