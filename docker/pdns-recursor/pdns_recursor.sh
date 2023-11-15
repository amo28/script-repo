#!/bin/bash

CONFIG_FILE="/etc/pdns-recursor/recursor.conf"

# named.root update
curl https://www.internic.net/domain/named.root -o "/etc/pdns-recursor/named.root"
HINT_FILE="hint-file=/etc/pdns-recursor/named.root"
sed -i "/hint-file=/c${HINT_FILE}" "${CONFIG_FILE}"

if [[ ${FORWARDZONES} ]] && [[ ${ALLOWFROM} ]]; then
    FORWARD_ZONES="forward-zones=${FORWARDZONES}"
    ALLOW_FROM="allow-from=${ALLOWFROM}"

    # recursor.conf updates
    sed -i "/forward-zones=/c${FORWARD_ZONES}" "${CONFIG_FILE}"
    sed -i "/allow-from=/c${ALLOW_FROM}" "${CONFIG_FILE}"
fi

# make required folders
mkdir -p /run/pdns-recursor
mkdir -p /var/lib/pdns-recursor/udr

# exec command
exec "$@"
