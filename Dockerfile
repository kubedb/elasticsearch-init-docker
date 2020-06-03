FROM debian:stretch as builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl unzip

RUN set -x                                                                                             \
  && curl -fsSL -o yq https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 \
  && chmod 755 yq

FROM busybox

RUN mkdir /usr/share/elasticsearch/plugins/opendistro_security/securityconfig
RUN mkdir /elasticsearch/temp-config
RUN mkdir /elasticsearch/custom-config

COPY securityconfig securityconfig
COPY --from=builder /yq /usr/bin/yq
COPY config-merger.sh /usr/bin/config-merger.sh

ENTRYPOINT ["/usr/bin/config-merger.sh"]