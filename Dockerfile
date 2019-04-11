FROM fluent/fluentd:v1.3.2-debian AS builder

ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

COPY ./fluent-plugin-kubernetes_sumologic*.gem ./

# New fluent image dynamically creates user in entrypoint
RUN [ -f /bin/entrypoint.sh ] && /bin/entrypoint.sh echo || : && \
    apt-get update && \
    apt-get install -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    gem install fluent-plugin-s3 -v 1.1.4 && \
    gem install fluent-plugin-systemd -v 0.3.1 && \
    gem install fluent-plugin-record-reformer -v 0.9.1 && \
    gem install fluent-plugin-kubernetes_metadata_filter -v 1.0.2 && \
    gem install fluent-plugin-sumologic_output -v 1.4.0 && \
    gem install fluent-plugin-concat -v 2.3.0 && \
    gem install fluent-plugin-rewrite-tag-filter -v 2.1.0 && \
    gem install fluent-plugin-prometheus -v 1.1.0 && \
    gem install fluent-plugin-kubernetes_sumologic && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && \
    gem sources -c && \
    apt-get remove --purge -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    rm -rf /var/lib/apt/lists/*

FROM fluent/fluentd:v1.3.2-debian

WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

RUN mkdir -p /mnt/pos
EXPOSE 24284

RUN mkdir -p /fluentd/etc && \
    mkdir -p /fluentd/plugins

# Default settings
ENV LOG_FORMAT "json"
ENV FLUSH_INTERVAL "5s"
ENV NUM_THREADS "1"
ENV SOURCE_CATEGORY "%{namespace}/%{pod_name}"
ENV SOURCE_CATEGORY_PREFIX "kubernetes/"
ENV SOURCE_CATEGORY_REPLACE_DASH "/"
ENV SOURCE_NAME "%{namespace}.%{pod}.%{container}"
ENV KUBERNETES_META "true"
ENV KUBERNETES_META_REDUCE "false"
ENV READ_FROM_HEAD "true"
ENV FLUENTD_SOURCE "file"
ENV FLUENTD_USER_CONFIG_DIR "/fluentd/conf.d/user"
ENV MULTILINE_START_REGEXP "/^\w{3} \d{1,2}, \d{4}/"
ENV CONCAT_SEPARATOR ""
ENV AUDIT_LOG_PATH "/mnt/log/kube-apiserver-audit.log"
ENV TIME_KEY "time"
ENV ADD_TIMESTAMP "true"
ENV TIMESTAMP_KEY "timestamp"
ENV ADD_STREAM "true"
ENV ADD_TIME "true"
ENV CONTAINER_LOGS_PATH "/mnt/log/containers/*.log"
ENV ENABLE_STAT_WATCHER "true"
ENV K8S_METADATA_FILTER_WATCH "true"
ENV K8S_METADATA_FILTER_VERIFY_SSL "true"
ENV K8S_METADATA_FILTER_BEARER_CACHE_SIZE "1000"
ENV K8S_METADATA_FILTER_BEARER_CACHE_TTL "3600"
ENV VERIFY_SSL "true"
ENV FORWARD_INPUT_BIND "0.0.0.0"
ENV FORWARD_INPUT_PORT "24224"

COPY --from=builder /var/lib/gems /var/lib/gems
COPY ./entrypoint.sh /fluentd/

ENTRYPOINT ["/fluentd/entrypoint.sh"]
