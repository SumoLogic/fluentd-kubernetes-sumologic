FROM fluent/fluentd:v0.14.17-debian
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

USER root

# New fluent image dynamically creates user in entrypoint
RUN [ -f /bin/entrypoint.sh ] && /bin/entrypoint.sh echo || : && \
    apt-get update && \
    apt-get install -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    gem install fluent-plugin-systemd fluent-plugin-record-reformer fluent-plugin-kubernetes_metadata_filter fluent-plugin-sumologic_output fluent-plugin-concat && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && \
    gem sources -c && \
    apt-get remove --purge -y build-essential ruby-dev libffi-dev libsystemd-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /mnt/pos
EXPOSE 24284

RUN mkdir -p /fluentd/conf.d && \
    mkdir -p /fluentd/etc && \
    mkdir -p /fluentd/plugins

# Default settings
ENV LOG_FORMAT "json"
ENV FLUSH_INTERVAL "30s"
ENV NUM_THREADS "1"
ENV SOURCE_CATEGORY "%{namespace}/%{pod_name}"
ENV SOURCE_CATEGORY_PREFIX "kubernetes/"
ENV SOURCE_CATEGORY_REPLACE_DASH "/"
ENV SOURCE_NAME "%{namespace}.%{pod}.%{container}"
ENV KUBERNETES_META "true"
ENV READ_FROM_HEAD "true"
ENV FLUENTD_SOURCE "file"
ENV FLUENTD_USER_CONFIG_DIR "/fluentd/conf.d/user"
ENV MULTILINE_START_REGEXP "/^\w{3} \d{1,2}, \d{4}/"
ENV CONCAT_SEPARATOR ""
ENV AUDIT_LOG_PATH "/mnt/log/kube-apiserver-audit.log"

COPY ./conf.d/ /fluentd/conf.d/
COPY ./etc/* /fluentd/etc/
COPY ./plugins/* /fluentd/plugins/
COPY ./entrypoint.sh /fluentd/

ENTRYPOINT ["/fluentd/entrypoint.sh"]
