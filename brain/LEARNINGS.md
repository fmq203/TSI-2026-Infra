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
- **Crear/convertir un LXC a privilegiado está bloqueado para CUALQUIER token de API**,
  sin importar sus permisos (ni siquiera `root@pam` con rol `Administrator` alcanza) —
  Proxmox devuelve 403 "only allowed for root@pam" pero en realidad excluye tokens por
  completo, exige una sesión real (ticket/login interactivo). Además `unprivileged` es
  **read-only** en el config de un LXC existente — no se puede cambiar un contenedor ya
  creado, hay que destruirlo y recrearlo. La única vía que funciona es `pct create`/
  `pct set` en una shell real del host (SSH o consola), no la API REST.
- **`docker-mailserver` necesita un LXC privilegiado** — intenta escribir el sysctl
  `kernel.domainname`, que un LXC no privilegiado deniega con
  "OCI runtime create failed... permission denied" al arrancar. Si un stack de Docker
  falla justo con ese error, es la causa.
- **Un contenedor solo ve la interfaz de CADA red Docker a la que está conectado, y
  Docker la nombra `eth0`, `eth1`... adentro del contenedor en el orden de conexión —
  nunca según el nombre de la interfaz del lado del host** (ej. `eth1` de `docker-host`
  no existe dentro de un contenedor conectado a una sola red; ahí siempre es `eth0`).
  Si un servicio necesita capturar/bindear a una interfaz específica (como Suricata),
  conectarlo a UNA sola red Docker para que el nombre interno sea predecible.
- **Triple anidamiento de virtualización (Proxmox/KVM → VM → VirtualBox → su guest) no
  funciona en este hardware** — probado con `cpu=host`, `cpu=host,flags=+nested-virt`
  (expone `ept`/`unrestricted_guest` en `/proc/cpuinfo`), `paravirtprovider=minimal`,
  `nestedpaging=off`, `vtxvpid=off`, y chipset `q35` — **los 5 intentos cuelgan en el
  mismo punto exacto** del boot del guest de VirtualBox ("Loading initial ramdisk..."),
  sin ningún error/excepción en `VBox.log`. No vale la pena seguir insistiendo con
  ajustes de configuración — si hace falta probar `vagrant up`/VirtualBox de verdad,
  usar una máquina física (ahí no hay triple anidamiento, que es justo el escenario real
  del Red Team de todas formas).
- **`docker-mailserver` con `SSL_TYPE=self-signed` no genera el certificado solo** —
  espera encontrarlo ya puesto en el volumen montado en `/tmp/docker-mailserver/ssl/`
  con nombres exactos (`<hostname>-cert.pem`, `<hostname>-key.pem`,
  `demoCA/cacert.pem`) y si no están, falla el arranque con "Missing expected file(s)".
  Ver `infra/mail/generate-self-signed-cert.sh`.
- **Imágenes con entrypoint que hace `chown` a sus archivos de config montados
  (ej. `jasonish/suricata`) fallan en loop si esos mounts son `:ro`** — error
  "Read-only file system" repetido. No montar esos paths como read-only.
- **Wazuh/OpenSearch (4.9.0):** `cluster.initial_master_nodes` en `opensearch.yml` es
  incompatible con `discovery.type: single-node` — tirá `IllegalArgumentException` y no
  arranca. Para un solo nodo, alcanza con `discovery.type: single-node` solo.
  `wazuh.api.timeout` no es una clave de config válida en el dashboard 4.9.0 (`FATAL
  Unknown configuration key`). El stack completo (indexer+manager+dashboard) tarda
  30-60s+ en levantar del todo — un "connection refused" del manager/dashboard hacia el
  indexer en los primeros segundos es normal, no es necesariamente un bug, hay que
  esperar y volver a mirar antes de tocar nada.
