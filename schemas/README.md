# Schemas

Contract policy:
- Format: Avro
- Registry: Confluent Schema Registry
- Subject naming: `<topic>-value`
- Global compatibility: `BACKWARD`

Subject examples:
- `orders.v1.events-value`
- `web.v1.clickstream-value`

Schema files:
- `avro/OrderCreated.avsc`
- `avro/OrderCreatedV2.avsc`
- `avro/PaymentRequested.avsc`
- `avro/PaymentAuthorized.avsc`
- `avro/InventoryReserved.avsc`
- `avro/OrderStatus.avsc`
- `avro/ClickstreamEvent.avsc`
