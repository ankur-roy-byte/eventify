COMPOSE_FILE=infra/compose/docker-compose.yml
ENV_FILE=$(if $(wildcard infra/compose/.env.local),infra/compose/.env.local,infra/compose/.env)
COMPOSE=docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)

.PHONY: up down dr-up up-separated up-tls up-sasl scram-users acls topics schemas-compat schemas connectors ksqldb run-orders-api run-payments run-inventory run-streams run-notifications run-telemetry lag validate demo

up:
	$(COMPOSE) up -d kafka1 kafka2 kafka3 schema-registry postgres connect opensearch ksqldb-server kafka-exporter jmx-kafka1 jmx-kafka2 jmx-kafka3 prometheus grafana kafka-ui

down:
	$(COMPOSE) down -v

dr-up:
	$(COMPOSE) --profile dr up -d dr-kafka1 mirror-maker2

up-separated:
	docker compose -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.separated-controllers.yml --env-file infra/compose/.env --profile separated up -d

up-tls:
	docker compose -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.stage-a-tls.yml --env-file infra/compose/.env up -d

up-sasl:
	docker compose -f infra/compose/docker-compose.yml -f infra/compose/docker-compose.stage-a-tls.yml -f infra/compose/docker-compose.stage-b-sasl-acl.yml --env-file infra/compose/.env up -d

scram-users:
	bash infra/compose/scripts/create-scram-users.sh

acls:
	bash infra/compose/scripts/create-acls.sh

topics:
	bash infra/compose/scripts/create-topics.sh

schemas-compat:
	bash infra/compose/scripts/set-schema-compatibility.sh

schemas:
	bash infra/compose/scripts/register-schemas.sh

connectors:
	bash infra/compose/scripts/apply-connectors.sh

ksqldb:
	curl -sS -X POST http://localhost:8088/ksql \
	  -H 'Content-Type: application/vnd.ksql.v1+json; charset=utf-8' \
	  -d "{\"ksql\":\"$$(cat ksqldb/001_create_streams.sql)\",\"streamsProperties\":{}}"
	curl -sS -X POST http://localhost:8088/ksql \
	  -H 'Content-Type: application/vnd.ksql.v1+json; charset=utf-8' \
	  -d "{\"ksql\":\"$$(cat ksqldb/002_metrics.sql)\",\"streamsProperties\":{}}"

run-orders-api:
	mvn -f services/orders-api/pom.xml spring-boot:run

run-payments:
	mvn -f services/payments-worker/pom.xml compile exec:java -Dexec.mainClass=com.example.payments.PaymentsWorkerApplication

run-inventory:
	mvn -f services/inventory-worker/pom.xml compile exec:java -Dexec.mainClass=com.example.inventory.InventoryWorkerApplication

run-streams:
	mvn -f services/streams-order-status/pom.xml compile exec:java -Dexec.mainClass=com.example.streams.OrderStatusStreamsApplication

run-notifications:
	pip install -r services/notifications-worker/requirements.txt
	python services/notifications-worker/app.py

run-telemetry:
	mvn -f services/payments-worker/pom.xml compile exec:java -Dexec.mainClass=com.example.payments.TelemetryProducerApplication

lag:
	$(COMPOSE) exec -T kafka1 kafka-consumer-groups --bootstrap-server kafka1:9092 --describe --group notifications-worker

validate:
	mvn -q -f services/orders-api/pom.xml -DskipTests compile
	mvn -q -f services/payments-worker/pom.xml -DskipTests compile
	mvn -q -f services/inventory-worker/pom.xml -DskipTests compile
	mvn -q -f services/streams-order-status/pom.xml -DskipTests compile
	python -m py_compile services/notifications-worker/app.py

demo:
	$(MAKE) up
	$(MAKE) topics
	$(MAKE) schemas-compat
	$(MAKE) schemas
	$(MAKE) connectors
	$(MAKE) ksqldb
	@echo "Start service processes in separate terminals with run-* targets."
