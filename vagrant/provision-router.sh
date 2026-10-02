#!/bin/bash
# Router Linux (nftables): alternativa automática a OPNsense para VirtualBox.
# Implementa los mismos flujos que docs/40-consigna-propia.md §2:
#   - Internet -> DMZ: solo puertos publicados (mail, wazo, honeypot)
#   - Usuarios -> Servidores: solo HTTP/HTTPS a la app de préstamos
#   - Servidores/Usuarios -> Gestión: solo agente Wazuh (1514/1515)
#   - Todo lo demás entre VLANs internas: denegado (MFA/Keycloak lo maneja a nivel
#     aplicación, esto es solo el filtrado de red)
set -ex
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y nftables

sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

iface_for_ip() {
  ip -4 -o addr show | awk -v pat="$1" '$0 ~ pat {print $2; exit}'
}

# "WAN" = vlan_wan (203.0.113.0/24), la red donde el Red Team suma su propia VM
# atacante — NO es la NIC de NAT que Vagrant usa para gestión/SSH (esa queda aparte,
# con acceso a internet real para que apt/docker funcionen durante el provisioning).
IF_WAN=$(iface_for_ip 203.0.113.254)
IF_SRV=$(iface_for_ip 10.10.10.254)
IF_DMZ=$(iface_for_ip 10.10.20.254)
IF_USR=$(iface_for_ip 10.10.30.254)
IF_MGMT=$(iface_for_ip 10.10.90.254)
# NIC de NAT de Vagrant (10.0.2.0/24): internet real. Se usa como salida para que los
# contenedores puedan bajar feeds/actualizaciones (ej. detector de vulnerabilidades de Wazuh).
IF_NAT=$(iface_for_ip 10.0.2.)

echo "Interfaces: WAN=$IF_WAN SRV=$IF_SRV DMZ=$IF_DMZ USR=$IF_USR MGMT=$IF_MGMT NAT=$IF_NAT"

cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain forward {
    type filter hook forward priority 0; policy drop;

    ct state established,related accept

    # Internet -> DMZ: solo los puertos publicados (mail, wazo, honeypot)
    iifname "$IF_WAN" oifname "$IF_DMZ" tcp dport { 25, 587, 993, 2222, 2223 } accept
    iifname "$IF_WAN" oifname "$IF_DMZ" udp dport { 5060 } accept

    # Cualquier VLAN interna -> "internet simulada" y -> internet real (NAT de Vagrant)
    iifname { "$IF_SRV", "$IF_DMZ", "$IF_USR", "$IF_MGMT" } oifname { "$IF_WAN", "$IF_NAT" } accept

    # Usuarios -> Servidores: solo HTTP/HTTPS a la app de préstamos
    iifname "$IF_USR" oifname "$IF_SRV" tcp dport { 80, 443 } accept

    # Servidores/Usuarios -> Gestión: solo agente Wazuh
    iifname { "$IF_SRV", "$IF_USR" } oifname "$IF_MGMT" tcp dport { 1514, 1515 } accept
    iifname { "$IF_SRV", "$IF_USR" } oifname "$IF_MGMT" udp dport { 1514 } accept

    # Resto de tráfico entre VLANs internas: denegado (política por defecto = drop)
  }

  chain postrouting {
    type nat hook postrouting priority 100;
    oifname { "$IF_WAN", "$IF_NAT" } masquerade
  }
}
EOF

nft -f /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

echo "Router listo. Reglas activas:"
nft list ruleset
