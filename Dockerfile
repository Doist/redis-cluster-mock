# syntax = docker/dockerfile:1
FROM redis:5-alpine
# hadolint ignore=DL3018,DL3028
RUN apk --no-cache --update add runit ruby \
    && gem install redis && mkdir -p /etc/service

COPY /entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["redis-cluster"]