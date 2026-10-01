---
title: Hechos estables — Tarea 3
tags: [tarea3, memoria, arquitectura, fechas]
updated: 2026-10-01
---

# Hechos estables — Tarea 3

## Marco general

- Curso: Seguridad de la Información (Tecnólogo). Tarea 3 = práctica integradora
  Blue Team / Red Team sobre una infraestructura de red de defensa real.
  (LETRA.md:1-9)
- Dos equipos: **Blue Team** (construye y rinde auditoría) y **Red Team** (ataca e
  informa). (LETRA.md:5, §0.3)
- Perfil de cumplimiento exigido: **MCU 5.0 (AGESIC), perfil comunitario AVANZADO**,
  en las 6 funciones (Gobernar, Identificar, Proteger, Detectar, Responder, Recuperar).
  (LETRA.md §0.1)
- 17 requerimientos funcionales (RF-01 a RF-17) y 10 no funcionales (RNF-01 a RNF-10).
  (LETRA.md §3-4)
- Se exige generar una **consigna propia** (escenario empresarial ficticio + diagrama
  de red + ≥5 casos de uso) antes de avanzar — RF-01. (LETRA.md §6.1, README.md)

## Fechas duras del curso

| Hito | Fecha |
|---|---|
| Pre-entrega Blue Team (congelar, `git tag v1.0`) | miércoles 07/10/2026 |
| Auditoría formal Blue Team (defensa MCU 5.0) | miércoles 14/10/2026 |
| Pre-entrega Red Team (informe preliminar ≥70%) | miércoles 28/10/2026 |
| Entrega final Red Team | lunes 09/11/2026 |

(README.md tabla; LETRA.md §0.3)

### Hitos internos sugeridos por la letra (§6.3 — no confirmado si el equipo los sigue tal cual)

| Hito | Fecha | Ítem |
|---|---|---|
| H1 | lunes 21/09/2026 | Consigna propia + diagrama aprobados |
| H2 | lunes 28/09/2026 | FW + segmentación + NIDS + HIDS operativos |
| H3 | viernes 02/10/2026 | SIEM + SOAR + Wazo + honeypots + dashboards |
| H4 | miércoles 07/10/2026 | Pre-entrega congelada, 3 ataques simulados documentados |
| H5 | miércoles 14/10/2026 | Auditoría formal |

## Arquitectura decidida (infra/README.md)

- **Solo 2 piezas fuera de Docker:** VM `router-fw` (OPNsense o similar, VLAN trunking
  802.1Q real + puerto SPAN/mirror + NAT) y VM `docker-host` (Debian/Ubuntu + Docker
  Engine, una NIC por VLAN). Todo lo demás corre en `docker compose`. Ver también
  [[decisions]] por el motivo completo.
- 9 stacks Docker planeados: `siem-hids` (Wazuh), `nids` (Suricata), `honeypot` (Cowrie),
  `mail` (docker-mailserver), `identity` (Keycloak MFA), `wazo` (PBX), `targets`
  (app+db+ssh víctima), `alerting` (webhook 2º canal), `soar-thehive-optional` (TheHive,
  apagado por defecto). (infra/README.md)
- **RF-06 (SOAR, 3 playbooks)** se resuelve con **Wazuh Active Response**, no con
  TheHive+Cortex — ver [[decisions]].
- Redes Docker (placeholders hasta que H1 defina IPs/VLANs reales): `net_dmz` (VLAN 10,
  DMZ), `net_srv` (VLAN 20, servidores), `net_usr` (VLAN 30, usuarios), `net_mgmt`
  (VLAN 90, gestión). (infra/README.md)
- Presupuesto de RAM de los contenedores: ~8-9 GB.
- Host real: Proxmox `proxmox01`, 6 cores / 23.28 GB RAM, ~11.6 GB ya usados por VMs de
  **otras materias** (`kali`, `unifios`, `opnrouter`, `forti`, etc. — no tocar). Las VMs
  de esta tarea son nuevas. (infra/README.md)

## Estado de avance observado (verificado 2026-10-01)

- `infra/`: tienen `docker-compose.yml` escrito → `identity/`, `mail/`, `targets/`,
  `honeypot/` (los 4 con `.env.example`). **Vacíos** (solo la carpeta, sin contenido):
  `nids/`, `router-vm/`, `siem-hids/`, `wazo/`, `alerting/`, `soar-thehive-optional/`,
  `infra/docs/`.
