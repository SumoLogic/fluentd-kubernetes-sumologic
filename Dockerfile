FROM fluent/fluentd:v0.12.34
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

USER root

RUN apk --no-cache --update add sudo build-base ruby-dev libffi-dev && \
    sudo -u fluent gem install fluent-plugin-record-reformer fluent-plugin-kubernetes_metadata_filter fluent-plugin-sumologic_output && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && sudo -u fluent gem sources -c && \
    apk del sudo build-base ruby-dev && rm -rf /var/cache/apk/*

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

COPY ./conf.d/* /fluentd/conf.d/
COPY ./etc/* /fluentd/etc/
COPY ./plugins/* /fluentd/plugins/

CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT