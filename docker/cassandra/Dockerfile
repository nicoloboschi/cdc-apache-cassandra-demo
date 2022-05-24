FROM cassandra:4.0.3

RUN sed -i 's/cdc_enabled: false/cdc_enabled: true/g' /etc/cassandra/cassandra.yaml
RUN sed -i "s/commitlog_sync_period_in_ms: 10000/commitlog_sync_period_in_ms: 2000/g" /etc/cassandra/cassandra.yaml
RUN echo "cdc_total_space_in_mb: 128" >> /etc/cassandra/cassandra.yaml

RUN (cd / && curl -L https://github.com/datastax/cdc-apache-cassandra/releases/download/v2.0.0/agent-c4-2.0.0-all.jar --output agent-c4-2.0.0-all.jar)

# Add cassandra-stress config
COPY table1.yaml /

# Add the prometheus exporter
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.16.1/jmx_prometheus_javaagent-0.16.1.jar /
RUN chmod a+rx /jmx_prometheus_javaagent-0.16.1.jar
COPY jmx_prometheus_exporter.yaml /

# Add cassandra tools in the PATH
ENV PATH="${PATH}:/opt/cassandra/tools/bin"
