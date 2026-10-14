# Bitácora de trabajo — Blue Team, Tarea 3

> Plantilla base: `plantilla/isaca/99-bitacora-trabajo.md` (SI-BIT-99). Equivalente en
> Excel: `04-bitacora-planilla.xlsx` (mismas columnas que la tabla resumen de §3).

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0** | **Gobernar** (GV-04) / **Responder** (RS-05) | Evidencia de ejecución, trazabilidad y mejora continua. |
| **BCU — GSI** | Requisito de documentación y trazabilidad | Registro verificable de las actividades de seguridad. |
| **URCDP — Ley 18.331, Art. 9** | Due diligence en tratamiento de datos | La bitácora documenta decisiones sobre datos personales. |
| **ISO/IEC 27001:2022** | A.5.1, A.5.24, A.8.15 | Evidencias del SGSI. |
| **COBIT 2019** | MEA01 (Supervisión y evaluación) | Registro auditable del desempeño. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-BIT-99 |
| Dueño | Blue Team — fmq203, Renzo Rampoldi |
| Período | 01/10/2026 → (abierta) |
| Versión | 1.0 |

Todas las horas en **UTC** (hora local de Uruguay = UTC−3).

---

## 1. Declaración de lagunas y de carga diferida

Lo que sigue se declara porque la letra exige que **no se omitan fallos** (LETRA.md §6.5)
y porque una bitácora reconstruida presentada como diaria no tiene valor de evidencia.

1. **14/09 → 30/09/2026: sin bitácora.** Hubo análisis inicial de la letra (14/09) pero
   no se registró trabajo diario, y los hitos H1 (21/09) y H2 (28/09) vencieron sin
   entregables. Esos días **no se reconstruyen**.
2. **01/10 → 06/10/2026: carga diferida.** El trabajo de esos días existió y es
   verificable, pero la bitácora no se cargó el mismo día. Las entradas de §2 se
   escribieron el **07/10/2026 (UTC)** a partir de fuentes con fecha y hora propias:
   commits de git (hash + hora UTC), `brain/decisions.md` y `brain/LEARNINGS.md`. La
   duración real de cada jornada no se registró: se indica el intervalo entre el primer y
   el último commit, que es una cota inferior.
3. **03/10 y 04/10/2026: sin actividad registrada** (no hay commits ni decisiones con esa
   fecha).
4. **Desde el 07/10/2026: registro diario**, el mismo día, firmado por quien hizo el
   trabajo.

Cada entrada de autoría de un integrante queda **pendiente de su firma** (§4) hasta que
la revise y confirme.

---

## 2. Entradas

---
Fecha: 01/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: diferida
---

### Actividad: Repo inicial y primeros stacks (redes, Suricata, Wazuh)

- **Fase**: Diseño / Implementación
- **Duración**: no registrada (commits entre 19:52 y 21:09 UTC)
- **Tarea realizada**: Creación del repo `TSI-2026-Infra` con la estructura de `infra/`.
  Se descubrió y documentó el trabajo previo en Proxmox (router OPNsense `opnrouter`) y se
  confirmó el mapeo real de VLANs: **10 = Servidores, 20 = DMZ**, gateway `.254`
  (contradecía la versión anterior de la documentación). `docker-host` se define como LXC
  privilegiado. Primeras correcciones de los stacks `nids` y `siem-hids`.
- **Herramienta / comando**: `docker network create` (macvlan), `docker compose up -d`
- **Resultado**: Parcial — stack Wazuh agregado (`09a1a1f`); Suricata arranca tras 4
  correcciones.
- **Evidencia anexa**: commits `4bf5ee1`, `ae4d817`, `e4b53a3`, `ed5aabf`, `a650c94`,
  `d1961d8`, `09a1a1f`; `brain/decisions.md` (entradas 2026-10-01).
- **Incidencia / hallazgo**: (1) `docker compose` no crea redes sin `services` → script
  `create-networks.sh`. (2) `suricata.yaml` no interpola `${VAR}` → interfaz fija. (3)
  Mounts `:ro` hacen que el entrypoint de Suricata falle en loop (`chown`). (4) Un
  contenedor ve cada red como `eth0`, `eth1`… → Suricata en una sola red. (5) El token
  de API de Proxmox no puede crear LXC privilegiados ni agregar NICs (detalle en
  `brain/LEARNINGS.md`).
- **Observaciones**: Se acordó el plan de recuperación por atraso
  (`brain/notes/plan-recuperacion-atraso.md`).

