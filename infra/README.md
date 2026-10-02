# infra/ — Despliegue de la infraestructura (Docker-first)

## Objetivo de este directorio

Que **cualquiera pueda levantar la infraestructura de defensa** con el mínimo de pasos manuales:
casi todo corre en `docker compose`, reproducible y versionado. Solo 1 pieza queda
fuera de Docker porque su naturaleza lo exige (ver abajo).

> ✅ **Actualizado 2026-10-02: esto ya no es un esqueleto con placeholders — es la
> infraestructura real, desplegada y corriendo.** IPs/VLANs son las reales de
> `opnrouter` (VM 124) y `docker-host` (CT 108). **6 de 9 stacks arriba (11
> contenedores)**: identity, siem-hids, nids, mail, honeypot, targets. Sin construir
> (no existen sus carpetas todavía): `wazo`, `alerting`, `soar-thehive-optional`. Ver
> `../brain/MEMORY.md` para IPs reales de cada contenedor y estado de cada pieza.

## Arquitectura: 1 VM (router) + 1 LXC (docker-host) + todo el resto en contenedores

`docker-host` terminó siendo un **LXC privilegiado**, no una VM — más liviano en RAM/CPU
(recurso escaso en este Proxmox compartido) y es el mismo patrón que ya traía el equipo
de un intento anterior (`lab-srv-datos`/`lab-web-dmz` también son LXC). Privilegiado
porque `docker-mailserver` necesita escribir un sysctl (`kernel.domainname`) que un LXC
no privilegiado deniega — ver `../brain/decisions.md` y `../brain/LEARNINGS.md`.

```
                         ┌─────────────────────────────┐
                         │   VM: opnrouter (124)         │
                         │   OPNsense/pfSense            │
                         │   - VLAN trunking real         │
                         │   - NAT / reglas perímetro      │
                         └──────────┬──┬──┬──┬────────────┘
                     vmbr11 (Srv)   │  │  │  │ vmbr13 (Mgmt)
                                    │  │  │  └──────────────────┐
                        vmbr12 (DMZ)│  │vmbr1 (Usr)             │
                         ┌──────────▼──▼──▼──────────────────┐  │
                         │   LXC privilegiado: docker-host (108)│ │
                         │   Debian 13 + Docker Engine, 1 NIC    │
                         │   por VLAN (eth0..eth3)                │
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

### Por qué el router sigue siendo VM (y docker-host no)

| Pieza | Motivo |
|---|---|
| **Router/FW** | OPNsense/pfSense es FreeBSD — un LXC solo puede correr contenedores Linux (comparte el kernel del host), no es una opción, es una limitación técnica dura. Además necesita manejar VLAN trunking (802.1Q), NAT, y la letra (sección 0.2) pide la "Vista Física" como diagrama central — se espera un dispositivo de red real. |
| **docker-host** | LXC privilegiado (no VM): más liviano, mismo patrón que ya usaba el equipo (`lab-srv-datos`/`lab-web-dmz`). Todo lo que corre *dentro* es 100% Docker Compose. |

Todo lo demás — SIEM, HIDS, NIDS, SOAR (Active Response), honeypot, mail, identidad/MFA,
Wazo, hosts víctima — es contenedor. Eso es lo que se pidió: "lo más posible en Docker".

## Provisioning desde cero (si hay que rearmar todo en otro Proxmox)

Lo que sigue abajo (redes Docker + stacks) asume que **ya existen** `opnrouter` y
`docker-host`. Si hay que crearlos de cero (otro Proxmox, o si se perdieron), estos son
los pasos reales que se usaron acá — ver `../brain/decisions.md` para el detalle de cada
decisión.

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

Presupuesto total contenedores: **~8-9 GB** de RAM. `docker-host` quedó con límite de
**9 GB** (subido de los 6 GB iniciales cuando se agregó Wazuh), dentro del margen real
del Proxmox del laboratorio (nodo único, 6 cores / 23.28 GB, ~10.7 GB libres al
2026-10-02 — **no tocar VMs existentes** `kali`, `unifios`, etc.; `opnrouter` SÍ es de
esta tarea, es el router).

## Redes compartidas (VLANs → redes Docker)

Todas las redes se declaran una sola vez en `docker-compose.networks.yml` como `external`,
y cada stack las referencia. Así se crean antes de levantar ningún stack.

| Red Docker | VLAN | Segmento | Quién vive ahí |
|---|---|---|---|
| `net_srv` | VLAN 10 (10.10.10.0/24) | Servidores | targets (app+db); ya existe `lab-srv-datos` (CT 210) |
| `net_dmz` | VLAN 20 (10.10.20.0/24) | DMZ | Wazo (pendiente), mail, honeypot, **NIDS (Suricata)**; ya existe `lab-web-dmz` (CT 211) |
| `net_usr` | VLAN 30 (10.10.30.0/24) | Usuarios | host SSH cliente víctima, puestos de prueba |
| `net_mgmt` | VLAN 90 (10.10.90.0/24) | Gestión | Wazuh (×3), Keycloak, alerting (pendiente) |

> El mapeo es **10 = Servidores, 20 = DMZ** (así quedó físicamente armado en Proxmox
> desde un intento previo del equipo — ver `../brain/decisions.md`). NIDS se movió de
> Gestión a DMZ el 2026-10-02: un contenedor Docker solo ve la interfaz de SU red,
> nombrada `eth0` puertas adentro — con dos redes conectadas el nombre deja de ser
> predecible, así que Suricata va en una sola (DMZ).

## Cómo levantar (orden recomendado — ya ejecutado 2026-10-02, referencia para rearmar)

**Camino corto** (dentro de `docker-host`, desde esta carpeta `infra/`):

```bash
make up       # redes + prerequisitos + los 6 stacks, en orden. Se puede re-correr.
make status   # docker ps resumido
make logs     # últimas líneas de cada stack
```

Los contenedores tienen `restart: unless-stopped`: si se reinicia `docker-host`, vuelven
solos (verificado 2026-10-02), no hace falta re-correr nada.

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
cd "$INFRA/siem-hids"  && docker compose up -d   # Wazuh: manager+indexer+dashboard
cd "$INFRA/nids"       && docker compose up -d   # Suricata
cd "$INFRA/mail"       && docker compose up -d
cd "$INFRA/honeypot"   && docker compose up -d
cd "$INFRA/targets"    && docker compose up -d
# wazo / alerting / soar-thehive-optional: no construidos todavía
```

