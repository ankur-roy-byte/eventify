FROM confluentinc/cp-kafka-connect:8.0.0

RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch
