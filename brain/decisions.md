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

- **2026-10-02** — Se arma una **reproducción portable en VirtualBox/Vagrant**
  (`vagrant/`) de la misma infra, para que el Red Team la ataque en su propia máquina en
  vez de competir por el Proxmox compartido del Blue Team (tiene sentido: cada equipo
  Blue Team arma su propia consigna, lo natural es que el Red Team correspondiente
  ataque una copia propia). El router de esa reproducción es una **VM Linux con
  nftables**, no OPNsense — OPNsense no tiene box de Vagrant oficial (FreeBSD, instalación
  por ISO) y automatizarlo no valía el esfuerzo dado el tiempo disponible.
  **Alternativas descartadas:** automatizar OPNsense igual (vía ISO + autoinstall,
  mucho más trabajo para un componente que el Red Team no audita, solo ataca lo que hay
  detrás). **Riesgo aceptado:** si algún hallazgo del Red Team depende específicamente
  de una particularidad de OPNsense, no se va a reproducir en esta copia — queda
  anotado en `vagrant/README.md`.
  **Fuente:** conversación 2026-10-02.

- **2026-10-02** — Revertido lo anterior en parte: para la reproducción VirtualBox se
  bajó el `config.xml` **real** de `opnrouter` (vía su API,
  `/api/core/backup/download/this`, con una API key de OPNsense generada por el
  usuario) y se confirmó que las interfaces son `vtnet0`(WAN)/`vtnet1`(Servidores,
  LAN)/`vtnet2`(DMZ, OPT1)/`vtnet3`(Usuarios, OPT2)/`vtnet4`(Gestión, OPT3) — virtio,
  compatible con el adaptador "virtio-net" de VirtualBox. Con esto, la opción
  **recomendada** para el router del Red Team pasa a ser OPNsense real + importar ese
  `config.xml` (fiel 1:1), con nftables como fallback 100% automatizado si no quieren
  instalar OPNsense a mano. El `config.xml` real **no está en el repo** (trae hash de
  password admin + API keys) — queda local, se distribuye al Red Team por canal
  privado. `.gitignore` actualizado para no commitearlo por accidente.
  **Fuente:** conversación 2026-10-02, archivo en
  `/tmp/.../scratchpad/opnsense-config.xml` (local, no en git).

- **2026-10-02** — Se armó una VM de prueba en Proxmox (**VMID 109**, `vbox-test-host`,
  4 cores/12GB/80GB, `cpu=host` para virtualización anidada) para validar el
  `Vagrantfile` de `vagrant/` sin depender de una laptop externa. Se apagaron
  `opnrouter` y `docker-host` temporalmente para liberar RAM (vuelven a prenderse al
  terminar esta prueba). Adentro: Debian 13 + VirtualBox 7.2.20 (repo oficial de
  Oracle, sí soporta `trixie`) + Vagrant 2.4.9 (repo de HashiCorp, también soporta
  `trixie`). `vboxdrv` activo, flag `vmx` presente — la virtualización anidada
  funciona. Repo clonado en `/opt/TSI-2026-Infra` dentro de esta VM de prueba (no
  confundir con el `docker-host` real).
  **Fuente:** conversación 2026-10-02.

- **2026-10-02** — Se intentó validar `vagrant up` (VirtualBox) anidado dentro de una
  VM de Proxmox (VMID 109, `vbox-test-host`) para no depender de una laptop externa.
  **Descartado tras 5 intentos de fix** (ver [[LEARNINGS]]) — es un límite real de
  triple anidamiento en este hardware, no algo configurable. `opnrouter` y
  `docker-host` se apagaron ~1h20 para esta prueba y se restauraron al cortarla; los
  11 contenedores de `docker-host` volvieron solos por `restart: unless-stopped`, sin
  intervención manual. La validación real de `vagrant up` se hace en una máquina
  física (no anidada) — que es además el escenario del compañero y del Red Team.
  **Fuente:** conversación 2026-10-02.

- **2026-10-02** — Se le dio a Claude acceso **SSH directo al host Proxmox** (key
  dedicada `claude_proxmox`, no la de uso personal) para ejecutar `pct exec`/`qm`
  directo en `docker-host` sin pedirle al usuario que relaye cada comando. Terminó
  usándose específicamente para `pct exec 108 -- curl ...` contra la API de OPNsense
  (vía `docker-host`, que ya está en la VLAN Servidores) — **no hizo falta** tocar la
  red del host Proxmox (el plan original de asignarle una IP transitoria a `vmbr11` se
  descartó, el usuario prefirió no modificar nada del host). Accesos temporales a ese
  entorno: los gestiona su dueño fuera del repo.
  **Fuente:** conversación 2026-10-02.

- **2026-10-02** — **El repo pasa a ser autosuficiente para desplegar desde cero en
  VirtualBox** (`vagrant/` como camino principal). Motivo: el otro integrante no tiene
  acceso al Proxmox de referencia y tiene que armar todo en su máquina. Se sacaron del
  repo todos los pendientes y accesos que dependían de ese Proxmox (IDs de VM, tokens,
  keys, VMs a borrar); la arquitectura y las IPs no cambian. Arreglos para que `vagrant
  up` funcione en una máquina limpia: sin carpeta compartida (clona el repo de GitHub;
  el box de Debian no trae Guest Additions y Windows no tiene rsync), NICs de VLAN de
  `docker-host` en modo promiscuo "allow-all" (macvlan), `.gitattributes` con LF para
  los scripts, IP fija para Keycloak (`.20`), su DB (`.21`) y la DB de la app (`.11`), y
  guía para configurar OPNsense a mano sin depender de un `config.xml` ajeno.
  **Fuente:** conversación 2026-10-02.
