FROM alpine:3.3

EXPOSE 80

RUN apk add --update nginx-lua lua5.1-curl lua5.1-cjson lua5.1-inspect  && \
    mkdir -p /tmp/nginx/client-body && \
    rm -rf /var/cache/apk/*

COPY . /

CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-p", "/app", "-c", "/nginx.conf"]
