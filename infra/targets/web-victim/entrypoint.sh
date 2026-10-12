#!/bin/bash
set -e

MANAGER_IP="${WAZUH_MANAGER:-10.10.90.10}"
AGENT_NAME="${WAZUH_AGENT_NAME:-webapp}"

echo "[CU-03] Configurando agente Wazuh..."

sed -i "s/MANAGER_IP/${MANAGER_IP}/g" /var/ossec/etc/ossec.conf

if ! grep -q "/var/www/html" /var/ossec/etc/ossec.conf; then
  sed -i '/<syscheck>/a \
    <directories realtime="yes" check_all="yes">/var/www/html</directories>' \
    /var/ossec/etc/ossec.conf
fi

if [ ! -s /var/ossec/etc/client.keys ]; then
  echo "[CU-03] Enrolando agente ${AGENT_NAME}..."
  /var/ossec/bin/agent-auth \
    -m "${MANAGER_IP}" \
    -A "${AGENT_NAME}"
fi

/var/ossec/bin/wazuh-control start

echo "[CU-03] Wazuh iniciado. Arrancando DVWA..."

exec /main.sh