---
Fecha: 02/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: diferida
---

### Actividad: Wazuh operativo, documentación de arquitectura y despliegue portable (Vagrant)

- **Fase**: Implementación / Documentación
- **Duración**: no registrada (commits entre 11:48 y 19:29 UTC)
- **Tarea realizada**: Corrección de la config de OpenSearch para que el stack Wazuh
  arranque. Actualización de diagramas y READMEs contra la infra real. Se armó
  `vagrant/` para levantar toda la infraestructura desde cero en VirtualBox (para el
  compañero y el Red Team). Se intentó validar ese despliegue anidado dentro de Proxmox.
- **Herramienta / comando**: `docker compose up -d` (siem-hids); `vagrant up` dentro de
  una VM de prueba en Proxmox
- **Resultado**: Wazuh: éxito. Validación de `vagrant up` anidado: **fallida** (5
  intentos).
- **Evidencia anexa**: commits `9f171ac`, `85aa663`, `8b413f6`, `5c2b227`, `de4d635`,
  `8b244c2`, `d5b4cec`, `1a0b720`.
- **Incidencia / hallazgo**: (1) `cluster.initial_master_nodes` es incompatible con
  `discovery.type: single-node` (el indexer no arranca). (2) `wazuh.api.timeout` no es
  una clave válida en el dashboard 4.9.0. (3) Triple anidamiento (Proxmox → VM →
  VirtualBox) cuelga siempre en el mismo punto del boot: límite del hardware, se
  descarta; la validación queda para una máquina física.
- **Observaciones**: El repo queda autosuficiente para desplegar sin acceso al Proxmox de
  referencia.

---
Fecha: 05/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: diferida
---

### Actividad: CU-01 (reconocimiento) detectado de punta a punta

- **Fase**: Implementación / Prueba
- **Duración**: no registrada (commits entre 10:56 y 11:57 UTC)
- **Tarea realizada**: Conexión del `eve.json` de Suricata al manager de Wazuh. Ping y
  escaneo SYN desde la VLAN Servidores contra la DMZ. Regla local 100100 que sube las
  firmas propias de CU-01 (SIDs 1000001-1000005) a nivel 10 para que notifiquen.
- **Herramienta / comando**: ping, `nmap -sS`; `grep` sobre `eve.json` y `alerts.json`;
  `filebeat test output`; `curl wazuh.indexer:9200/_cat/indices/wazuh-alerts*`
- **Resultado**: **Éxito** — alertas 1000005 (barrido de ping) y 1000001 (escaneo SYN) en
  Suricata → regla 86601/100100 en Wazuh → visibles en el dashboard.
- **Evidencia anexa**: commits `69641b2`, `42f63e5`, `0ae9235`, `2ed8e4a`, `6a1b8f5`,
  `4117d59`. **Capturas: pendientes** (`docs/evidencias/` vacía al 07/10).
- **Incidencia / hallazgo**: Tres fallos encadenados antes del éxito: (1) checksums
  incompletos en NICs virtuales → Suricata descartaba paquetes; (2) `classtype` sin
  `classification.config`; (3) **causa real**: el firewall solo dejaba pasar TCP/443 de
  Servidores a DMZ, el escaneo nunca llegaba a Suricata. Después, el dashboard seguía
  vacío: Filebeat 7.10 no publicaba en OpenSearch 2.x (falta
  `compatibility.override_main_response_version`). Además, el dashboard de Wazuh pedía
  login sin backend de seguridad → se quitó el plugin (`0608ee5`). Detalle en
  `brain/LEARNINGS.md`.
- **Observaciones**: Registrado como incidente simulado INC-2026-001
  (`04-gestion-incidentes.md`).

### Actividad: CU-02 (fuerza bruta SSH) construido

- **Fase**: Implementación
- **Duración**: no registrada (commits 12:15 y 12:24 UTC)
- **Tarea realizada**: Imagen propia `targets/ssh-victim/` (OpenSSH + rsyslog + agente
  Wazuh 4.9.0). Active Response `firewall-drop` ante las reglas 5712/5763; mail de alertas
  nivel ≥ 10 a `soc@lab.local`.
- **Herramienta / comando**: `docker compose up -d --build` (targets),
  `siem-hids/configure-manager.sh`
