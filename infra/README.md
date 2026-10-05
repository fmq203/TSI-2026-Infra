# infra/ — Despliegue de la infraestructura (Docker-first)

## Objetivo de este directorio

Que **cualquiera pueda levantar la infraestructura de defensa** con el mínimo de pasos manuales:
casi todo corre en `docker compose`, reproducible y versionado. Solo 1 pieza queda
fuera de Docker porque su naturaleza lo exige (ver abajo).

> **Para desplegar desde cero en VirtualBox, ir a `../vagrant/README.md`** — hace todo
> lo de esta carpeta automáticamente. Este README explica qué hay adentro de
> `docker-host` y cómo levantarlo a mano en cualquier Linux con 4 NICs.
>
> Estado: **6 de 9 stacks construidos (11 contenedores)**: identity, siem-hids, nids,
> mail, honeypot, targets. Sin construir (no existen sus carpetas): `wazo`, `alerting`,
> `soar-thehive-optional`. IPs de cada contenedor en `../brain/MEMORY.md`.

## Arquitectura: 1 router + 1 docker-host + todo el resto en contenedores

`docker-host` es una VM en VirtualBox, o un **LXC privilegiado** en Proxmox (más liviano;
privilegiado porque `docker-mailserver` necesita escribir un sysctl, `kernel.domainname`,
que un LXC no privilegiado deniega — ver `../brain/LEARNINGS.md`).

```
                         ┌─────────────────────────────┐
                         │   router (VM)                 │
                         │   OPNsense, o nftables en     │
                         │   VirtualBox                  │
                         │   - NAT / reglas entre VLANs   │
                         └──────────┬──┬──┬──┬────────────┘
                    Servidores (10) │  │  │  │ Gestión (90)
                                    │  │  │  └──────────────────┐
                            DMZ (20)│  │Usuarios (30)           │
                         ┌──────────▼──▼──▼──────────────────┐  │
                         │   docker-host (VM o LXC privil.)    │ │
                         │   Linux + Docker Engine, 1 NIC        │
                         │   por VLAN, .5 en todas               │
                         │                                         │
                         │  ┌───────────────────────────────────┐ │
                         │  │ identity/ (Keycloak)          ✅    │ │
                         │  │ siem-hids/ (Wazuh ×3)         ✅    │ │
                         │  │ nids/ (Suricata, en VLAN DMZ) ✅    │ │
                         │  │ mail/ (docker-mailserver)     ✅    │ │
                         │  │ honeypot/ (Cowrie)            ✅    │ │
                         │  │ targets/ (app+db+ssh víctima) ✅    │ │
                         │  │ wazo/ (Wazo PBX)              ❌    │ │
                         │  │ alerting/ (webhook 2º canal)  ❌    │ │
                         │  │ soar-thehive-optional/ (apagado)   │ │
                         │  └───────────────────────────────────┘ │
                         └─────────────────────────────────────────┘
```

### Por qué el router es una VM aparte

OPNsense/pfSense es FreeBSD: no puede correr en un contenedor Linux. Además hace NAT y el
filtrado entre VLANs, y la letra (sección 0.2) pide la "Vista Física" como diagrama
central — se espera un dispositivo de red real, no una abstracción de Docker.

Todo lo demás — SIEM, HIDS, NIDS, SOAR (Active Response), honeypot, mail, identidad/MFA,
Wazo, hosts víctima — es contenedor. Eso es lo que se pidió: "lo más posible en Docker".

## Alternativa: desplegar en Proxmox en vez de VirtualBox

Para quien tenga un Proxmox propio. Lo de abajo (redes Docker + stacks) asume que **ya
existen** el router y `docker-host`; estos son los pasos para crearlos — ver
`../brain/decisions.md` y `../brain/LEARNINGS.md` para el detalle y los problemas que
aparecieron.

### 1. Crear las 4 bridges de red en el host Proxmox

