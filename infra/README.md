# infra/ — Despliegue de la infraestructura (Docker-first)

## Objetivo de este directorio

Que **cualquiera pueda levantar la infraestructura de defensa** con el mínimo de pasos manuales:
casi todo corre en `docker compose`, reproducible y versionado. Solo 1 pieza queda
fuera de Docker porque su naturaleza lo exige (ver abajo).

> ✅ **Actualizado 2026-10-02: esto ya no es un esqueleto con placeholders — es la
> infraestructura real, desplegada y corriendo.** IPs/VLANs son las reales de
> `opnrouter` (VM 124) y `docker-host` (CT 108). 9 de 9 contenedores planeados están
> arriba (falta `wazo`/`alerting`, no construidos todavía, no bloquean el freeze del
> 07/10). Ver `../brain/MEMORY.md` para el detalle y estado de cada pieza.

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

## Stacks y qué RF cubre cada uno

| Carpeta | Servicio | RF que cubre | RAM aprox. |
|---|---|---|---|
| `siem-hids/` | Wazuh (manager + indexer + dashboard) | RF-04, RF-05, RF-10, RF-15, RF-16 | ~3-4 GB |
| `nids/` | Suricata (IDS, hoy en VLAN DMZ vía macvlan) | RF-03 | ~0.5 GB |
| `honeypot/` | Cowrie (SSH/Telnet honeypot) | RF-09 | ~0.25 GB |
| `mail/` | docker-mailserver (Postfix+Dovecot) | RF-07 (canal email) | ~0.5 GB |
| `identity/` | Keycloak (TOTP + WebAuthn nativos) | RF-12 | ~1 GB |
| `wazo/` | Wazo PBX | RF-08 | ~1.5-2 GB |
| `targets/` | App vulnerable + DB + host SSH víctima (con agente Wazuh) | activos a proteger; RT-02/RT-03 | ~1 GB |
| `alerting/` | Relay de webhook (2º canal: Telegram/Discord) | RF-07 (2º canal) | ~0.1 GB |
| `soar-thehive-optional/` | TheHive + Cortex + Cassandra + ES | opcional, RF-11 enriquecido | ~3-4 GB (apagado por defecto) |

**SOAR (RF-06, 3 playbooks) se resuelve con Wazuh Active Response**, nativo del stack
`siem-hids/` — sin contenedor adicional. Evita cargar Cassandra+Elasticsearch de TheHive
solo para eso. `soar-thehive-optional/` queda documentado pero apagado; se enciende
solo si sobra RAM en el host.

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

```bash
# 1. Crear las redes compartidas (una sola vez) — docker-compose.networks.yml es solo
#    referencia, `docker compose up` no crea redes sin services; usar el script:
chmod +x create-networks.sh && ./create-networks.sh

# 2. Prerequisitos de un par de stacks antes de levantarlos:
#    mail necesita certs propios (SSL_TYPE=self-signed no los genera solo):
cd mail && ./generate-self-signed-cert.sh && cd ..
#    siem-hids (Wazuh/OpenSearch) necesita este sysctl en docker-host:
sysctl -w vm.max_map_count=262144

# 3. Por stack, en orden de dependencia
cd identity      && docker compose up -d && cd ..   # MFA primero (todo lo demás lo puede usar)
cd siem-hids      && docker compose up -d && cd ..   # Wazuh: manager+indexer+dashboard
cd nids           && docker compose up -d && cd ..   # Suricata
cd mail           && docker compose up -d && cd ..
cd honeypot       && docker compose up -d && cd ..
cd wazo           && docker compose up -d && cd ..   # no construido todavía
cd targets        && docker compose up -d && cd ..
cd alerting       && docker compose up -d && cd ..   # no construido todavía

# Opcional, solo si sobra RAM:
cd soar-thehive-optional && docker compose up -d && cd ..
```

O usar el `Makefile` de este directorio: `make up` / `make down` / `make status`.

## Qué falta para que esto sea "real" (no solo esqueleto)

1. ~~Consigna propia aprobada (H1, 21/09)~~ — borrador escrito, pendiente aprobación
   docente (`docs/40-consigna-propia.md`). IPs/VLANs reales ya reemplazaron los
   placeholders en todos los `.env`.
2. ~~Desplegar identity, siem-hids, nids, mail, honeypot, targets~~ — hecho 2026-10-02,
   9/9 contenedores corriendo. Reglas de Suricata escritas para CU-01
   (`nids/rules/local.rules`). Faltan los decoders/reglas de Wazuh para CU-02..CU-05.
3. **Agente Wazuh en `targets`** (HIDS/FIM real, RF-04) — no instalado todavía. Hace
   falta además una regla de firewall en OPNsense: VLAN Servidores/Usuarios → VLAN
   Gestión, puertos 1514/1515 (si no, el agente nunca llega al manager).
4. **Playbooks de Active Response** (scripts) para los 3 casos de RF-06.
5. ⚠️ **Pendiente de decidir:** cómo llega tráfico real espejado a Suricata — hoy corre
   en la VLAN DMZ y ve tráfico local de ese segmento vía macvlan, no un mirror explícito
   del router. Opciones: port-mirror a nivel de bridge en Proxmox, o correr Suricata
   directo en OPNsense vía su plugin nativo `os-suricata` (más simple, evita todo el
   problema de mirroring). Las reglas de `local.rules` sirven para cualquiera de las
   dos. Ver `../brain/decisions.md`.
6. `wazo` y `alerting` sin construir — no bloquean el freeze del 07/10.

## Verificación de que el aprovisionamiento del entorno es correcto

Nodo Proxmox usado (`proxmox01`): 6 cores / 23.28 GB RAM. De esta tarea: `opnrouter`
(VM 124, reutilizada de un intento anterior del equipo) y `docker-host` (CT 108, LXC
privilegiado, nuevo). El resto de las VMs/CT del nodo (`kali`, `unifios`, `forti`, etc.)
son de **otras materias/tareas del curso** y no se tocan.