- `docs/`: `40-consigna-propia.md` y `00-arquitectura.md` tienen **borrador** (escenario
  "FinSegura S.A.", fintech ficticia; 5 casos de uso CU-01..CU-05; vista física con IPs
  reales tomadas de los `.env.example`/compose ya existentes) — falta revisión del
  equipo y aprobación docente. El resto de la matriz sigue en `☐` en `docs/README.md`.
  `docs/evidencias/` está vacía.
- Git: repo local con 6 commits por encima de `origin/main` sin pushear (`git status`,
  2026-10-01).

## Atraso confirmado (conversación 01/10/2026)

- H1 (21/09) y H2 (28/09) de la letra vencieron sin avance: atraso real, no un
  cronograma interno distinto. Equipo de **2 personas**. Consigna propia: escenario
  decidido, diagrama técnico y casos de uso todavía sin cerrar a esta fecha.
- Plan de recuperación acordado (día a día hasta el freeze del 07/10): ver
  [[plan-recuperacion-atraso]].

## Infraestructura real en Proxmox (confirmado 2026-10-01)

- Nodo `proxmox01`: 6 cores / 23.28 GB RAM, ~11.8 GB libres al momento de revisar.
- Ya existe, de un intento anterior del equipo (no estaba en el repo): VM `opnrouter`
  (124, OPNsense real) + CT `lab-srv-datos` (210) + CT `lab-web-dmz` (211).
- Mapeo de VLANs confirmado (ver [[decisions]] para el detalle completo): VLAN10=
  Servidores (10.10.10.0/24), VLAN20=DMZ (10.10.20.0/24), VLAN30=Usuarios
  (10.10.30.0/24, bridge `vmbr1` ya existe libre), VLAN90=Gestión (10.10.90.0/24,
  bridge `vmbr13` **todavía no existe**, es el único paso manual pendiente).
- IPs reservadas por hosts reales (no usar para contenedores Docker): `10.10.10.20`
  (lab-srv-datos), `10.10.20.10` (lab-web-dmz), `.254` en cada VLAN (gateway de
  opnrouter).

## Provisioning ejecutado (2026-10-01)

- `docker-host` creado: **CT 108**, Debian 13, LXC **no privilegiado** (el token del
  conector MCP no puede crear privilegiados, ver [[LEARNINGS]]), nesting=1, 2 cores,
  6 GB RAM, 40 GB disco en `nvme`. NICs: net0=vmbr11/Servidores `.5`,
  net1=vmbr12/DMZ `.5`, net2=vmbr1/Usuarios `.5`. **Falta net3 (Gestión, vmbr13)**.
- `opnrouter` (124): subido a 2 cores/2 GB (pendiente de que se reinicie la VM para
  tomar efecto). NICs agregadas: net3=vmbr1/Usuarios. **Falta NIC de Gestión (vmbr13)**.
- **Resuelto:** se creó `vmbr13` (VLAN Gestión) y se agregaron las 4 NICs en ambos
  (`opnrouter` net1-4, `docker-host` net0-3) vía la API REST de Proxmox directamente con
  `curl` + el token root de `Seguridad/Tarea/.env` (el conector MCP no exponía ni crear
  bridges ni agregar NICs — ver [[LEARNINGS]]). En esta versión de Proxmox (9.2) **ningún
  rol predefinido entre `PVEAdmin`/`PVESysAdmin` y `Administrator` incluye `Sys.Modify`**
  — hubo que terminar asignándole `Administrator` al token para poder crear la bridge.
  El `ifreload -a` del alta de `vmbr13` devolvió exit code 1 pero la bridge quedó activa
  y el nodo sano (mismo uptime, sin caídas) — igual que `vmbr11`/`vmbr12`, `vmbr13` no
  aparece en el listado `/nodes/.../network` (parser de esta versión no las reconoce del
  todo, pero funcionan).
- **Completo (2026-10-01):** `opnrouter` reiniciado (2 cores/2GB activos), y el equipo
  asignó `10.10.30.254/24` (Usuarios) y `10.10.90.254/24` (Gestión) a las 2 interfaces
  nuevas dentro de OPNsense. Las 4 VLANs están arriba en `opnrouter` y `docker-host`.
- Pendiente ahora: instalar Docker dentro de `docker-host` — no hay ejecución remota
  dentro de un LXC vía las herramientas disponibles, lo tiene que hacer el equipo por
  consola/SSH. Si Docker falla por no ser privilegiado, convertir el CT a privilegiado
  desde la UI. Después: copiar `infra/` a `docker-host`, levantar
  `docker-compose.networks.yml` y los stacks que ya tienen compose (`identity`, `mail`,
  `honeypot`, `targets`).
