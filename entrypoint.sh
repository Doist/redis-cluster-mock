#!/bin/sh -eu

PORT="7000"

/usr/local/bin/redis-server --daemonize yes --port $PORT \
    --loglevel warning \
    --cluster-enabled yes \
    --cluster-config-file nodes.conf \
    --cluster-node-timeout 5000 \
    --appendonly yes

while redis-cli -p $PORT ping 2>&1 | grep -v PONG
do
    echo "== Waiting for redis to start"
    sleep 3
done

REDIS_IP=$(hostname -i)
echo "== Create redis cluster"
redis-trib.py create $REDIS_IP:$PORT
echo "== Check cluster"
redis-trib.py list --addr $REDIS_IP:$PORT