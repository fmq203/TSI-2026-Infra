#!/bin/sh
# Crea la casilla del SOC, donde Wazuh manda las alertas (siem-hids/configure-manager.sh).
# docker-mailserver no termina de arrancar sin al menos una cuenta. Idempotente.
set -e
cd "$(dirname "$0")"
[ -f .env ] && . ./.env
SOC_MAIL=${SOC_MAIL:-soc@lab.local}
SOC_MAIL_PASSWORD=${SOC_MAIL_PASSWORD:-changeme}   # .env viejos no tienen la variable

i=0
until docker exec mailserver setup email list >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -gt 24 ]; then echo "ERROR: mailserver no responde en 2 min" >&2; exit 1; fi
  sleep 5
done

if docker exec mailserver setup email list | grep -q "$SOC_MAIL"; then
  echo "La casilla $SOC_MAIL ya existe."
else
  docker exec mailserver setup email add "$SOC_MAIL" "$SOC_MAIL_PASSWORD"
  echo "Creada la casilla $SOC_MAIL (leer por IMAPS en 10.10.20.20:993)."
fi
