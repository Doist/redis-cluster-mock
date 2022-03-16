#!/bin/sh -ex

if [ "$1" = 'redis-cluster' ]; then
    # Allow passing in cluster IP by argument or environmental variable
    IP="${2:-$IP}"

    if [ -z "$IP" ]; then # If IP is unset then discover it
        IP=$(hostname -i)
    fi

    if [ -z "${INITIAL_PORT}" ]; then # Default to port 7000
        INITIAL_PORT=7000
    fi

    if [ -z "$MASTERS" ]; then # Default to 3 masters
        MASTERS=3
    fi

    if [ -z "$SLAVES_PER_MASTER" ]; then # Default to 1 slave for each master
        SLAVES_PER_MASTER=1
    fi

    if [ -z "$BIND_ADDRESS" ]; then # Default to any IPv4 address
        BIND_ADDRESS=0.0.0.0
    fi

    max_port=$((INITIAL_PORT + MASTERS * (SLAVES_PER_MASTER + 1) - 1))

    first_standalone=$((max_port + 1))
    if [ "$STANDALONE" = "true" ]; then
        STANDALONE=2
    fi
    if [ -n "$STANDALONE" ]; then
        max_port=$((max_port + STANDALONE))
    fi

    for port in $(seq $INITIAL_PORT $max_port); do
        mkdir -p "/redis-conf/${port}" "/redis-data/${port}" "/etc/sv/${port}"

        if [ -e "/redis-data/${port}/nodes.conf" ]; then
            rm "/redis-data/${port}/nodes.conf"
        fi

        if [ -e "/redis-data/${port}/dump.rdb" ]; then
            rm "/redis-data/${port}/dump.rdb"
        fi

        if [ -e "/redis-data/${port}/appendonly.aof" ]; then
            rm "/redis-data/${port}/appendonly.aof"
        fi

        if [ "$port" -lt "$first_standalone" ]; then
            cat >"/redis-conf/${port}/redis.conf" <<EOF
bind ${BIND_ADDRESS}
port ${port}
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
dir /redis-data/${port}
EOF
            nodes="$nodes $IP:$port"
        else
            cat >"/redis-conf/${port}/redis.conf" <<EOF
bind ${BIND_ADDRESS}
port ${port}
appendonly yes
dir /redis-data/${port}
EOF
        fi

        cat >"/etc/sv/${port}/run" <<EOF
#!/bin/sh -eu
exec 2>&1
exec /usr/local/bin/redis-server /redis-conf/${port}/redis.conf
EOF

        chmod +x "/etc/sv/${port}/run"
        ln -svf "/etc/sv/${port}" /etc/service/
    done

    (
        sleep 5
        echo "yes" | eval /redis/src/redis-cli --cluster create --cluster-replicas "$SLAVES_PER_MASTER" "$nodes"
    ) &

    exec /sbin/runsvdir -P /etc/service

else

    exec "$@"
fi