- **Resultado**: Construido, **sin verificar** de punta a punta.
- **Evidencia anexa**: commits `fd562cf`, `481888a`.
- **Incidencia / hallazgo**: —
- **Observaciones**: Decisión de bloquear en el propio host y no en el router (ver
  `brain/decisions.md` 2026-10-05). El docente habilitó recortar alcance con
  justificación.

### Actividad: Logs de Suricata y Cowrie → Wazuh

- **Fase**: Implementación
- **Responsable**: Renzo Rampoldi
- **Duración**: no registrada (commit 23:58 UTC)
- **Tarea realizada**: Volumen de logs de Cowrie montado en el manager, `<localfile>` en
  `configure-manager.sh` y regla 100110 (login fallido en el honeypot, nivel 8).
- **Resultado**: Construido, **sin verificar** en el dashboard.
- **Evidencia anexa**: commit `be2e6b7`.
- **Incidencia / hallazgo**: Ver 07/10: en un despliegue desde cero rompía `make up`.

---
Fecha: 06/10/2026 · Equipo: Blue · Responsable: Renzo Rampoldi · Carga: diferida
---

### Actividad: Agente Wazuh para `targets`

- **Fase**: Implementación
- **Duración**: no registrada (commit 22:47 UTC)
- **Tarea realizada**: Contenedor `wazuh-agent` separado (`infra/targets/wazuh-agent/`) y
  `ssh-client` vuelto a la imagen `linuxserver/openssh-server`.
- **Resultado**: Revertido el 07/10 (ver abajo).
- **Evidencia anexa**: commit `ecf697c`.

---
Fecha: 07/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: el mismo día
---

### Actividad: Revisión de cambios del equipo y corrección de regresiones

- **Fase**: Prueba / Documentación
- **Duración**: no registrada (commits 01:56 y 01:59 UTC)
- **Tarea realizada**: Revisión de los commits `be2e6b7` y `ecf697c`. Se restauró
  `ssh-client` a la imagen `ssh-victim/` y se corrigió el orden de arranque de los stacks.
  Actualización del estado en README, `brain/MEMORY.md` y plan de recuperación.
- **Herramienta / comando**: `git diff`, revisión de `docker-compose.yml`, `Makefile`
- **Resultado**: Éxito (revisión de código; **no se desplegó** para probarlo).
- **Evidencia anexa**: commits `543c519`, `1e3e5a2`; `brain/decisions.md` 2026-10-06;
  `brain/LEARNINGS.md` 2026-10-06.
- **Incidencia / hallazgo**: (1) El agente en un contenedor aparte no comparte
  filesystem, red ni procesos con `ssh-client`: no veía su `auth.log` y sin `NET_ADMIN` el
  Active Response de CU-02 no podía bloquear. (2) `siem-hids` monta el volumen del
  honeypot como `external`, pero el honeypot arrancaba después: en un `vagrant up` limpio
  fallaba `make up` entero. No se notaba en un entorno donde el volumen ya existía.
- **Observaciones**: Cambios pendientes de push hasta coordinarlos con Renzo.

### Actividad: Documentación — incidentes, bitácora y Excel MCU

- **Fase**: Documentación
- **Duración**: no registrada (commits desde 02:08 UTC)
- **Tarea realizada**: `docs/04-gestion-incidentes.md` (severidades, procedimiento,
  INC-2026-001..003), esta bitácora, y los Excel `04-bitacora-planilla`,
  `02-registro-activos-mcu5` (A01-A22) y `03-matriz-raci-mcu5` (16 procesos + hoja de
  roles con propuesta de asignación).
- **Resultado**: Borradores. Commits `0ba84e1`, `b3ba156` y el de la RACI.
- **Incidencia / hallazgo**: Plazos de notificación BCU/URCDP no están en las plantillas
  del curso: quedan "a confirmar".
- **Observaciones**: Asignación de roles del equipo y dueños de activos pendiente de
  revisar entre los dos.

### Actividad: Excel de controles MCU 5.0 y documentos ISACA 01, 03, 07, 09

- **Fase**: Documentación
- **Duración**: no registrada
- **Tarea realizada**: `excel/01-controles-mcu5-perfil-avanzado.xlsx` (47 controles con
  aplica, estado y evidencia, + hoja Resumen con fórmulas). Política (`01`), análisis de
  riesgos (`03`, 13 riesgos), monitoreo y logs (`07`), gestión de accesos (`09`).
- **Resultado**: Borradores. No se pudo recalcular el Excel con LibreOffice (no está
  instalado): las fórmulas se verificaron en Python y el libro quedó marcado para
  recalcular al abrirse.
