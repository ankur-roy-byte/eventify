import json
import os
import signal
import sys
import time
from pathlib import Path

from confluent_kafka import Consumer, KafkaError, Producer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroDeserializer
from confluent_kafka.serialization import MessageField, SerializationContext


RUNNING = True
RETRY_TOPICS = ["retry.v1.notifications.5s", "retry.v1.notifications.1m"]
PRIMARY_TOPICS = ["orders.v1.status", "risk.v1.fraud_alerts"]
RETRY_DELAYS_MS = [5000, 60000]


def stop_handler(_signum, _frame):
    global RUNNING
    RUNNING = False


def decode_headers(message) -> dict[str, str]:
    decoded = {}
    for key, value in message.headers() or []:
        decoded[key] = value.decode("utf-8") if isinstance(value, bytes) else str(value)
    return decoded


def to_headers(raw: dict[str, str]) -> list[tuple[str, bytes]]:
    return [(key, value.encode("utf-8")) for key, value in raw.items()]


def parse_attempt(headers: dict[str, str]) -> int:
    try:
        return int(headers.get("x-retry-attempt", "0"))
    except ValueError:
        return 0


def process_status_notification(order_status: dict) -> None:
    order_id = order_status.get("order_id")
    status = order_status.get("status")
    print(f"notification dispatched for order={order_id}, status={status}")


def process_fraud_notification(fraud_alert: dict) -> None:
    order_id = fraud_alert.get("order_id")
    amount = fraud_alert.get("amount")
    print(f"fraud alert dispatched for order={order_id}, amount={amount}")


def route_to_retry(dlq_producer: Producer, message, headers: dict[str, str], error_text: str) -> bool:
    attempt = parse_attempt(headers)
    if attempt >= len(RETRY_TOPICS):
        return False

    retry_topic = RETRY_TOPICS[attempt]
    delay_ms = RETRY_DELAYS_MS[attempt]
    now_ms = int(time.time() * 1000)
    original_topic = headers.get("x-original-topic", message.topic())

    retry_headers = {
        "x-retry-attempt": str(attempt + 1),
        "x-not-before-epoch-ms": str(now_ms + delay_ms),
        "x-original-topic": original_topic,
        "x-last-error": error_text,
    }

    dlq_producer.produce(
        retry_topic,
        key=(message.key() or b""),
        value=message.value(),
        headers=to_headers(retry_headers),
    )
    dlq_producer.flush(5)
    return True


def route_to_dlq(dlq_producer: Producer, message, headers: dict[str, str], error_text: str) -> None:
    payload = {
        "topic": message.topic(),
        "partition": message.partition(),
        "offset": message.offset(),
        "error": error_text,
        "retry_attempt": parse_attempt(headers),
        "original_topic": headers.get("x-original-topic", message.topic()),
    }

    dlq_producer.produce(
        "dlq.v1.notifications",
        key=(message.key() or b""),
        value=json.dumps(payload).encode("utf-8"),
    )
    dlq_producer.flush(5)


def resolve_base_topic(message, headers: dict[str, str]) -> str:
    if message.topic() in RETRY_TOPICS:
        return headers.get("x-original-topic", "orders.v1.status")
    return message.topic()


def main() -> int:
    bootstrap = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:19092,localhost:29092,localhost:39092")
    schema_registry_url = os.getenv("SCHEMA_REGISTRY_URL", "http://localhost:8081")

    schemas_dir = Path(__file__).resolve().parents[2] / "schemas" / "avro"
    order_status_schema = (schemas_dir / "OrderStatus.avsc").read_text(encoding="utf-8")
    fraud_alert_schema = (schemas_dir / "PaymentRequested.avsc").read_text(encoding="utf-8")

    schema_registry_client = SchemaRegistryClient({"url": schema_registry_url})
    status_deserializer = AvroDeserializer(schema_registry_client, order_status_schema)
    fraud_deserializer = AvroDeserializer(schema_registry_client, fraud_alert_schema)

    consumer = Consumer(
        {
            "bootstrap.servers": bootstrap,
            "group.id": "notifications-worker",
            "enable.auto.commit": False,
            "auto.offset.reset": "earliest",
            "isolation.level": "read_committed",
        }
    )

    dlq_producer = Producer({"bootstrap.servers": bootstrap})
    consumer.subscribe(PRIMARY_TOPICS + RETRY_TOPICS)

    signal.signal(signal.SIGINT, stop_handler)
    signal.signal(signal.SIGTERM, stop_handler)

    try:
        while RUNNING:
            message = consumer.poll(1.0)
            if message is None:
                continue
            if message.error():
                if message.error().code() == KafkaError._PARTITION_EOF:
                    continue
                print(f"consumer error: {message.error()}", file=sys.stderr)
                continue

            headers = decode_headers(message)
            retry_not_before = headers.get("x-not-before-epoch-ms")
            if retry_not_before and message.topic() in RETRY_TOPICS:
                now_ms = int(time.time() * 1000)
                wait_ms = int(retry_not_before) - now_ms
                if wait_ms > 0:
                    time.sleep(min(wait_ms / 1000.0, 1.0))
                    continue

            try:
                base_topic = resolve_base_topic(message, headers)
                if base_topic == "orders.v1.status":
                    deserializer = status_deserializer
                elif base_topic == "risk.v1.fraud_alerts":
                    deserializer = fraud_deserializer
                else:
                    raise ValueError(f"unsupported notification topic {base_topic}")

                record = deserializer(
                    message.value(),
                    SerializationContext(base_topic, MessageField.VALUE),
                )
                if record is None:
                    consumer.commit(message=message, asynchronous=False)
                    continue

                if base_topic == "orders.v1.status":
                    process_status_notification(record)
                else:
                    process_fraud_notification(record)

                consumer.commit(message=message, asynchronous=False)
            except Exception as ex:  # noqa: BLE001
                if not route_to_retry(dlq_producer, message, headers, str(ex)):
                    route_to_dlq(dlq_producer, message, headers, str(ex))
                consumer.commit(message=message, asynchronous=False)
    finally:
        consumer.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
