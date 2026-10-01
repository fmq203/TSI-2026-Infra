---
title: Decisiones — Tarea 3
tags: [tarea3, decisiones, arquitectura]
updated: 2026-10-01
---

# Decisiones — Tarea 3

Log cronológico. Formato: fecha — decisión. Motivo. Alternativas descartadas. Fuente.
No se reescribe el pasado: si una decisión cambia, se agrega una entrada nueva que
referencia la anterior.

- **2026-09-14** — Solo 2 piezas de la infraestructura van en VM (no en Docker):
  `router-fw` y `docker-host`. Todo el resto (SIEM, HIDS, NIDS, SOAR, honeypot, mail,
  identidad/MFA, Wazo, hosts víctima) va en Docker Compose.
  **Motivo:** el router necesita manejar interfaces físicas/VLAN trunking 802.1Q real,
  hacer NAT y exponer un puerto SPAN/mirror para el NIDS — un contenedor no controla el
  stack de red del host de esa forma; además la letra (LETRA.md §0.2) pide la Vista
  Física como diagrama central, no una abstracción de Docker. El docker-host es VM
  porque necesita varias NICs (una por VLAN) conectadas al router.
  **Alternativas descartadas:** virtualizar también el router/FW como contenedor.
  **Fuente:** infra/README.md.

- **2026-09-14** — RF-06 (SOAR, 3 playbooks) se resuelve con **Wazuh Active Response**,
  nativo del stack `siem-hids`, en vez de un stack SOAR dedicado como TheHive+Cortex.
  **Motivo:** evita cargar Cassandra + Elasticsearch adicionales de TheHive solo para
  cumplir el requisito, cuando Wazuh (ya necesario para HIDS/SIEM) cubre la orquestación
  de respuesta nativamente.
  **Alternativas descartadas:** TheHive+Cortex como SOAR principal — queda documentado
  en `infra/soar-thehive-optional/` y apagado por defecto; se enciende solo si sobra RAM
  en el host (~3-4 GB adicionales).
  **Fuente:** infra/README.md.

- **2026-10-01** — Descubierto (no documentado hasta ahora): el equipo ya había armado
  parte de la red real en Proxmox en un intento anterior: VM `opnrouter` (VMID 124, OPNsense
  real y funcionando, confirmado por el usuario) + CT `lab-srv-datos` (210, 10.10.10.20) +
  CT `lab-web-dmz` (211, 10.10.20.10). Se confirmó con el usuario (conversación 01/10) que
  es trabajo propio, no de otro equipo/materia.
  **Mapeo de VLANs confirmado (contrario a lo que decía `infra/README.md` hasta hoy):**
  VLAN 10 = **Servidores** (10.10.10.0/24), VLAN 20 = **DMZ** (10.10.20.0/24) — porque así
  quedó físicamente armado, y se decidió mantenerlo así en vez de mover los CT existentes.
  Gateway real de cada VLAN: `.254` (no `.1` como decía una versión anterior de
  `docker-compose.networks.yml`).
  **Se actualizaron para reflejar esto:** `infra/README.md`, `infra/docker-compose.networks.yml`,
  `infra/mail/.env.example` (MAILSERVER_IP → 10.10.20.20), `infra/honeypot/docker-compose.yml`
  (COWRIE_IP → 10.10.20.30), `infra/targets/.env.example` y `docker-compose.yml`
  (WEBAPP_IP → 10.10.10.10), `docs/00-arquitectura.md`, `docs/40-consigna-propia.md`.
  **Fuente:** inspección directa de Proxmox (MCP) + confirmación del usuario, 2026-10-01.

- **2026-10-01** — `docker-host` se crea como **LXC privilegiado** (nesting=1, keyctl=1),
  no como VM completa.
  **Motivo:** el patrón ya usado por el equipo en el intento anterior (`lab-srv-datos` y
  `lab-web-dmz` son LXC, no VMs) funciona y es más liviano en RAM/CPU — recurso crítico
  dado el presupuesto ajustado del host (~11.8 GB libres de 23.28 GB totales, compartido
  con otras materias). El router (`opnrouter`) sí debe seguir siendo VM porque OPNsense/
  pfSense es FreeBSD y un LXC solo puede correr contenedores Linux (no es una opción, es
  una limitación técnica dura).
  **Riesgo abierto:** sumando `opnrouter` (sube a ~2 GB) + `docker-host` (~9-10 GB para
  que entren los 8 stacks activos) el margen libre queda en menos de 1 GB — no van a poder
  correr los 8 stacks a pleno régimen simultáneamente sin ajustar. Recomendación: levantar
  `docker-host` con un límite de memoria conservador al inicio (~6 GB: identity+siem-hids+
  nids+targets+honeypot) y subirlo (`update_container_resources`, sin recrear) recién
  cuando se agreguen `mail`/`wazo`/`alerting`.
  **Fuente:** cálculo sobre `get_nodes`/`get_vms`/`get_containers` (MCP Proxmox), 2026-10-01.