- **Incidencia / hallazgo**: Al revisar el repo para calificar controles: (1) Suricata
  solo carga las 5 reglas propias, ningún ruleset público (RF-03); (2) no hay retención
  de 90 días configurada (RF-15); (3) 4 imágenes en `:latest`; (4) el router deja salir a
  Internet desde todas las VLAN, incluida Servidores (camino de exfiltración, CU-05); (5)
  el dashboard de Wazuh sin plugin de seguridad no puede autenticar contra Keycloak:
  hay que elegir cómo ponerle MFA.
- **Observaciones**: Todo quedó como riesgo con tratamiento en `03-analisis-riesgos.md`.

### Actividad: Kit de evidencias y documentos 06, 11, 12

- **Fase**: Documentación
- **Duración**: no registrada
- **Tarea realizada**: `docs/evidencias/README.md` (procedimiento de captura de CU-01 y
  CU-02); continuidad (`06`), SoA con el Anexo A completo (`11`, 93 controles) y
  notificación (`12`, con un ejercicio de escritorio INC-2026-004). Push al repo
  compartido.
- **Resultado**: Borradores. La evidencia **no se capturó**: desde la sesión de trabajo
  no hay acceso de shell a `docker-host` por las vías permitidas; se corre en cada
  despliegue.
- **Incidencia / hallazgo**: La plantilla de SoA dice 79 controles; ISO 27001:2022 tiene
  93. No existe ningún respaldo de datos (RF-13).
- **Observaciones**: fmq203 le avisa a Renzo por fuera de los cambios a sus commits (pendiente al momento del push).

---

---
Fecha: 07/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: el mismo día
---

### Actividad: Despliegue de CU-02 y Cowrie en el entorno de referencia

- **Fase**: Implementación / Prueba
- **Duración**: no registrada (agente conectado a las 18:31 UTC)
- **Tarea realizada**: `git pull` en `docker-host` (estaba en `0472d64`, anterior a
  CU-02); `honeypot`, `siem-hids`, `mail` y `targets` levantados en orden;
  `configure-manager.sh` y `ensure-accounts.sh`. Reglas nuevas en OPNsense: OPT2 →
  `10.10.90.10` TCP 1514-1515, OPT3 → `10.10.20.20` TCP 25.
- **Herramienta / comando**: `pct exec 108 -- ...`; `nc -zv`; `ip neigh`; OPNsense
  Firewall → Rules / Live View
- **Resultado**: Éxito: agente `ssh-client` **Active** (ID 001), con FIM, SCA y rootcheck.
- **Evidencia anexa**: salida de `agent_control -l` (a guardar en `docs/evidencias/`).
- **Incidencia / hallazgo**: CU-02 nunca había estado desplegado en el entorno de
  referencia. El agente no enrolaba por timeout: faltaban las reglas y, ya creada, la de
  OPT2 tenía el rango en *Source port* en vez de *Destination port*. Detalle en
  `brain/LEARNINGS.md` (2026-10-07).
- **Observaciones**: La ejecución del ataque de CU-02 queda como siguiente paso.

---
Fecha: 11/10/2026 · Equipo: Blue · Responsable: Renzo Rampoldi · Carga: diferida
---

### Actividad: Evidencia real de CU-01/CU-02/CU-03 y CU-03 implementado; avance MFA Keycloak

- **Fase**: Implementación / Prueba
- **Duración**: no registrada (commit `40364c8`)
- **Tarea realizada**: Ejecución y captura de evidencia de los tres casos de uso. CU-03
  implementado de cero: imagen propia `targets/web-victim/` (DVWA + agente Wazuh embebido
  + FIM en tiempo real sobre `/var/www/html`), regla local `100200` (nivel 12, MITRE
  T1505.003) y Active Response `isolate-webapp`. Keycloak: realm `lab`, usuario de demo y
  TOTP validado; certificados de laboratorio generados (`identity/certs/`) para HTTPS
  futuro.
- **Herramienta / comando**: `nmap`, fuerza bruta SSH con usuario inexistente, alta de
  archivo `.php` en el webroot; capturas del dashboard y de la consola
- **Resultado**: CU-01, CU-02 y CU-03 verificados en **detección y respuesta**, con
  evidencia en `docs/evidencias/`. TOTP de Keycloak validado.
- **Evidencia anexa**: commit `40364c8`; `docs/evidencias/CU-01_INC-2026-001/`, `CU-02/`,
  `CU-03_INC-2026-003/` (capturas).
