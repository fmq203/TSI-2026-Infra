---
title: Hechos estables — Tarea 3 (foto del estado actual)
tags: [tarea3, memoria, arquitectura, fechas, estado]
updated: 2026-10-06
---

# Hechos estables — Tarea 3

> Este archivo es la **foto del estado actual**, no un historial. El "por qué" de cada
> cosa está en [[decisions]] (cronológico) y los errores ya pisados en [[LEARNINGS]]. Si
> algo de acá contradice al código, manda el código — actualizar este archivo.

## Marco general

- Curso: Seguridad de la Información (Tecnólogo). Tarea 3 = práctica integradora
  Blue Team / Red Team sobre una infraestructura de red de defensa. (LETRA.md)
- Equipo Blue Team: **2 personas**. Perfil exigido: **MCU 5.0 (AGESIC), perfil
  AVANZADO**, 6 funciones. 17 RF + 10 RNF. (LETRA.md §0.1, §3-4)
- Escenario de la consigna propia: **FinSegura S.A.**, fintech ficticia, 5 casos de uso
  CU-01..CU-05 (`docs/40-consigna-propia.md`, borrador sin aprobación docente aún).

## Fechas duras

| Hito | Fecha |
|---|---|
| Pre-entrega Blue Team (congelar con `git tag v1.0`) | **miércoles 07/10/2026** |
| Auditoría formal Blue Team (defensa MCU 5.0 + demo detección→respuesta) | miércoles 14/10/2026 |
| Pre-entrega Red Team | miércoles 28/10/2026 |
| Entrega final Red Team | lunes 09/11/2026 |

Los hitos internos H1 (21/09) y H2 (28/09) se vencieron sin avance; desde el 01/10 se
sigue [[plan-recuperacion-atraso]].

## Dónde vive todo

- **Repo:** <https://github.com/fmq203/TSI-2026-Infra> (público).
- **Despliegue:** cada integrante levanta su propio entorno. Camino estándar:
  **VirtualBox + Vagrant** (`vagrant/`). Uno de los integrantes tiene además un
  despliegue de referencia propio (Proxmox) donde se probaron los stacks; el otro no
  tiene acceso a él ni lo necesita. El historial de ese despliegue está en [[decisions]].

## Arquitectura (igual en cualquier despliegue)

- **Router/firewall:** OPNsense (recomendado por la letra) o, en VirtualBox, una VM Linux
  con nftables (automática, `vagrant/provision-router.sh`). Hace NAT, es el gateway
  `.254` de cada VLAN y aplica las reglas de `docs/40-consigna-propia.md` §2.
- **docker-host:** Linux + Docker con una NIC en cada VLAN (`.5` en todas). Corre todos
  los stacks de `infra/`. En Proxmox tiene que ser LXC **privilegiado**; en VirtualBox
  es una VM.
- **RF-06 (SOAR)** se resuelve con **Wazuh Active Response**, no con TheHive.

## Red

| VLAN | Rol | Subred | Gateway | Red Docker | Red interna VirtualBox | Interfaz OPNsense |
|---|---|---|---|---|---|---|
| — | "Internet" (WAN) | `203.0.113.0/24` en VirtualBox | `.254` | — | `vlan_wan` | WAN `vtnet0` |
| 10 | Servidores | `10.10.10.0/24` | `.254` | `net_srv` | `vlan_srv` | LAN `vtnet1` |
| 20 | DMZ | `10.10.20.0/24` | `.254` | `net_dmz` | `vlan_dmz` | OPT1 `vtnet2` |
| 30 | Usuarios | `10.10.30.0/24` | `.254` | `net_usr` | `vlan_usr` | OPT2 `vtnet3` |
| 90 | Gestión | `10.10.90.0/24` | `.254` | `net_mgmt` | `vlan_mgmt` | OPT3 `vtnet4` |

Ojo: **10 = Servidores, 20 = DMZ** (al revés de lo que asumía una versión vieja). Las
redes Docker son macvlan, creadas por `infra/create-networks.sh`.

## Contenedores (todos con IP fija)

| Stack | Contenedor | IP |
|---|---|---|
| identity | `keycloak` / `identity-db` | `10.10.90.20` / `.21` |
| siem-hids | `wazuh.manager` / `.indexer` / `.dashboard` | `10.10.90.10` / `.11` / `.12` |
| nids | `suricata` | `10.10.20.50` |
| mail | `mailserver` | `10.10.20.20` |
| honeypot | `cowrie` | `10.10.20.30` |
| targets | `target-webapp` (DVWA) / `target-app-db` | `10.10.10.10` / `.11` |
| targets | `target-ssh-client` (imagen propia `ssh-victim/`, SSH 2222 + agente Wazuh `ssh-client`) | `10.10.30.10` |
| (futuro) | `wazo` / `alerting` | `10.10.20.40` / `10.10.90.40` (reservadas) |

Todo contenedor nuevo con IP fija: el IPAM de Docker no sabe que `.5` es de
`docker-host` y `.254` del router, y podría asignarlas.

6 de 9 stacks construidos. **No construidos:** `wazo`, `alerting`,
`soar-thehive-optional` (este último no hace falta).

## Credenciales

- En el repo **no hay secretos**: solo `infra/*/.env.example` con contraseñas de
  laboratorio (`changeme` y similares). Al desplegar se copian a `.env` (gitignored)
  dentro de `docker-host`. Cambiarlas antes de la auditoría.
- Backups `config.xml` de OPNsense traen hashes de contraseña: nunca al repo
  (`.gitignore` los excluye).

## Pendientes

Lista mantenida en `README.md` → "Pendientes" (infra, documentación, seguridad) y estado
por día en [[plan-recuperacion-atraso]]. Al 06/10: Suricata y Cowrie conectados a Wazuh
(Cowrie sin verificar), CU-02 construido sin verificar, falta agente en `webapp` (CU-03),
MFA en Keycloak, y probar `vagrant up` de punta a punta en una máquina física.
Documentación al 07/10: borradores de 00, 01, 03, 04, 07, 09, 40, 99 y los 4 Excel MCU
(`docs/excel/`); faltan 06, 10, 11, 12, 28 y **toda la evidencia** (`docs/evidencias/`
vacía). Riesgos abiertos priorizados en `docs/03-analisis-riesgos.md`.

Orden de arranque de stacks: `identity nids honeypot siem-hids mail targets` — nids y
honeypot antes que siem-hids porque el manager monta sus volúmenes de logs como
`external`.