Datacenter → Node → System → Network → Create → Linux Bridge, 4 veces: sin IP, sin
puerto físico (igual que una bridge interna aislada). Nombres usados acá: `vmbr11`
(Servidores), `vmbr12` (DMZ), `vmbr1` (Usuarios), `vmbr13` (Gestión) — los nombres no
importan, lo que importa es que cada una quede aislada (sin `bridge_ports`).

> Para crear/editar bridges del nodo hace falta el rol `Administrator` completo en el
> token de API que se use (`Sys.Modify`) — ningún rol intermedio de Proxmox lo incluye.
> Ver `../brain/LEARNINGS.md`.

### 2. Crear la VM del router (OPNsense/pfSense)

VM completa (no LXC — OPNsense es FreeBSD, un LXC solo corre contenedores Linux, es una
limitación técnica dura, no una elección). Instalar desde el ISO oficial de OPNsense, con
**5 NICs virtio** en este orden (importa, define qué `vtnetN` es cuál adentro de
OPNsense):

| # | Bridge | Rol | IP a configurar |
|---|---|---|---|
| net0 | `vmbr0` (o la red con salida a internet) | WAN | DHCP o la que corresponda |
| net1 | `vmbr11` | Servidores (LAN) | 10.10.10.254/24 |
| net2 | `vmbr12` | DMZ (OPT1) | 10.10.20.254/24 |
| net3 | `vmbr1` | Usuarios (OPT2) | 10.10.30.254/24 |
| net4 | `vmbr13` | Gestión (OPT3) | 10.10.90.254/24 |

Configurar NAT (automático con el wizard de OPNsense) y las reglas de firewall de
`docs/40-consigna-propia.md` §2. Recursos: 2 cores / 2 GB alcanza para este laboratorio.

### 3. Crear `docker-host` (LXC privilegiado)

```bash
pct create <vmid> local:vztmpl/debian-13-standard_<version>_amd64.tar.zst \
  --hostname docker-host \
  --cores 2 --memory 9216 --swap 1024 \
  --rootfs <storage>:40 \
  --unprivileged 0 \
  --features nesting=1,keyctl=1 \
  --onboot 1 \
  --net0 name=eth0,bridge=vmbr11,gw=10.10.10.254,ip=10.10.10.5/24 \
  --net1 name=eth1,bridge=vmbr12,gw=10.10.20.254,ip=10.10.20.5/24 \
  --net2 name=eth2,bridge=vmbr1,gw=10.10.30.254,ip=10.10.30.5/24 \
  --net3 name=eth3,bridge=vmbr13,gw=10.10.90.254,ip=10.10.90.5/24

pct start <vmid>
```

> **Por qué `pct create` y no la API/UI de un token:** crear un LXC **privilegiado**
> está bloqueado para *cualquier* token de API (incluso uno con rol `Administrator`) —
> Proxmox exige una sesión real (SSH/consola), por diseño. Por eso este paso es manual,
> no se puede automatizar vía API. Ver `../brain/LEARNINGS.md`.
>
> Privilegiado porque `docker-mailserver` necesita escribir un sysctl
> (`kernel.domainname`) que un LXC no privilegiado deniega. `unprivileged` es además una
> opción **read-only** después de creado — si se crea sin privilegios por error, hay que
> destruir y recrear, no se puede convertir en caliente.

### 4. Instalar Docker y clonar este repo dentro de `docker-host`

```bash
apt update && apt install -y ca-certificates curl git
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

cd /opt
git clone <url-de-este-repo>
cd <repo>/infra
```

De acá en adelante, seguir "Cómo levantar" más abajo.

## Stacks y qué RF cubre cada uno