- **Incidencia / hallazgo**: La detección de CU-02 requirió atacar con un usuario
  **inexistente** (regla 5712), no con un usuario válido. La notificación por mail no se
  capturó en ninguno de los casos.
- **Observaciones**: Push directo a `main`.

---
Fecha: 14/10/2026 · Equipo: Blue · Responsable: fmq203 · Carga: el mismo día
---

### Actividad: Cierre de la notificación por mail (CU-02 y CU-03) de punta a punta

- **Fase**: Prueba / Documentación
- **Duración**: no registrada (commits `e5f5541`, `0925f6b`, `fcd653b`)
- **Tarea realizada**: `git pull` del commit de Renzo y actualización de toda la
  documentación a la evidencia real. Diagnóstico y cierre del eslabón de notificación,
  que nunca había funcionado: (1) faltaba la regla de firewall Gestión→DMZ TCP 25 en
  OPNsense; (2) Postfix rechazaba el mail del manager (`550 5.5.1 Protocol error`,
  filtro `postscreen`) porque `net_mgmt` no estaba en `mynetworks` — fix persistente en
  `infra/mail/config/postfix-main.cf`. Reenrolamiento del agente `webapp` (el contenedor
  vivo nunca se había recreado con la imagen `web-victim`) y sincronización de la regla
  `100200` al manager con `configure-manager.sh`.
- **Herramienta / comando**: `pct exec 108` (API Proxmox), `docker compose up -d
  --force-recreate`, `configure-manager.sh`, `postconf`, revisión del Maildir de
  `mailserver`
- **Resultado**: **Éxito** — CU-02 (regla 5712 → `firewall-drop` → mail, MTTD ≈13 s,
  MTTR ≈0 s, +24 s notificación) y CU-03 (regla 100200 → `isolate-webapp` → mail, MTTD/MTTR
  ≈0 s, +15 s notificación) verificados de punta a punta, notificación incluida.
- **Evidencia anexa**: `docs/evidencias/CU-02/2026-10-14_CU-02_mail.txt` y
  `_deteccion-respuesta.txt`; `docs/evidencias/CU-03_INC-2026-003/2026-10-14_CU-03_mail.txt`
  y `_reenrolamiento-y-cierre.txt`; `brain/LEARNINGS.md` 2026-10-14.
- **Incidencia / hallazgo**: (1) Dos causas de red/config tenían el mail caído hacía 14
  días sin que se notara (detección y respuesta sí funcionaban). (2) El agente de `webapp`
  se había perdido porque el contenedor nunca se recreó con la imagen nueva y el manager
  no tenía sincronizada la regla 100200 tras el pull.
- **Observaciones**: `infra/targets/wazuh-agent/` quedó como código muerto (el sidecar
  revertido el 06/10); CU-03 usa `web-victim/` con agente embebido.

### Actividad: Diagramas Mermaid de arquitectura y revisión de documentación

- **Fase**: Documentación
- **Duración**: no registrada (commits `29f89ae`, `5c07adf`, `04f48cf`, `a2f41a5`)
- **Tarea realizada**: Diagramas Mermaid en `docs/00-arquitectura.md` (topología de red +
  las 3 cadenas detección→respuesta→notificación) y en `infra/README.md` (stacks + orden
  de arranque de `make up`). Actualización de `04`, `07`, `09`, `11`, `12`, Excel 01,
  `docs/README.md`, README raíz y `brain/` al estado real.
- **Resultado**: Documentación alineada con el estado verificado al 14/10.
- **Evidencia anexa**: commits citados.
- **Incidencia / hallazgo**: La sintaxis `-.texto.->` de Mermaid no admite puntos en la
  etiqueta (rompía el render de GitHub con `eve.json`); corregido.
- **Observaciones**: —

## 3. Tabla resumen (formato Excel `04-bitacora-planilla.xlsx`)

