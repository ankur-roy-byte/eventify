package com.example.payments;

import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import io.confluent.kafka.serializers.KafkaAvroDeserializerConfig;
import io.confluent.kafka.serializers.KafkaAvroSerializer;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;

import java.time.Duration;
import java.time.Instant;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

public class PaymentsWorkerApplication {

        private static final String PAYMENT_AUTHORIZED_SCHEMA =
                        "{\"type\":\"record\",\"name\":\"PaymentAuthorized\",\"namespace\":\"com.example.events.payments.v1\"," +
                                        "\"fields\":[{\"name\":\"order_id\",\"type\":\"string\"},{\"name\":\"payment_status\",\"type\":\"string\"}," +
                                        "{\"name\":\"authorized_at\",\"type\":\"string\"}]}";

    public static void main(String[] args) {
        String bootstrap = System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:19092,localhost:29092,localhost:39092");
        String schemaRegistry = System.getenv().getOrDefault("SCHEMA_REGISTRY_URL", "http://localhost:8081");

        Properties consumerProps = new Properties();
        consumerProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
        consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG, "payments-worker");
        consumerProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
        consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class.getName());
        consumerProps.put(KafkaAvroDeserializerConfig.SCHEMA_REGISTRY_URL_CONFIG, schemaRegistry);
        consumerProps.put(KafkaAvroDeserializerConfig.SPECIFIC_AVRO_READER_CONFIG, "false");

        Properties producerProps = new Properties();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
        producerProps.put(ProducerConfig.ACKS_CONFIG, "all");
        producerProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
        producerProps.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "payments-worker-tx-v1");
        producerProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class.getName());
        producerProps.put("schema.registry.url", schemaRegistry);

        Schema paymentSchema = new Schema.Parser().parse(PAYMENT_AUTHORIZED_SCHEMA);

        try (KafkaConsumer<String, GenericRecord> consumer = new KafkaConsumer<>(consumerProps);
             KafkaProducer<String, GenericRecord> producer = new KafkaProducer<>(producerProps)) {

            producer.initTransactions();
            consumer.subscribe(Collections.singletonList("orders.v1.events"));

            while (true) {
                ConsumerRecords<String, GenericRecord> records = consumer.poll(Duration.ofSeconds(1));
                if (records.isEmpty()) {
                    continue;
                }

                Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();

                try {
                    producer.beginTransaction();

                    for (ConsumerRecord<String, GenericRecord> record : records) {
                        GenericRecord orderCreated = record.value();
                        String orderId = orderCreated.get("order_id").toString();

                        GenericRecord paymentAuthorized = new GenericData.Record(paymentSchema);
                        paymentAuthorized.put("order_id", orderId);
                        paymentAuthorized.put("payment_status", "AUTHORIZED");
                        paymentAuthorized.put("authorized_at", Instant.now().toString());

                        producer.send(new ProducerRecord<>("payments.v1.events", orderId, paymentAuthorized));
                        offsets.put(
                                new TopicPartition(record.topic(), record.partition()),
                                new OffsetAndMetadata(record.offset() + 1)
                        );
                    }

                    producer.sendOffsetsToTransaction(offsets, consumer.groupMetadata());
                    producer.commitTransaction();
                } catch (Exception ex) {
                    producer.abortTransaction();
                }
            }
        }
    }
}
