#!/bin/bash

read INPUT

COMMAND=$(printf '%s' "$INPUT" | sed -n 's/.*"command":"\([^"]*\)".*/\1/p')

MANAGER_IP="10.10.90.10"
GATEWAY="10.10.10.254"
INTERFACE="eth0"
LOG="/var/ossec/logs/active-responses.log"

case "$COMMAND" in
  add)
    echo "$(date -u) CU03 isolate-webapp: Starting isolation" >> "$LOG"

    /sbin/ip route replace ${MANAGER_IP}/32 \
      via ${GATEWAY} dev ${INTERFACE}

    /sbin/ip route del default 2>/dev/null || true

    echo "$(date -u) CU03 isolate-webapp: Webapp isolated, Wazuh access preserved" >> "$LOG"
    ;;

  delete)
    echo "$(date -u) CU03 isolate-webapp: Restoring connectivity" >> "$LOG"

    /sbin/ip route replace default \
      via ${GATEWAY} dev ${INTERFACE}

    /sbin/ip route del ${MANAGER_IP}/32 2>/dev/null || true

    echo "$(date -u) CU03 isolate-webapp: Connectivity restored" >> "$LOG"
    ;;
esac

exit 0
