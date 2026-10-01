# infra/ — Despliegue de la infraestructura (Docker-first)

## Objetivo de este directorio

Que **cualquiera pueda levantar la infraestructura de defensa** con el mínimo de pasos manuales:
casi todo corre en `docker compose`, reproducible y versionado. Solo 2 piezas quedan
fuera de Docker porque su naturaleza lo exige (ver abajo).

> ⚠️ **IPs, VLAN IDs y nombres de host en este esqueleto son PLACEHOLDERS.**
> Se ajustan una vez que la consigna propia (`docs/40-consigna-propia.md`, hito H1 —
> 21/09/2026) defina el escenario empresarial real. La estructura y los compose files
> no cambian; solo el `.env` de cada stack.

## Arquitectura: 2 VMs + todo el resto en contenedores

```
                         ┌─────────────────────────────┐
                         │   VM 1: router-fw            │
                         │   OPNsense (o similar)       │
                         │   - VLAN trunking real        │
                         │   - NAT / reglas perímetro     │
                         │   - Puerto SPAN/mirror ────────┼──► NIDS (Suricata, en docker-host)
                         └──────────┬──────────┬─────────┘
                                    │          │
                    net1 (DMZ)      │          │  net2 (Servers) net3 (Users) net4 (Mgmt)
                         ┌──────────▼──────────▼─────────┐
                         │   VM 2: docker-host             │
                         │   Debian/Ubuntu + Docker Engine │
                         │   Cada red del router = 1 red   │
                         │   macvlan en el docker-host      │
                         │                                  │
                         │  ┌────────────────────────────┐  │
                         │  │ siem-hids/  (Wazuh)         │  │
                         │  │ nids/       (Suricata)      │  │
                         │  │ honeypot/   (Cowrie)         │  │
                         │  │ mail/       (docker-mailserver)│
                         │  │ identity/   (Keycloak MFA)    │  │
                         │  │ wazo/       (Wazo PBX)         │  │
                         │  │ targets/    (app+db+ssh victima)│
                         │  │ alerting/   (webhook 2º canal)  │
                         │  │ soar-thehive-optional/ (apagado)│
                         │  └────────────────────────────┘  │
                         └──────────────────────────────────┘
```

### Por qué SOLO estas 2 piezas van en VM y no en Docker

| Pieza | Motivo |
|---|---|
| **Router/FW** | Necesita manejar interfaces físicas/VLAN trunking (802.1Q real), hacer NAT y exponer un puerto SPAN/mirror para el NIDS. Un contenedor no controla el stack de red del host de esa forma. Además la letra (sección 0.2) pide la "Vista Física" como diagrama central — se espera un dispositivo de red real, no una abstracción de Docker. |
| **Docker host** | Es una VM porque necesita varias NICs (una por VLAN) conectadas al router. Todo lo que corre *dentro* sí es 100% Docker Compose. |

Todo lo demás — SIEM, HIDS, NIDS, SOAR (Active Response), honeypot, mail, identidad/MFA,
Wazo, hosts víctima — es contenedor. Eso es lo que se pidió: "lo más posible en Docker".

## Stacks y qué RF cubre cada uno

| Carpeta | Servicio | RF que cubre | RAM aprox. |
|---|---|---|---|
| `siem-hids/` | Wazuh (manager + indexer + dashboard) | RF-04, RF-05, RF-10, RF-15, RF-16 | ~3-4 GB |
| `nids/` | Suricata (IDS, modo lectura de SPAN) | RF-03 | ~0.5 GB |
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

Presupuesto total contenedores: **~8-9 GB** de RAM, dentro del margen real observado en
el Proxmox del laboratorio (nodo único, 6 cores / 23 GB, ~11-12 GB libres compartidos
con otras materias — **no tocar VMs existentes** `kali`, `unifios`, `opnrouter`, etc.).

## Redes compartidas (VLANs → redes Docker)

