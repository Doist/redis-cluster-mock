#!/bin/sh -eu

PORTS="7000 7001 7002 7003 7004 7005"

mkdir -p /etc/service /etc/redis

for PORT in $PORTS; do
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
done

(
    REDIS_IP=$(hostname -i)
    sleep 3 && redis-cli --cluster create \
        $REDIS_IP:7000 $REDIS_IP:7001 $REDIS_IP:7002 \
        $REDIS_IP:7003 $REDIS_IP:7004 $REDIS_IP:7005 \
      --cluster-replicas 1 --cluster-yes;
) &

exec /sbin/runsvdir -P /etc/service