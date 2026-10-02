#!/bin/sh
# Crea las 4 redes macvlan compartidas. `docker compose -f docker-compose.networks.yml up`
# NO sirve para esto: Compose no crea redes/volúmenes declarados si el archivo no tiene
# ningún `service` que los use — confirmado 2026-10-01 (quedaba "no service selected" y
# ninguna red se creaba). docker-compose.networks.yml queda solo como referencia legible
# de la config; esto es lo que efectivamente hay que correr, una sola vez.
#
# Detecta la interfaz física de cada VLAN por su IP (no asume eth0/eth1/eth2/eth3) —
# funciona igual en docker-host sobre Proxmox (LXC) que en la reproducción portable con
# Vagrant/VirtualBox (ver ../vagrant/), donde los nombres de NIC pueden salir distintos
# (enp0sX, etc.).
set -e

iface_for_ip() {
  ip -4 -o addr show | awk -v pat="$1" '$0 ~ pat {print $2; exit}'
}

IF_SRV=$(iface_for_ip 10.10.10.5)
IF_DMZ=$(iface_for_ip 10.10.20.5)
IF_USR=$(iface_for_ip 10.10.30.5)
IF_MGMT=$(iface_for_ip 10.10.90.5)

for pair in "Servidores:$IF_SRV" "DMZ:$IF_DMZ" "Usuarios:$IF_USR" "Gestión:$IF_MGMT"; do
  name="${pair%%:*}"; val="${pair#*:}"
  if [ -z "$val" ]; then
    echo "ERROR: no encontré la interfaz de $name (buscando la IP .5 de docker-host en esa VLAN). ¿Están las 4 NICs configuradas?" >&2
    exit 1
  fi
done

docker network create -d macvlan \
  --subnet=10.10.10.0/24 --gateway=10.10.10.254 \
  -o parent="$IF_SRV" net_srv

docker network create -d macvlan \
  --subnet=10.10.20.0/24 --gateway=10.10.20.254 \
  -o parent="$IF_DMZ" net_dmz

docker network create -d macvlan \
  --subnet=10.10.30.0/24 --gateway=10.10.30.254 \
  -o parent="$IF_USR" net_usr

docker network create -d macvlan \
  --subnet=10.10.90.0/24 --gateway=10.10.90.254 \
  -o parent="$IF_MGMT" net_mgmt

docker network ls | grep net_