| Carpeta | Servicio | RF que cubre | RAM aprox. |
|---|---|---|---|
| `siem-hids/` | Wazuh (manager + indexer + dashboard) | RF-04, RF-05, RF-10, RF-15, RF-16 | ~3-4 GB |
| `nids/` | Suricata (IDS, hoy en VLAN DMZ vía macvlan) | RF-03 | ~0.5 GB |
| `honeypot/` | Cowrie (SSH/Telnet honeypot) | RF-09 | ~0.25 GB |
| `mail/` | docker-mailserver (Postfix+Dovecot) | RF-07 (canal email) | ~0.5 GB |
| `identity/` | Keycloak (TOTP + WebAuthn nativos) | RF-12 | ~1 GB |
| `wazo/` | Wazo PBX | RF-08 | ~1.5-2 GB — ❌ **no construido** (carpeta no existe) |
| `targets/` | App vulnerable + DB + host SSH víctima (agente Wazuh **pendiente**) | activos a proteger; RT-02/RT-03 | ~1 GB |
| `alerting/` | Relay de webhook (2º canal: Telegram/Discord) | RF-07 (2º canal) | ~0.1 GB — ❌ **no construido** |
| `soar-thehive-optional/` | TheHive + Cortex + Cassandra + ES | opcional, RF-11 enriquecido | ~3-4 GB — ❌ **no construido**, y no hace falta |

**SOAR (RF-06, 3 playbooks) se resuelve con Wazuh Active Response**, nativo del stack
`siem-hids/` — sin contenedor adicional. Evita cargar Cassandra+Elasticsearch de TheHive
solo para eso. `soar-thehive-optional/` solo se construiría si sobra tiempo y RAM.

Presupuesto total contenedores: **~8-9 GB** de RAM — darle a `docker-host` 9-10 GB
(con 6 GB Wazuh no entra cómodo).

## Redes compartidas (VLANs → redes Docker)

Las 4 redes son **macvlan** colgadas de cada NIC de `docker-host` y se crean con
`create-networks.sh` (que detecta qué NIC es cuál por su IP `.5`). Cada stack las usa
como `external`. `docker-compose.networks.yml` queda solo como referencia legible.

| Red Docker | VLAN | Segmento | Quién vive ahí |
|---|---|---|---|
| `net_srv` | VLAN 10 (10.10.10.0/24) | Servidores | targets (app + db) |
| `net_dmz` | VLAN 20 (10.10.20.0/24) | DMZ | mail, honeypot, **NIDS (Suricata)**, Wazo (pendiente) |
| `net_usr` | VLAN 30 (10.10.30.0/24) | Usuarios | host SSH víctima, puestos de prueba |
| `net_mgmt` | VLAN 90 (10.10.90.0/24) | Gestión | Wazuh (×3), Keycloak, alerting (pendiente) |

> El mapeo es **10 = Servidores, 20 = DMZ** (no al revés). Suricata está en una sola red
> (DMZ) a propósito: un contenedor ve cada red como `eth0`, `eth1`... en orden de
> conexión, sin relación con los nombres del host; con una sola red, su interfaz de
> captura es siempre `eth0`.
>
> Limitación de macvlan: `docker-host` **no puede hablar con sus propios contenedores**
> (ni `curl` ni ping). Para probar un servicio, hacerlo desde el router u otra VM.

## Cómo levantar

**Camino corto** (dentro de `docker-host`, desde esta carpeta `infra/`):

```bash
make up       # redes + prerequisitos + los 6 stacks, en orden. Se puede re-correr.
make status   # docker ps resumido
make logs     # últimas líneas de cada stack
```

Los contenedores tienen `restart: unless-stopped`: si se reinicia `docker-host`, vuelven
solos, no hace falta re-correr nada.

**Camino manual** (lo mismo que hace `make up`, paso a paso):

