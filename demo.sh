#!/bin/bash


docker-compose up -d cassandra pulsar

docker logs cassandra
docker exec -it cassandra cqlsh -e "CREATE KEYSPACE ks1 WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'};"
docker exec -it cassandra cqlsh -e "CREATE TABLE ks1.table1 (a text, b text, PRIMARY KEY (a)) WITH cdc=true;"
docker exec -it cassandra cqlsh -e "SELECT * FROM ks1.table1;"

docker logs pulsar

docker exec -it pulsar bin/pulsar-admin source create \
    --source-type cassandra-source \
    --tenant public \
    --namespace default \
    --name cassandra-source-ks1-table1 \
    --destination-topic-name data-ks1.table1 \
    --source-config "{
      \"keyspace\": \"ks1\",
      \"table\": \"table1\",
      \"events.topic\": \"persistent://public/default/events-ks1.table1\",
      \"events.subscription.name\": \"sub1\",
      \"contactPoints\": \"cassandra\",
      \"loadBalancing.localDc\": \"datacenter1\"
    }"


docker exec -it pulsar bin/pulsar-admin source status --name cassandra-source-ks1-table1
docker exec -it pulsar cat /pulsar/logs/functions/public/default/cassandra-source-ks1-table1/cassandra-source-ks1-table1-0.log


docker exec -it cassandra cqlsh -e "INSERT INTO ks1.table1(a,b) VALUES('mykey','bvalue');"
docker exec -it cassandra cqlsh -e "SELECT count(*) FROM ks1.table1;"
docker exec -it cassandra cassandra-stress user profile=/table1.yaml no-warmup ops\(insert=1\) n=1000000 -rate threads=10

docker exec -it pulsar bin/pulsar-admin topics stats persistent://public/default/events-ks1.table1
docker exec -it pulsar bin/pulsar-admin topics stats persistent://public/default/data-ks1.table1

docker exec -it pulsar bin/pulsar-client consume -st auto_consume -s from-cli persistent://public/default/data-ks1.table1

docker exec -it cassandra cqlsh -e "SELECT * FROM ks1.table1;"

docker-compose up -d prometheus grafana

http://localhost:9090
http://localhost:3000