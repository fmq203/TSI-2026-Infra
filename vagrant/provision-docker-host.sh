#!/bin/bash
# Docker + todos los stacks, aplicando de entrada todo lo que ya debugueamos a mano en
# la versión Proxmox (ver ../brain/LEARNINGS.md): certs de mail, vm.max_map_count para
# Wazuh, create-networks.sh en vez de docker-compose.networks.yml.
set -ex
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl git

curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

# Requisito de OpenSearch (indexer de Wazuh)
sysctl -w vm.max_map_count=262144
grep -q '^vm.max_map_count' /etc/sysctl.conf || echo "vm.max_map_count=262144" >> /etc/sysctl.conf

cd /opt/TSI-2026-Infra/infra

# Esperar a que las 4 NICs de VLAN tengan IP (Vagrant a veces tarda un segundo más que
# el arranque del provisioner)
for i in $(seq 1 30); do
  ip -4 addr show | grep -q "10.10.90.5" && break
  sleep 2
done

chmod +x create-networks.sh
./create-networks.sh

# mail: generar certs self-signed si no existen (SSL_TYPE=self-signed no los genera solo)
if [ ! -f mail/ssl/mail.lab.local-cert.pem ]; then
  chmod +x mail/generate-self-signed-cert.sh
  (cd mail && ./generate-self-signed-cert.sh)
fi

# .env de cada stack que lo necesita (copiar el .example si todavía no existe)
for stack in identity siem-hids nids mail targets; do
  if [ -f "$stack/.env.example" ] && [ ! -f "$stack/.env" ]; then
    cp "$stack/.env.example" "$stack/.env"
  fi
done

# Levantar en orden (identity primero por MFA)
for stack in identity siem-hids nids mail honeypot targets; do
  (cd "$stack" && docker compose up -d)
done

echo ""
echo "===================================================================="
echo "Listo. Desde el host (tu máquina), para llegar a las VLANs internas"
echo "necesitás rutear a través del router (10.10.X.254) o acceder directo"
echo "si tu hipervisor expone las redes internas al host."
echo "  Wazuh dashboard:  https://10.10.90.12"
echo "  Keycloak:         revisar IP con: docker inspect keycloak | grep IPAddress"
echo "  App de préstamos: http://10.10.10.10"
echo "===================================================================="
