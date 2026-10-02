#!/bin/bash
# Instala Docker, clona el repo y levanta todos los stacks con `make up` (que ya aplica
# los prerequisitos: redes macvlan, certs de mail, vm.max_map_count de Wazuh, .env).
set -ex
export DEBIAN_FRONTEND=noninteractive

REPO_URL="${REPO_URL:-https://github.com/fmq203/TSI-2026-Infra.git}"
REPO_DIR=/opt/TSI-2026-Infra

apt-get update
apt-get install -y ca-certificates curl git make openssl

if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

# Persistir el sysctl de OpenSearch (make up lo aplica en caliente, esto sobrevive reinicios)
grep -q '^vm.max_map_count' /etc/sysctl.conf || echo "vm.max_map_count=262144" >> /etc/sysctl.conf

if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$REPO_DIR"
fi

# Esperar a que las 4 NICs de VLAN tengan IP (a veces tardan un poco más que el provisioner)
for i in $(seq 1 30); do
  ip -4 addr show | grep -q "10.10.90.5/" && break
  sleep 2
done

cd "$REPO_DIR/infra"
chmod +x create-networks.sh mail/generate-self-signed-cert.sh
make up

cat <<'EOF'

====================================================================
Listo. Las VLANs son redes internas de VirtualBox: NO se ven desde tu
máquina. Para abrir las consolas en tu navegador, desde la carpeta vagrant/:

  vagrant ssh router -- -N \
    -L 5601:10.10.90.12:5601 \
    -L 8080:10.10.90.20:8080 \
    -L 8081:10.10.10.10:80

  Wazuh dashboard   http://localhost:5601   (tarda ~1 min en levantar)
  Keycloak          http://localhost:8080
  App (DVWA)        http://localhost:8081

Ver vagrant/README.md para el resto.
====================================================================
EOF
