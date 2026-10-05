#!/bin/sh
# Configura el manager de Wazuh para la cadena detección → respuesta → notificación.
# Idempotente: se puede correr las veces que haga falta (`make up` lo corre). Reinicia el
# manager solo si cambió algo.
#
#   1. Lee el eve.json de Suricata (CU-01).
#   2. Reglas locales (config/wazuh_manager/local_rules.xml): CU-01 a nivel 10.
#   3. Active Response (CU-02): fuerza bruta SSH → firewall-drop en el agente víctima.
#   4. Mail de alertas nivel >= 10 al SOC, vía el mailserver de la DMZ.
set -e
cd "$(dirname "$0")"

C=wazuh.manager
CONF=/var/ossec/etc/ossec.conf
SURICATA_LOG=/var/log/suricata/eve.json
SMTP_SERVER=${SMTP_SERVER:-10.10.20.20}
EMAIL_TO=${EMAIL_TO:-soc@lab.local}
EMAIL_FROM=${EMAIL_FROM:-wazuh@lab.local}
CHANGED=0

# Esperar a que el manager haya terminado de inicializar (la primera vez copia la config
# por defecto al volumen; si escribimos antes, se pierde).
i=0
until docker exec $C /var/ossec/bin/wazuh-control status 2>/dev/null | grep -q 'wazuh-logcollector is running'; do
  i=$((i+1))
  if [ "$i" -gt 60 ]; then echo "ERROR: el manager no terminó de arrancar en 5 min" >&2; exit 1; fi
  sleep 5
done

# ossec.conf admite varios bloques <ossec_config>: cada pieza se agrega como un bloque
# nuevo al final, marcado con un comentario para no duplicarla.
append_block() {  # $1 = marca, resto = líneas del bloque
  mark=$1; shift
  if docker exec $C grep -q "$mark" $CONF; then return 0; fi
  docker exec $C sh -c "printf '%s\n' '<!-- tsi: $mark -->' '<ossec_config>' $(printf "'%s' " "$@") '</ossec_config>' >> $CONF"
  echo "agregado a ossec.conf: $mark"
  CHANGED=1
}

# 1. Suricata
# (marca = la ruta del eve.json: así reconoce también el bloque que agregaba la versión
# anterior de este script, enable-suricata-logs.sh)
append_block "$SURICATA_LOG" \
  '  <localfile>' \
  '    <log_format>json</log_format>' \
  "    <location>$SURICATA_LOG</location>" \
  '  </localfile>'

# 3. Active Response: 5712 = fuerza bruta con usuarios inexistentes, 5763 = fuerza bruta
#    con fallos de autenticación (ambas nivel 10, reglas estándar de sshd). firewall-drop
#    ya viene definido como <command> en el ossec.conf por defecto del manager.
append_block "active-response-cu02" \
  '  <active-response>' \
  '    <command>firewall-drop</command>' \
  '    <location>local</location>' \
  '    <rules_id>5712,5763</rules_id>' \
  '    <timeout>600</timeout>' \
  '  </active-response>'

# 4. Mail: se editan los valores que ya trae el <global> por defecto.
before=$(docker exec $C md5sum $CONF)
docker exec $C sed -i \
  -e "s|<email_notification>no</email_notification>|<email_notification>yes</email_notification>|" \
  -e "s|<smtp_server>[^<]*</smtp_server>|<smtp_server>$SMTP_SERVER</smtp_server>|" \
  -e "s|<email_from>[^<]*</email_from>|<email_from>$EMAIL_FROM</email_from>|" \
  -e "s|<email_to>[^<]*</email_to>|<email_to>$EMAIL_TO</email_to>|" \
  -e "s|<email_alert_level>[0-9]*</email_alert_level>|<email_alert_level>10</email_alert_level>|" \
  $CONF
[ "$before" = "$(docker exec $C md5sum $CONF)" ] || { echo "actualizada la config de mail"; CHANGED=1; }

# 2. Reglas locales
RULES=/var/ossec/etc/rules/local_rules.xml
want=$(md5sum < config/wazuh_manager/local_rules.xml | cut -d' ' -f1)
have=$(docker exec $C sh -c "md5sum < $RULES" | cut -d' ' -f1)
if [ "$want" != "$have" ]; then
  docker cp config/wazuh_manager/local_rules.xml $C:$RULES
  docker exec $C chown wazuh:wazuh $RULES
  echo "actualizado local_rules.xml"
  CHANGED=1
fi

if [ "$CHANGED" = 1 ]; then
  # Validar antes de reiniciar: con una regla o un XML roto el manager no levanta.
  docker exec $C /var/ossec/bin/wazuh-analysisd -t
  docker exec $C /var/ossec/bin/wazuh-control restart
  echo "Listo: manager reconfigurado y reiniciado."
else
  echo "El manager ya estaba configurado, no se toca nada."
fi
