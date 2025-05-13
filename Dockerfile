FROM alpine:3.21

ARG BUILD_DATE
ARG VERSION="1.0"
ARG NGINX_VERSION="1.26.3-r0"

LABEL maintainer="HV Varona-Fong"
LABEL build_version="Tiny WebServer version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL org.opencontainers.image.authors="Humbero V. Varona-Fong <hvinlay.varona@gmail.com>"
LABEL org.opencontainers.image.description="Tiny WebServer"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

ENV TIMEZONE=UTC
ENV NGINX_WORKER_PROCESSES=1
ENV REDIRECT_TO_HTTPS=no
ENV AUTOCERT=no
ENV CERT_WARN_DAYS=30

RUN mkdir -p /config/www /config/data /config/ssl /config/warnings && chmod -R 755 /config

RUN apk add --no-cache \
    tzdata \
    unzip \
    mc \
    nano \
    curl \
    wget \
    sqlite \
    memcached \
    coreutils \
    nginx=${NGINX_VERSION} \
    nginx-mod-http-brotli=${NGINX_VERSION} \
    nginx-mod-http-dav-ext=${NGINX_VERSION} \
    nginx-mod-http-echo=${NGINX_VERSION} \
    nginx-mod-http-fancyindex=${NGINX_VERSION} \
    nginx-mod-http-geoip=${NGINX_VERSION} \
    nginx-mod-http-geoip2=${NGINX_VERSION} \
    nginx-mod-http-headers-more=${NGINX_VERSION} \
    nginx-mod-http-image-filter=${NGINX_VERSION} \
    nginx-mod-http-perl=${NGINX_VERSION} \
    nginx-mod-http-redis2=${NGINX_VERSION} \
    nginx-mod-http-set-misc=${NGINX_VERSION} \
    nginx-mod-http-upload-progress=${NGINX_VERSION} \
    nginx-mod-http-xslt-filter=${NGINX_VERSION} \
    nginx-mod-mail=${NGINX_VERSION} \
    nginx-mod-rtmp=${NGINX_VERSION} \
    nginx-mod-stream=${NGINX_VERSION} \
    nginx-mod-stream-geoip=${NGINX_VERSION} \
    nginx-mod-stream-geoip2=${NGINX_VERSION} \
    nginx-vim=${NGINX_VERSION} \
    && printf "Tiny WebServer version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version \
    && rm -f /etc/nginx/conf.d/stream.conf \
    && rm -rf /var/cache/apk/* /tmp/*

COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80 443
VOLUME /config

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -k -s -L -o /dev/null -w "%{http_code}" http://127.0.0.1 | grep -qE "200|301|302|403|404"

ENTRYPOINT ["/init.sh"]
