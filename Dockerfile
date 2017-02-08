FROM 3dsim/fluentd:v0.12-debian
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH

USER root

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
            ca-certificates \
            ruby \
 && buildDeps=" \
      make gcc g++ libc-dev \
      ruby-dev libffi-dev sudo\
    " \
 && apt-get install -y --no-install-recommends $buildDeps \
 && update-ca-certificates

RUN sudo -u fluent gem install fluent-plugin-record-reformer fluent-plugin-kubernetes_metadata_filter fluent-plugin-sumologic_output && \
    rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem && sudo -u fluent gem sources -c

# Cleanup
RUN apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem


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

COPY ./conf.d/* /fluentd/conf.d/
COPY ./etc/* /fluentd/etc/
COPY ./plugins/* /fluentd/plugins/

CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT
