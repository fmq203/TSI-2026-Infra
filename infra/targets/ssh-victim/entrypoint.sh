#!/bin/sh
# Arranca rsyslog, sshd y el agente Wazuh. El agente se enrola solo contra el manager
# (auto-enrollment por 1515) la primera vez que arranca; el nombre del agente es el
# hostname del contenedor (docker-compose.yml: hostname: ssh-client).
set -e

: "${SSH_USER:=labuser}"
: "${SSH_PASSWORD:?falta SSH_PASSWORD}"
: "${WAZUH_MANAGER:=10.10.90.10}"

id "$SSH_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$SSH_USER"
echo "$SSH_USER:$SSH_PASSWORD" | chpasswd

sed -i "s|<address>.*</address>|<address>$WAZUH_MANAGER</address>|" /var/ossec/etc/ossec.conf

rm -f /run/rsyslogd.pid
rsyslogd
mkdir -p /run/sshd
ssh-keygen -A >/dev/null
/usr/sbin/sshd

/var/ossec/bin/wazuh-control start || echo "AVISO: el agente Wazuh no arrancó (¿manager inalcanzable?)"

# Proceso en primer plano: el log del agente (enrolamiento, active response).
touch /var/ossec/logs/ossec.log /var/ossec/logs/active-responses.log
exec tail -F /var/ossec/logs/ossec.log /var/ossec/logs/active-responses.log