> Wazuh tarda 30-60 s en levantar del todo: los "connection refused" del manager o del
> dashboard hacia el indexer en el primer minuto son normales. Mirar de nuevo antes de
> tocar nada.

## Qué falta para que esto sea "real" (no solo esqueleto)

1. ~~Consigna propia aprobada (H1, 21/09)~~ — borrador escrito, pendiente aprobación
   docente (`docs/40-consigna-propia.md`). IPs/VLANs reales ya reemplazaron los
   placeholders en todos los `.env`.
2. ~~Desplegar identity, siem-hids, nids, mail, honeypot, targets~~ — hecho 2026-10-02,
   6 stacks / 11 contenedores corriendo. Reglas de Suricata escritas para CU-01
   (`nids/rules/local.rules`). Faltan los decoders/reglas de Wazuh para CU-02..CU-05.
3. **Agente Wazuh en `targets`** (HIDS/FIM real, RF-04) — no instalado todavía. Hace
   falta además una regla de firewall en OPNsense: VLAN Servidores/Usuarios → VLAN
   Gestión, puertos 1514/1515 (si no, el agente nunca llega al manager).
4. **Logs de Suricata y Cowrie → Wazuh**: hoy `nids` escribe `eve.json` en el volumen
   `suricata_logs` y `honeypot` en `cowrie_logs`, y nadie los lee. Hace falta montarlos
   en `wazuh.manager` (o un agente/forwarder) y declararlos como `<localfile>` en
   `ossec.conf`. Sin esto no hay correlación (RF-05) ni se ve el CU-01 en el dashboard.
5. **MFA dentro de Keycloak** (TOTP/WebAuthn, RF-12): el contenedor corre pero no hay
   realm/usuarios/MFA configurados todavía.
6. **Playbooks de Active Response** (scripts) para los 3 casos de RF-06.
7. ⚠️ **Pendiente de decidir:** cómo llega tráfico real espejado a Suricata — hoy corre
   en la VLAN DMZ y ve tráfico local de ese segmento vía macvlan, no un mirror explícito
   del router. Opciones: port-mirror a nivel de bridge en Proxmox, o correr Suricata
   directo en OPNsense vía su plugin nativo `os-suricata` (más simple, evita todo el
   problema de mirroring). Las reglas de `local.rules` sirven para cualquiera de las
   dos. Ver `../brain/decisions.md`.
8. `wazo` y `alerting` sin construir — no bloquean el freeze del 07/10.

## Verificación de que el aprovisionamiento del entorno es correcto

Nodo Proxmox usado (`proxmox01`): 6 cores / 23.28 GB RAM. De esta tarea: `opnrouter`
(VM 124, reutilizada de un intento anterior del equipo) y `docker-host` (CT 108, LXC
privilegiado, nuevo). El resto de las VMs/CT del nodo (`kali`, `unifios`, `forti`, etc.)
son de **otras materias/tareas del curso** y no se tocan.
