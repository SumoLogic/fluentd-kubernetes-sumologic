FROM fluent/fluentd:debian
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

USER root

RUN apt-get update && apt-get install -y sudo build-essential ruby-dev libffi-dev && \
    gem install fluent-plugin-record-reformer fluent-plugin-kubernetes_metadata_filter fluent-plugin-sumologic_output fluent-plugin-gcloud-pubsub-custom && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && gem sources -c

    #  && \
    # apk del sudo build-base ruby-dev && rm -rf /var/cache/apk/*

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

ENTRYPOINT []

CMD fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT