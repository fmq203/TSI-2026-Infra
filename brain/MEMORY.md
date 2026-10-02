---
title: Hechos estables — Tarea 3 (foto del estado actual)
tags: [tarea3, memoria, arquitectura, fechas, estado]
updated: 2026-10-02
---

# Hechos estables — Tarea 3

> Este archivo es la **foto del estado actual**, no un historial. El "por qué" de cada
> cosa y cómo se llegó acá está en [[decisions]] (cronológico) y los errores ya pisados
> en [[LEARNINGS]]. Si algo de acá contradice al código o a Proxmox, manda lo real —
> actualizar este archivo.

## Marco general

- Curso: Seguridad de la Información (Tecnólogo). Tarea 3 = práctica integradora
  Blue Team / Red Team sobre una infraestructura de red de defensa real. (LETRA.md)
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

- **Repo de esta tarea:** <https://github.com/fmq203/TSI-2026-Infra> (público). Raíz =
  esta carpeta. El repo del curso (`FQ-TSI-2026`) NO contiene esta tarea.
- **Proxmox:** nodo `proxmox01` (`192.168.0.102:8006`), 6 cores / 23.28 GB, compartido
  con VMs/CTs que **no son de esta tarea** (no tocarlos).
- **De esta tarea en Proxmox:**

| ID | Nombre | Tipo | Rol |
|---|---|---|---|
| 124 | `opnrouter` | VM, OPNsense 26.1.2 | Router/firewall, gateway `.254` de las 4 VLANs, NAT |
| 108 | `docker-host` | LXC **privilegiado**, Debian 13, 2c/9GB | Corre todos los stacks Docker. Repo clonado en `/opt/TSI-2026-Infra` |
| 210 | `lab-srv-datos` | LXC Debian | Resto de un intento anterior, `10.10.10.20`. Sin decidir si se borra |
| 211 | `lab-web-dmz` | LXC Debian | Resto de un intento anterior, `10.10.20.10`. Sin decidir si se borra |
| 109 | `vbox-test-host` | VM, apagada | Prueba fallida de VirtualBox anidado (ver [[LEARNINGS]]). Se puede borrar |
| 120 | `kali` | VM | **No es de esta tarea**, pero está en la VLAN Servidores (`vmbr11`) — sirve para llegar a las consolas |

## Red (confirmada contra Proxmox y OPNsense real)

| VLAN | Rol | Subred | Gateway | Bridge Proxmox | Interfaz OPNsense |
|---|---|---|---|---|---|
| — | WAN | `192.168.0.0/24` (DHCP) | — | `vmbr0` | WAN `vtnet0` |
| 10 | Servidores | `10.10.10.0/24` | `.254` | `vmbr11` | LAN `vtnet1` |
| 20 | DMZ | `10.10.20.0/24` | `.254` | `vmbr12` | OPT1 `vtnet2` |
| 30 | Usuarios | `10.10.30.0/24` | `.254` | `vmbr1` | OPT2 `vtnet3` |
| 90 | Gestión | `10.10.90.0/24` | `.254` | `vmbr13` | OPT3 `vtnet4` |

Ojo: **10 = Servidores, 20 = DMZ** (al revés de lo que asumía una versión vieja).
`docker-host` tiene `.5` en cada VLAN (`eth0`..`eth3` en ese orden).

## Contenedores corriendo en `docker-host` (verificado 2026-10-02)

| Stack | Contenedor | IP | Cómo se asignó |
|---|---|---|---|
| identity | `keycloak` | `10.10.90.1` | dinámica (IPAM Docker) |
| identity | `identity-db` | `10.10.90.2` | dinámica |
| siem-hids | `wazuh.manager` / `.indexer` / `.dashboard` | `10.10.90.10` / `.11` / `.12` | fija |
| nids | `suricata` | `10.10.20.50` | fija |
| mail | `mailserver` | `10.10.20.20` | fija |
| honeypot | `cowrie` | `10.10.20.30` | fija |
| targets | `target-webapp` (DVWA) | `10.10.10.10` | fija |
| targets | `target-app-db` | `10.10.10.1` | dinámica |
| targets | `target-ssh-client` | `10.10.30.10` | fija |

6 de 9 stacks arriba (11 contenedores). **No construidos:** `wazo`, `alerting`.
`soar-thehive-optional` apagado a propósito (RF-06 se cubre con Wazuh Active Response).

⚠️ Riesgo latente: el IPAM de Docker no sabe que `.5` es de `docker-host` — si se agregan
contenedores sin IP fija en `net_mgmt`/`net_srv`, alguno puede caer en `.5` y chocar.
Dar IP fija a todo contenedor nuevo.

## Credenciales (dónde están — NUNCA en el repo)

- Tokens/keys que usó Claude están **solo en la máquina del integrante que los creó**
  (`Seguridad/Tarea/.env`, fuera del repo): token Proxmox `root@pam!claude-fq-tsi`,
  API key de OPNsense, key SSH `claude-code-tarea3`. **No se comparten**: el compañero
  debe crear los suyos si los necesita.
- Contraseñas de los servicios: las de cada `infra/*/.env.example` (valores de
  laboratorio tipo `changeme`) — son las que están **en uso hoy**. Cambiarlas antes de
  la auditoría.
- `config.xml` de OPNsense (backup real, trae hashes de contraseña): NO está en el repo,
  se pide al integrante que lo tiene.

## Pendientes (ver también `README.md` → "Para retomar")

- Infra: agente Wazuh en `targets` + regla OPNsense Servidores/Usuarios→Gestión
  1514/1515; **llevar los logs de Suricata (`eve.json`) y Cowrie a Wazuh** — hoy cada uno
  escribe en su volumen y Wazuh no los ve, sin esto no hay correlación (RF-05) ni se ve
  el CU-01 en el dashboard; MFA configurado dentro de Keycloak; playbooks de Active
  Response (RF-06, 3 casos); decidir mirror de tráfico para Suricata; `wazo` y
  `alerting`.
- Docs: toda la matriz ISACA salvo `00-arquitectura` y `40-consigna-propia` (borradores);
  Excel MCU; bitácora.
- Seguridad / limpieza: ver `README.md` → "Pendientes de seguridad".
