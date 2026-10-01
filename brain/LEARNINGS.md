---
title: Lecciones aprendidas — Tarea 3
tags: [tarea3, learnings]
updated: 2026-10-01
---

# Lecciones aprendidas — Tarea 3

Append-only: qué funcionó, qué no, y por qué.

- **2026-10-01 — Límites del MCP de Proxmox usado por Claude.** El token de API con el
  que opera no es `root@pam`: no puede crear LXC **privilegiados** (`create_container`
  con `unprivileged=false` da 403). Y ni `update_vm_config` (VMs) ni
  `update_container_network` (LXC) pueden **agregar** una interfaz de red nueva — solo
  modifican `net0` o una interfaz que ya existe en la config. Resultado práctico: crear
  el primer NIC de un host nuevo y subir cores/memoria sí se puede por API; agregar NICs
  adicionales (2da, 3ra, 4ta VLAN) y crear/editar bridges del host hay que hacerlo a mano
  desde la UI de Proxmox (o convertir el CT a privilegiado ahí si Docker lo necesita).
  No perder tiempo reintentando esas llamadas por API — es una restricción de permisos/
  capacidad de la herramienta, no un error transitorio.

- **2026-10-01 — Rodeando el límite anterior: API REST de Proxmox directa por `curl`.**
  Cuando el conector MCP no alcanza (crear bridge, agregar NICs), se puede pegarle
  directo a `https://192.168.0.102:8006/api2/json/...` con el token de
  `Seguridad/Tarea/.env` en el header `Authorization: PVEAPIToken=<id>=<secret>` — no
  hace falta CSRF token con auth por API token (solo con ticket/cookie). Funcionó para
  crear bridges (`POST .../network` + `PUT .../network` para aplicar) y para agregar
  NICs a VMs/CT (`PUT .../qemu/{vmid}/config` o `.../lxc/{vmid}/config` con `netN=...`).
- **Permisos reales de los roles predefinidos en Proxmox 9.2** (distinto a lo esperado):
  `PVESysAdmin` NO incluye `Sys.Modify` (solo Audit/Console/Syslog). Ningún rol
  predefinido entre `PVEAdmin` y `Administrator` lo incluye — está bundleado únicamente
  en `Administrator` (rol completo). Para crear/editar bridges de red del nodo no hay
  forma de dar un permiso acotado sin crear un rol custom a mano
  (`POST /access/roles`) — más rápido en este caso fue asignar `Administrator` al token.
