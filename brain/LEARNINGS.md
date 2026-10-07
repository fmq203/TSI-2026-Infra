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
- **2026-10-05 — Login del dashboard de Wazuh imposible con el indexer sin seguridad.**
  Con `DISABLE_SECURITY_PLUGIN=true` en el indexer, el dashboard igual muestra su login
  (plugin `securityDashboards`) y rechaza cualquier usuario, incluido `admin`/`admin`:
  no hay backend de seguridad contra el cual validar. Arreglo: el `entrypoint` del
  dashboard borra `plugins/securityDashboards` antes de arrancar, y se sacan del
  `opensearch_dashboards.yml` las claves `opensearch_security.*` (sin el plugin pasan a
  ser desconocidas y el dashboard no arranca). Resultado: web UI sin login.
- **2026-10-05 — Suricata veía tráfico (flows) pero no disparaba ninguna alerta: tres
  causas encadenadas.**
  1. En NICs virtuales los checksums llegan incompletos y Suricata descarta los
     paquetes: `af-packet: checksum-checks: no` y `stream: checksum-validation: no`.
     (`stream: midstream: true` para que los escaneos NULL/FIN/XMAS se inspeccionen.)
  2. `classtype` en las reglas + `classification-file` apuntando a una ruta que no
     existe en la imagen (Suricata 8 ya no lo tiene en `/etc/suricata/`). Ojo: en este
     caso `suricata -T` igual reportó "5 rules successfully loaded"; se sacó `classtype`
     de las reglas y las rutas fijas del yaml por las dudas.
  3. **La causa real del 0 final: el firewall.** El router (OPNsense, en el despliegue de
     referencia) solo dejaba pasar TCP/443 de Servidores a DMZ: el ping y el escaneo
     nunca llegaban a Suricata. Pista: en `eve.json` los únicos flows del atacante eran a
     `dest_port:443`; en el Live View de OPNsense no aparecían los bloqueos porque la
     regla de bloqueo por defecto estaba sin log. Diagnóstico rápido para la próxima:
     `grep '"src_ip":"<IP atacante>"' eve.json | tail` y mirar a qué puertos/protocolos
     llegó algo. Con una regla temporal de paso, la regla 1000005 (barrido de ping)
     disparó al toque.
- **Para probar las reglas de CU-01:** el atacante tiene que poder llegar a la IP de
  Suricata (`10.10.20.50`); hoy Suricata solo ve tráfico dirigido a sí mismo (macvlan),
  no el de los otros servicios de la DMZ.
- **2026-10-05 — Dashboard de Wazuh vacío aunque el manager tenía las alertas.** El
  manager escribía las alertas en `alerts.json` y `filebeat test output` daba OK, pero
  no existía ningún índice `wazuh-alerts-*`: Filebeat 7.10.2 no publica en un servidor
  que reporta OpenSearch 2.x. Arreglo: `compatibility.override_main_response_version:
  true` en el `opensearch.yml` del indexer (está en la config oficial de Wazuh; se había
  perdido al armar la config mínima). Recrear el indexer y reiniciar el manager; Filebeat
  manda también las alertas atrasadas. Diagnóstico por tramos que sirvió: (1) `grep
  suricata alerts.json` en el manager, (2) `filebeat test output`, (3) `curl
  wazuh.indexer:9200/_cat/indices/wazuh-alerts*`.

## 2026-10-06 — Volumen `external` de otro stack = dependencia de orden de arranque

`siem-hids` monta los volúmenes de logs de `nids` y `honeypot` como `external: true`.
Si ese stack no se levantó antes, `docker compose up` de `siem-hids` falla con
"external volume ... not found", y como `make up` corta con `|| exit 1`, no arranca
nada de lo que viene después. En un entorno donde el volumen ya existía (de un
despliegue anterior) el problema **no se ve** — solo aparece en un despliegue desde
cero (`vagrant up`). Regla: al montar un volumen de otro stack, mover ese stack antes en
`STACKS` del `Makefile` y en la guía manual de `infra/README.md`.

## 2026-10-07 — CU-02 nunca había corrido en el despliegue de referencia: tres causas

1. **`docker-host` estaba en `0472d64`** (05/10 11:57), el commit *anterior* al que
   construyó CU-02 (`fd562cf`): la imagen `ssh-victim`, el Active Response y el mail
   nunca se habían desplegado ahí. Antes de dar algo por "construido", mirar en qué commit
   está el entorno donde se va a mostrar (`git log -1` en `/opt/TSI-2026-Infra`).
2. **Faltaban las reglas de OPNsense** OPT2 (Usuarios) → `10.10.90.10` TCP 1514-1515 y
   OPT3 (Gestión) → `10.10.20.20` TCP 25. Una interfaz OPT nueva bloquea todo lo que
   entra. Síntoma: en el agente, `Unable to connect to enrollment service` cada ~2 min
   (timeout de TCP = paquete descartado; un "refused" inmediato habría sido el manager).
3. **La regla se creó con el rango en *Source port*** en lugar de *Destination port*. El
   agente sale de un puerto aleatorio *hacia* 1514/1515; con el rango en origen la regla
   no coincide nunca. En OPNsense, el *Source port* casi siempre queda en `any`.

Diagnóstico que funcionó, por tramos: `nc -zv` al 1515 desde un contenedor descartable en
`net_mgmt` (sin router: abrió → el manager está bien) y en `net_usr` (con router: timeout
→ es el firewall); `ip neigh` desde `docker-host` para confirmar capa 2 con la MAC de la NIC
del router; prueba con `/dev/tcp` desde la IP real del agente (una regla `/32` no cubre a
un contenedor de prueba con otra IP). Resultado 07/10 15:31 (UTC−3): `ssh-client` Active,
con FIM, SCA (CIS Debian 12) y rootcheck corriendo.
