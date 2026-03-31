package com.example.streams;

import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.Consumed;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KTable;
import org.apache.kafka.streams.kstream.Materialized;
import org.apache.kafka.streams.kstream.Produced;

import java.time.Instant;
import java.util.Map;
import java.util.Properties;

public class OrderStatusStreamsApplication {

        private static final Schema ORDER_STATUS_SCHEMA = new Schema.Parser().parse(
                        "{\"type\":\"record\",\"name\":\"OrderStatus\",\"namespace\":\"com.example.events.orders.v1\"," +
                                        "\"fields\":[{\"name\":\"order_id\",\"type\":\"string\"},{\"name\":\"status\",\"type\":\"string\"}," +
                                        "{\"name\":\"payment_status\",\"type\":[\"null\",\"string\"],\"default\":null}," +
                                        "{\"name\":\"inventory_status\",\"type\":[\"null\",\"string\"],\"default\":null}," +
                                        "{\"name\":\"updated_at\",\"type\":\"string\"}]}"
        );

        private static final Schema FRAUD_ALERT_SCHEMA = new Schema.Parser().parse(
                        "{\"type\":\"record\",\"name\":\"PaymentRequested\",\"namespace\":\"com.example.events.payments.v1\"," +
                                        "\"fields\":[{\"name\":\"order_id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}," +
                                        "{\"name\":\"requested_at\",\"type\":\"string\"}]}"
        );

    public static void main(String[] args) {
        String bootstrap = System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:19092,localhost:29092,localhost:39092");
        String schemaRegistry = System.getenv().getOrDefault("SCHEMA_REGISTRY_URL", "http://localhost:8081");

        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "streams-order-status-v1");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
        props.put("schema.registry.url", schemaRegistry);
        props.put(StreamsConfig.PROCESSING_GUARANTEE_CONFIG, StreamsConfig.EXACTLY_ONCE_V2);
        props.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 200);

        Serde<String> keySerde = Serdes.String();
        GenericAvroSerde valueSerde = new GenericAvroSerde();
        valueSerde.configure(Map.of("schema.registry.url", schemaRegistry), false);

        StreamsBuilder builder = new StreamsBuilder();

        KTable<String, GenericRecord> ordersLatest = builder
                .stream("orders.v1.events", Consumed.with(keySerde, valueSerde))
                .toTable(Materialized.with(keySerde, valueSerde));

        KTable<String, GenericRecord> paymentsLatest = builder
                .stream("payments.v1.events", Consumed.with(keySerde, valueSerde))
                .toTable(Materialized.with(keySerde, valueSerde));

        KTable<String, GenericRecord> inventoryLatest = builder
                .stream("inventory.v1.events", Consumed.with(keySerde, valueSerde))
                .toTable(Materialized.with(keySerde, valueSerde));

        KTable<String, GenericRecord> withPayment = ordersLatest.leftJoin(
                paymentsLatest,
                (order, payment) -> buildStatus(order, payment, null),
                Materialized.with(keySerde, valueSerde)
        );

        KTable<String, GenericRecord> finalStatus = withPayment.leftJoin(
                inventoryLatest,
                OrderStatusStreamsApplication::mergeInventoryStatus,
                Materialized.with(keySerde, valueSerde)
        );

        finalStatus.toStream().to("orders.v1.status", Produced.with(keySerde, valueSerde));

        KStream<String, GenericRecord> fraudAlerts = builder
                .stream("orders.v1.events", Consumed.with(keySerde, valueSerde))
                .filter((key, order) -> extractAmount(order) >= 10000.0)
                .mapValues(OrderStatusStreamsApplication::toFraudAlert);

        fraudAlerts.to("risk.v1.fraud_alerts", Produced.with(keySerde, valueSerde));

        KafkaStreams streams = new KafkaStreams(builder.build(), props);
        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));
        streams.start();
    }

    private static GenericRecord buildStatus(GenericRecord order, GenericRecord payment, GenericRecord inventory) {
        GenericRecord status = new GenericData.Record(ORDER_STATUS_SCHEMA);
        String orderId = order.get("order_id").toString();
        String paymentStatus = payment == null ? null : payment.get("payment_status").toString();
        String inventoryStatus = inventory == null ? null : inventory.get("inventory_status").toString();

        status.put("order_id", orderId);
        status.put("payment_status", paymentStatus);
        status.put("inventory_status", inventoryStatus);
        status.put("status", computeStatus(paymentStatus, inventoryStatus));
        status.put("updated_at", Instant.now().toString());
        return status;
    }

    private static GenericRecord mergeInventoryStatus(GenericRecord partialStatus, GenericRecord inventory) {
        if (partialStatus == null) {
            return null;
        }

        String paymentStatus = partialStatus.get("payment_status") == null
                ? null
                : partialStatus.get("payment_status").toString();

        String inventoryStatus = inventory == null
                ? (partialStatus.get("inventory_status") == null ? null : partialStatus.get("inventory_status").toString())
                : inventory.get("inventory_status").toString();

        GenericRecord merged = new GenericData.Record(ORDER_STATUS_SCHEMA);
        merged.put("order_id", partialStatus.get("order_id").toString());
        merged.put("payment_status", paymentStatus);
        merged.put("inventory_status", inventoryStatus);
        merged.put("status", computeStatus(paymentStatus, inventoryStatus));
        merged.put("updated_at", Instant.now().toString());
        return merged;
    }

    private static GenericRecord toFraudAlert(GenericRecord order) {
        GenericRecord fraudAlert = new GenericData.Record(FRAUD_ALERT_SCHEMA);
        fraudAlert.put("order_id", order.get("order_id").toString());
        fraudAlert.put("amount", extractAmount(order));
        fraudAlert.put("requested_at", Instant.now().toString());
        return fraudAlert;
    }

    private static double extractAmount(GenericRecord order) {
        Object amount = order.get("total_amount");
        if (amount instanceof Number) {
            return ((Number) amount).doubleValue();
        }
        return Double.parseDouble(amount.toString());
    }

    private static String computeStatus(String paymentStatus, String inventoryStatus) {
        if ("AUTHORIZED".equals(paymentStatus) && "RESERVED".equals(inventoryStatus)) {
            return "READY_TO_SHIP";
        }
        if (paymentStatus == null || inventoryStatus == null) {
            return "PENDING";
        }
        return "ON_HOLD";
    }
}
