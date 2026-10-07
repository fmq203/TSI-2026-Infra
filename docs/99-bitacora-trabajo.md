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

---

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

---

## 4. Firmas

Cada integrante confirma que las entradas con su nombre reflejan lo que hizo.

| Integrante | Entradas | Firma | Fecha |
|---|---|---|---|
| fmq203 | 01/10, 02/10, 05/10 (CU-01, CU-02), 07/10 | ☐ pendiente | |
| Renzo Rampoldi | 05/10 (Cowrie), 06/10 | ☐ pendiente | |

## Check de aceptación

- [ ] Registro diario sin lagunas superiores a 1 día — **no se cumple** antes del 07/10
  (ver §1); se cumple desde el 07/10.
- [ ] Cada miembro firma sus entradas — pendiente (§4).
- [ ] Cada hallazgo del Red Team tiene su bitácora de ataque — a partir del 28/10.
- [ ] Cada control auditado puede relacionarse con una o más entradas de bitácora.
