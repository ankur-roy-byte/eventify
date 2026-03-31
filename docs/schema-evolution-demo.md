# Schema Evolution Demo

Goal: prove backward-compatible evolution with Schema Registry.

## Subjects

- `orders.v1.events-value`

## Versions

- V1: `schemas/avro/OrderCreated.avsc`
  - fields: `order_id`, `customer_id`, `product_id`, `total_amount`, `created_at`
- V2: `schemas/avro/OrderCreatedV2.avsc`
  - adds optional `coupon_code` with default `null`

## Steps

1. Start stack and set global compatibility:
   - `make up`
   - `make topics`
   - `make schemas-compat`
2. Register V1:
   - `curl -X POST http://localhost:8081/subjects/orders.v1.events-value/versions ...`
3. Produce V1 events and consume with a V1 reader.
4. Register V2 with optional defaulted field.
5. Produce V2 events including `coupon_code`.
6. Re-run V1 consumer and verify it still reads records.

## Why Compatible

Adding an optional field with a default preserves backward compatibility for older readers.
