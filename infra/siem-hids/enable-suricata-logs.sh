#!/bin/sh
# Hace que el manager de Wazuh lea el eve.json de Suricata (montado en /var/log/suricata
# por docker-compose.yml). Wazuh ya trae decoder JSON y reglas para Suricata (grupo
# "suricata"), así que las alertas aparecen solas en el dashboard. Idempotente: se puede
# correr las veces que haga falta (`make up` lo corre).
set -e

CONF=/var/ossec/etc/ossec.conf
MARK=/var/log/suricata/eve.json

# Esperar a que el manager haya terminado de inicializar (la primera vez copia la config
# por defecto al volumen; si escribimos antes, se pierde).
i=0
until docker exec wazuh.manager /var/ossec/bin/wazuh-control status 2>/dev/null | grep -q 'wazuh-logcollector is running'; do
  i=$((i+1))
  if [ "$i" -gt 60 ]; then echo "ERROR: el manager no terminó de arrancar en 5 min" >&2; exit 1; fi
  sleep 5
done

if docker exec wazuh.manager grep -q "$MARK" "$CONF"; then
  echo "Wazuh ya lee $MARK, no se toca nada."
  exit 0
fi

# ossec.conf admite varios bloques <ossec_config>: se agrega uno nuevo al final.
docker exec wazuh.manager sh -c "printf '%s\n' \
  '<ossec_config>' \
  '  <localfile>' \
  '    <log_format>json</log_format>' \
  '    <location>$MARK</location>' \
  '  </localfile>' \
  '</ossec_config>' >> $CONF"

docker exec wazuh.manager /var/ossec/bin/wazuh-control restart
echo "Listo: Wazuh lee $MARK (alertas de Suricata con rule.groups: suricata)."
