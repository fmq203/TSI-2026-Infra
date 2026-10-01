#!/bin/sh
# Crea las 4 redes macvlan compartidas. `docker compose -f docker-compose.networks.yml up`
# NO sirve para esto: Compose no crea redes/volúmenes declarados si el archivo no tiene
# ningún `service` que los use — confirmado 2026-10-01 (quedaba "no service selected" y
# ninguna red se creaba). docker-compose.networks.yml queda solo como referencia legible
# de la config; esto es lo que efectivamente hay que correr, una sola vez.
set -e

docker network create -d macvlan \
  --subnet=10.10.10.0/24 --gateway=10.10.10.254 \
  -o parent=eth0 net_srv

docker network create -d macvlan \
  --subnet=10.10.20.0/24 --gateway=10.10.20.254 \
  -o parent=eth1 net_dmz

docker network create -d macvlan \
  --subnet=10.10.30.0/24 --gateway=10.10.30.254 \
  -o parent=eth2 net_usr

docker network create -d macvlan \
  --subnet=10.10.90.0/24 --gateway=10.10.90.254 \
  -o parent=eth3 net_mgmt

docker network ls | grep net_