Todas las redes se declaran una sola vez en `docker-compose.networks.yml` como `external`,
y cada stack las referencia. Así se crean antes de levantar ningún stack.

| Red Docker | VLAN | Segmento | Quién vive ahí |
|---|---|---|---|
| `net_srv` | VLAN 10 (10.10.10.0/24) | Servidores | targets (app+db); ya existe `lab-srv-datos` (CT 210) |
| `net_dmz` | VLAN 20 (10.10.20.0/24) | DMZ | Wazo, mail, honeypot; ya existe `lab-web-dmz` (CT 211) |
| `net_usr` | VLAN 30 (10.10.30.0/24) | Usuarios | host SSH cliente víctima, puestos de prueba |
| `net_mgmt` | VLAN 90 (10.10.90.0/24) | Gestión | Wazuh, Keycloak, NIDS (sniff), alerting |

> ⚠️ Confirmado 2026-10-01: el mapeo es **10 = Servidores, 20 = DMZ** (al revés de una
> versión anterior de esta tabla), porque así quedó físicamente armado en Proxmox desde
> un intento previo del equipo (`opnrouter` VMID 124 + CTs 210/211). Ver `../brain/decisions.md`.

## Cómo levantar (orden recomendado)

```bash
# 1. Crear las redes compartidas (una sola vez)
docker compose -f docker-compose.networks.yml up -d

# 2. Por stack, en orden de dependencia
cd identity      && docker compose up -d && cd ..   # MFA primero (todo lo demás lo puede usar)
cd siem-hids      && docker compose up -d && cd ..   # SIEM/HIDS
cd nids           && docker compose up -d && cd ..   # NIDS
cd mail           && docker compose up -d && cd ..
cd honeypot       && docker compose up -d && cd ..
cd wazo           && docker compose up -d && cd ..
cd targets        && docker compose up -d && cd ..
cd alerting       && docker compose up -d && cd ..

# Opcional, solo si sobra RAM:
cd soar-thehive-optional && docker compose up -d && cd ..
```

O usar el `Makefile` de este directorio: `make up` / `make down` / `make status`.

## Qué falta para que esto sea "real" (no solo esqueleto)

1. ~~Consigna propia aprobada (H1, 21/09)~~ — borrador escrito 2026-10-01
   (`docs/40-consigna-propia.md`), pendiente aprobación docente. IPs/VLANs reales ya
   reemplazaron los placeholders en los `.env` de `mail`, `honeypot`, `targets`.
2. **Reglas de Suricata**: escritas para CU-01 (`nids/rules/local.rules` — escaneo
   ruidoso, NULL/FIN/XMAS, barrido de ping). Faltan los decoders/reglas de Wazuh para
   CU-02..CU-05.
   ⚠️ **Pendiente de decidir:** cómo llega el tráfico espejado a Suricata — port-mirror
   a nivel de bridge en Proxmox hacia `docker-host`, o correr Suricata directo en
   OPNsense vía su plugin nativo `os-suricata` (más simple, el router ya ve el tráfico
   relevante; evita todo el problema de mirroring). Las reglas de `local.rules` sirven
   para cualquiera de las dos opciones. Ver `../brain/decisions.md`.
3. **Playbooks de Active Response** (scripts) para los 3 casos de RF-06.
4. ~~Provisioning de las 2 VMs en Proxmox~~ — hecho 2026-10-01: `opnrouter` (VMID 124,
   subido a 2 cores/2GB, 4 VLANs) y `docker-host` (CT 108, LXC, 4 NICs). Falta instalar
   Docker dentro de `docker-host` (manual, por consola/SSH).

## Verificación de que el aprovisionamiento del entorno es correcto

Node Proxmox usado (`proxmox01`): 6 cores / 23.28 GB RAM, ~11.6 GB en uso por VMs de
**otras tareas del curso** (no relacionadas a esta). Las VMs de esta tarea son nuevas y
no reutilizan `kali`, `unifios`, `opnrouter`, `forti`, etc.
