package com.example.payments;

import io.confluent.kafka.serializers.KafkaAvroSerializer;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

import java.time.Instant;
import java.util.Properties;
import java.util.UUID;

public class TelemetryProducerApplication {

    private static final String CLICKSTREAM_SCHEMA =
            "{\"type\":\"record\",\"name\":\"ClickstreamEvent\",\"namespace\":\"com.example.events.web.v1\"," +
                    "\"fields\":[{\"name\":\"event_id\",\"type\":\"string\"},{\"name\":\"session_id\",\"type\":\"string\"}," +
                    "{\"name\":\"customer_id\",\"type\":\"string\"},{\"name\":\"path\",\"type\":\"string\"}," +
                    "{\"name\":\"event_at\",\"type\":\"string\"}]}";

    public static void main(String[] args) {
        String bootstrap = System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:19092,localhost:29092,localhost:39092");
        String schemaRegistry = System.getenv().getOrDefault("SCHEMA_REGISTRY_URL", "http://localhost:8081");

        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, Integer.MAX_VALUE);
        props.put(ProducerConfig.LINGER_MS_CONFIG, 25);
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 131072);
        props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "zstd");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class.getName());
        props.put("schema.registry.url", schemaRegistry);

        Schema schema = new Schema.Parser().parse(CLICKSTREAM_SCHEMA);

        try (KafkaProducer<String, GenericRecord> producer = new KafkaProducer<>(props)) {
            for (int i = 0; i < 100; i++) {
                GenericRecord event = new GenericData.Record(schema);
                String customerId = "cust-" + (i % 10);
                event.put("event_id", UUID.randomUUID().toString());
                event.put("session_id", "session-" + (i / 5));
                event.put("customer_id", customerId);
                event.put("path", "/checkout");
                event.put("event_at", Instant.now().toString());

                producer.send(new ProducerRecord<>("web.v1.clickstream", customerId, event));
            }

            producer.flush();
        }
    }
}
