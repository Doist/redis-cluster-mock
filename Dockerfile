FROM redis:5-alpine AS builder
RUN apk --no-cache --update add \
    build-base gcc \
    python3 python3-dev py3-pip py3-virtualenv \
    && pip install --ignore-installed six redis-trib

ENV VENV /app/venv
ENV PATH $VENV/bin:$PATH

RUN python3 -m virtualenv $VENV \
    && pip3 --no-cache install --ignore-installed six redis-trib

FROM redis:5-alpine AS runtime
RUN apk --no-cache --update add runit python3

ARG PORTS=7000

ENV VENV /app/venv
ENV PATH $VENV/bin:$PATH
ENV PORT ${PORT}

COPY --from=builder $VENV $VENV

COPY /entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]