```bash
# 1. Crear las redes compartidas (una sola vez) — docker-compose.networks.yml es solo
#    referencia, `docker compose up` no crea redes sin services; usar el script:
chmod +x create-networks.sh && ./create-networks.sh

# 2. Prerequisitos de un par de stacks antes de levantarlos:
#    mail necesita certs propios (SSL_TYPE=self-signed no los genera solo):
cd mail && ./generate-self-signed-cert.sh && cd ..
#    siem-hids (Wazuh/OpenSearch) necesita este sysctl en docker-host:
sysctl -w vm.max_map_count=262144

# 3. Por stack, en orden de dependencia. OJO: usar rutas absolutas o `;` en vez de `&&`
#    entre el cd de vuelta — si un `docker compose up` falla, un `&&` corta la cadena y
#    el siguiente comando se ejecuta en el directorio equivocado (nos pasó varias veces).
INFRA=/opt/TSI-2026-Infra/infra   # ajustar a donde hayan clonado el repo

for s in identity siem-hids nids mail honeypot targets; do
  [ -f "$INFRA/$s/.env.example" ] && [ ! -f "$INFRA/$s/.env" ] && cp "$INFRA/$s/.env.example" "$INFRA/$s/.env"
done

cd "$INFRA/identity"   && docker compose up -d   # MFA primero (todo lo demás lo puede usar)
cd "$INFRA/nids"       && docker compose up -d   # Suricata (antes que Wazuh: le monta su volumen de logs)
cd "$INFRA/siem-hids"  && docker compose up -d   # Wazuh: manager+indexer+dashboard
"$INFRA/siem-hids/configure-manager.sh"          # Suricata, reglas locales, active response, mail
cd "$INFRA/mail"       && docker compose up -d
"$INFRA/mail/ensure-accounts.sh"                # casilla soc@lab.local
cd "$INFRA/honeypot"   && docker compose up -d
cd "$INFRA/targets"    && docker compose up -d --build   # ssh-client es imagen propia (ssh-victim/)
# wazo / alerting / soar-thehive-optional: no construidos todavía
```

> Wazuh tarda 30-60 s en levantar del todo: los "connection refused" del manager o del
> dashboard hacia el indexer en el primer minuto son normales. Mirar de nuevo antes de
> tocar nada.

## Qué falta

1. ~~Consigna propia~~ — borrador escrito, pendiente aprobación docente
   (`docs/40-consigna-propia.md`).
2. ~~Stacks identity, siem-hids, nids, mail, honeypot, targets~~ — construidos y
   probados. Reglas de Suricata escritas para CU-01 (`nids/rules/local.rules`). Faltan
   los decoders/reglas de Wazuh para CU-02..CU-05.
3. **Agente Wazuh en `targets`** (HIDS/FIM real, RF-04) — instalado en `ssh-client`
   (imagen `targets/ssh-victim/`, CU-02: fuerza bruta → Active Response `firewall-drop`
   → mail a `soc@lab.local`), **sin verificar todavía**. Falta en `webapp` (CU-03). El
   router tiene que dejar pasar Servidores/Usuarios → Gestión 1514/1515 y Gestión → DMZ
   25 (mail): el router nftables de `vagrant/` ya lo permite; en OPNsense hay que crear
   las reglas.
4. **Logs de Cowrie → Wazuh**: Suricata ya está conectado (el volumen `nids_suricata_logs`
   se monta en `wazuh.manager` y `siem-hids/configure-manager.sh` agrega el
   `<localfile>` a `ossec.conf`). Falta lo mismo para `cowrie_logs` del honeypot. Ojo:
   Suricata hoy probablemente solo ve el tráfico dirigido a su IP (`10.10.20.50`) — ver
   el punto 7.
5. **MFA dentro de Keycloak** (TOTP/WebAuthn, RF-12): el contenedor corre pero no hay
   realm/usuarios/MFA configurados todavía.
6. **Playbooks de Active Response** (scripts) para los 3 casos de RF-06.
7. ⚠️ **Pendiente de decidir:** cómo llega tráfico real espejado a Suricata — hoy corre
   en la VLAN DMZ y ve tráfico local de ese segmento vía macvlan, no un mirror explícito
   del router. Opciones: espejar tráfico a nivel del hipervisor (bridge/switch virtual),
   o correr Suricata directo en OPNsense vía su plugin nativo `os-suricata` (más simple,
   evita todo el problema de mirroring). Las reglas de `local.rules` sirven para
   cualquiera de las dos. Ver `../brain/decisions.md`.
8. `wazo` y `alerting` sin construir — no bloquean el freeze del 07/10.