| Fecha | Hora (UTC) | Fase | Responsable | Tarea | Herramienta/Comando | Resultado/Evidencia | Incidencia | Observaciones |
|---|---|---|---|---|---|---|---|---|
| 01/10/2026 | 19:52-21:09 | Diseño/Impl. | fmq203 | Repo inicial, redes, Suricata, Wazuh | docker network create, compose | Parcial — `4bf5ee1`..`09a1a1f` | 4 fallos de config resueltos | Carga diferida |
| 02/10/2026 | 11:48-19:29 | Impl./Doc. | fmq203 | Wazuh OK, docs, Vagrant | compose, vagrant up | Wazuh OK; Vagrant anidado fallido — `9f171ac`..`1a0b720` | Triple anidamiento no soportado | Carga diferida |
| 03/10/2026 | — | — | — | Sin actividad registrada | — | — | — | Laguna |
| 04/10/2026 | — | — | — | Sin actividad registrada | — | — | — | Laguna |
| 05/10/2026 | 10:56-11:57 | Impl./Prueba | fmq203 | CU-01 de punta a punta | nmap, ping, filebeat | Éxito — `69641b2`..`4117d59` | Firewall, checksums, Filebeat | INC-2026-001; carga diferida |
| 05/10/2026 | 12:15-12:24 | Impl. | fmq203 | CU-02 construido | compose --build | Sin verificar — `fd562cf` | — | Carga diferida |
| 05/10/2026 | 23:58 | Impl. | R. Rampoldi | Cowrie → Wazuh | configure-manager.sh | Sin verificar — `be2e6b7` | Rompía make up desde cero | Carga diferida |
| 06/10/2026 | 22:47 | Impl. | R. Rampoldi | Agente Wazuh en targets | compose | Revertido — `ecf697c` | Agente aislado del blanco | Carga diferida |
| 07/10/2026 | 01:56-01:59 | Prueba/Doc. | fmq203 | Corrección de regresiones | git diff | Éxito (sin desplegar) — `543c519`, `1e3e5a2` | 2 regresiones | Mismo día |
| 07/10/2026 | 02:08- | Doc. | fmq203 | Incidentes, bitácora, Excel 02/03/04 | — | Borradores — `0ba84e1`, `b3ba156`, … | Plazos BCU/URCDP sin fuente | Mismo día |
| 07/10/2026 | — | Doc. | fmq203 | Excel 01 + ISACA 01, 03, 07, 09 | — | Borradores | 5 brechas nuevas (ver entrada) | Mismo día |
| 07/10/2026 | — | Doc. | fmq203 | Kit de evidencias; 06, 11, 12; push | git push | Borradores | Sin respaldos de datos; SoA 93 vs 79 | Mismo día |
| 07/10/2026 | 18:31 | Impl./Prueba | fmq203 | Despliegue CU-02 + Cowrie en referencia | pct exec, nc, OPNsense | Agente `ssh-client` Active | CU-02 nunca desplegado; reglas FW faltantes | Mismo día |
| 11/10/2026 | — | Impl./Prueba | R. Rampoldi | Evidencia CU-01/02/03; CU-03 implementado; TOTP Keycloak | nmap, fuerza bruta, FIM | CU-01/02/03 detección+respuesta OK — `40364c8` | Sin captura de mail; CU-02 con usuario inexistente | Carga diferida |
| 14/10/2026 | — | Prueba/Doc. | fmq203 | Cierre notificación por mail CU-02/CU-03 | pct exec, compose, configure-manager, postconf | Éxito punta a punta — `e5f5541`, `0925f6b`, `fcd653b` | Mail caído 14d (FW + postscreen); agente webapp perdido | Mismo día |
| 14/10/2026 | — | Doc. | fmq203 | Diagramas Mermaid + revisión de docs | — | Docs alineadas — `29f89ae`..`a2f41a5` | Mermaid no admite puntos en etiquetas | Mismo día |

---

## 4. Firmas

Cada integrante confirma que las entradas con su nombre reflejan lo que hizo.

| Integrante | Entradas | Firma | Fecha |
|---|---|---|---|
| fmq203 | 01/10, 02/10, 05/10 (CU-01, CU-02), 07/10, 14/10 | ☐ pendiente | |
| Renzo Rampoldi | 05/10 (Cowrie), 06/10, 11/10 | ☐ pendiente | |

## Check de aceptación

- [ ] Registro diario sin lagunas superiores a 1 día — **no se cumple** antes del 07/10
  (ver §1); se cumple desde el 07/10 (con días sin actividad entre el 08 y el 10, y entre
  el 12 y el 13, declarados como sin trabajo registrado).
- [ ] Cada miembro firma sus entradas — pendiente (§4).
- [ ] Cada hallazgo del Red Team tiene su bitácora de ataque — a partir del 28/10.
- [x] Cada control auditado puede relacionarse con una o más entradas de bitácora — los
  controles de Detectar/Responder verificados (CU-01/02/03) tienen entrada con evidencia.
