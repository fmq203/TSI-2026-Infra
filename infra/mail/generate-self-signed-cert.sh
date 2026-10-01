#!/bin/sh
# docker-mailserver con SSL_TYPE=self-signed espera que el certificado YA exista en
# ./ssl/ montado — no lo genera solo. Correr esto UNA vez antes de levantar el stack
# (o después, y hacer `docker compose up -d --force-recreate`).
set -e
cd "$(dirname "$0")"

mkdir -p ssl/demoCA

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
  -keyout ssl/mail.lab.local-key.pem \
  -out ssl/mail.lab.local-cert.pem \
  -subj "/CN=mail.lab.local"

# Self-signed: el mismo cert actúa como su propia "CA" (lo que docker-mailserver espera
# encontrar en demoCA/cacert.pem para este SSL_TYPE).
cp ssl/mail.lab.local-cert.pem ssl/demoCA/cacert.pem

echo "Certs generados en ./ssl/ — ahora: docker compose up -d --force-recreate"
