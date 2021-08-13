#!/bin/sh -eu

PORT="7000"

mkdir -p /etc/service /etc/redis

if [ ! -d /etc/sv/$PORT ]; then
    mkdir -p /etc/sv/$PORT

cat >"/etc/sv/$PORT/run" <<EOF
#!/bin/sh -eu
exec 2>&1
exec /usr/local/bin/redis-server /etc/redis/$PORT.conf
EOF

cat > "/etc/redis/$PORT.conf" <<EOF
daemonize no
port $PORT
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
EOF
    chmod +x /etc/sv/$PORT/run
    ln -svf /etc/sv/$PORT /etc/service/
fi

(
    REDIS_IP=$(hostname -i)
    while redis-cli -p "$PORT" ping 2>&1 | grep -v PONG
    do
        echo "== Waiting for redis to start"
        sleep 1
    done
    if redis-trib.py list --addr "$REDIS_IP:$PORT" 2>&1 | grep -vc 'myself,master'; then
        echo "== Create redis cluster"
        redis-trib.py create "$REDIS_IP:$PORT"
        echo "== Check cluster"
        redis-trib.py list --addr "$REDIS_IP:$PORT"
    fi
) &

exec /sbin/runsvdir -P /etc/service
