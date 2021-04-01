FROM redis:5-alpine
RUN apk --no-cache --update add runit ruby \
    && gem install redis
COPY /entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]