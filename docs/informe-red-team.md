# Informe de evaluación técnica — Red Team

> Versión 1.0 del 31/10/2026, para la entrega del 09/11. El detalle de cada prueba está en
> [`informe-evidencias-redteam.md`](../docs-red-team/informe-evidencias-redteam.md).
> Los identificadores `RT-` de la letra son objetivos de ataque. Los hallazgos de este
> informe usan `H-`, para no mezclar las dos listas.
> RT-01 Parte B y los Events de Keycloak se toman del informe de evidencias (Andres, 28/10).
> No se rehicieron esas pruebas el 31/10.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0** | **Detectar** (DE-03) / **Responder** (RS-01) | Dos cadenas cerradas de punta a punta (fuerza bruta SSH y webshell). El resto de los objetivos de la §7.2 no tiene control, o el control no está aplicado en este despliegue. |
| **BCU — GSI** | Evaluación de controles | Insumo para corregir identidad, visibilidad del NIDS y el alcance de las reglas. |
| **ISO/IEC 27001:2022** | A.5.24 – A.5.28 | Lo que se detectó quedó con hora, evidencia y respuesta. Lo que no se detectó queda nombrado. |
| **ISO/IEC 27005 / 31000** | Riesgo | Prioridad en la sección 8, por severidad cualitativa. |
| **COBIT 2019** | MEA02 | Este informe es la evaluación del sistema de control del Blue Team. |

## Control del documento

| Campo | Valor |
|---|---|
| Título | Informe de evaluación técnica — Red Team |
| Código | `RT-T3-2026` |
| Cliente/cátedra | Cátedra Taller de Seguridad Informática |
| Periodo de evaluación | 25/10/2026 → 31/10/2026. Ventana de la letra: 28/10 → 09/11. |
| Equipo Red Team | Andres, Horacio, Pablo |
| Sistemas evaluados | Laboratorio FinSegura S.A. (Tarea 3), copia VirtualBox + Vagrant |
| Alcance autorizado | VLAN WAN `203.0.113.0/24`, Servidores `10.10.10.0/24`, DMZ `10.10.20.0/24`, Usuarios `10.10.30.0/24`, Gestión `10.10.90.0/24`, y el repositorio público |
| Versión | 1.0 |
| Fecha | 31/10/2026 |

## 1. Resumen ejecutivo

Se evaluó la infraestructura de defensa del Blue Team: firewall nftables, Suricata en la DMZ, Wazuh como SIEM y como SOAR (Active Response), Cowrie, DVWA como app de préstamos y Keycloak. Wazo y el segundo canal de alertas no están desplegados.

Los 12 objetivos de la letra (§7.2) están cerrados. La Parte B del RT-01, desde la WAN, hizo que Suricata viera los escaneos NULL y FIN y que Wazuh los subiera con la regla 100100. Los Events de Keycloak del RT-06 están revisados: la auditoría del realm `master` está apagada y no hay registros.

La defensa responde cuando el evento coincide con una regla que ya probaron: la fuerza bruta SSH se bloquea y avisa, y un `.php` nuevo en la app aísla el contenedor y avisa. Fuera de esa forma, la actividad no deja alerta. Las consolas de administración se abren sin segundo factor, y las contraseñas de arranque están en el repositorio público.

| Severidad cualitativa | Cantidad |
|---|---|
| Crítica | 2 |
| Alta | 11 |
| Media | 7 |
| Baja | 1 |
| Informativa | 1 |

El CVSS v3.1 está en la sección 4. La severidad de esa tabla sigue siendo la cualitativa del informe de evidencias: no se reescribió cuando el base da otro número. Donde difieren, la sección 4 lo dice. Madurez observada en MCU 5.0: Detectar y Responder funcionan en la fuerza bruta, en el PHP de la app y en el reconocimiento NULL/FIN desde la WAN. No cubren DNS, DoS, el login aceptado por el honeypot ni el acceso a las consolas.

## 2. Alcance y reglas de compromiso

Objetivos de la §7.2 y estado al 31/10:

| ID | Objetivo | Estado |
|---|---|---|
| RT-01 | Reconocimiento del perímetro evadiendo el NIDS | Cerrado. Parte A: desde Usuarios el tráfico no llega al sensor. Parte B: desde la WAN, NULL y FIN contra `10.10.20.50` disparan Suricata y la regla 100100. |
| RT-02 | Fuerza bruta SSH | Cerrado. El control funcionó. |
| RT-03 | Webshell / inyección en la app | Cerrado. El control funcionó. La app está en Servidores, no en la DMZ. |
| RT-04 | Honeypot | Cerrado. Cowrie acepta la sesión y no alerta. |
| RT-05 | Exfiltración DNS/TLS | Cerrado. No hay correlación. |
| RT-06 | Credenciales robadas contra consolas | Cerrado. Acceso con la cuenta de ejemplo (H-04.1, H-04.2, H-12.1). Events apagados: cero registros (H-04.3). |
| RT-07 | Evasión del SIEM | Cerrado. Reglas locales públicas y de coincidencia estrecha. |
| RT-08 | Wazo | Cerrado. El activo no existe. |
| RT-09 | MFA administrativo | Cerrado. El segundo factor no está en este despliegue. |
| RT-10 | Consola del SIEM | Cerrado. Se lee sin autenticación. |
| RT-11 | DoS acotado | Cerrado sin enviar tráfico. No hay regla de DoS. |
| RT-12 | OSINT del repositorio | Cerrado. Contraseñas de arranque en el árbol público. |

No se hizo denegación de servicio, ni exfiltración, ni inyección de logs. No se modificaron reglas. No se dejó un artefacto en el honeypot: la sesión se cerró con `exit`. El diagrama de red es el de `00-arquitectura.md`.

## 3. Metodología

Referencias usadas como marco: PTES, OWASP Testing Guide, MITRE ATT&CK y NIST SP 800-115. En esta preliminar se ejecutó reconocimiento, acceso a consolas, una subida a la app, un SSH al honeypot, revisión de reglas y OSINT del git. No hubo fase de post-explotación sobre un sistema operativo.

Herramientas: navegador por túnel SSH, cliente SSH de Kali, `ping`, `git`, y lectura de `local.rules` y `local_rules.xml`. El análisis estático (Trivy, Semgrep) y el contraste de CVE quedaron en CU-06 y CU-07.

## 4. Inventario de hallazgos

La columna de severidad es cualitativa. «Repro» es S cuando hay captura o comando en `evidencias/`, o cuando el repro es un archivo del repo. El CVSS es v3.1, base. Un guion significa que no es una debilidad: el control funcionó, o el activo no existe.

| ID | Activo | Tipo | Severidad | CVSS | Estado | Repro | MITRE |
|---|---|---|---|---|---|---|---|
| H-01.1 | Firewall | Segmentación efectiva desde Usuarios | — (control) | — | Observado | S | T1046 |
| H-01.2 | Firewall | SYN descartado y NULL/FIN con RST | Baja (observación) | 4.3 | Observado | S | T1046 |
| H-01.3 | Suricata / Wazuh | NULL/FIN desde la WAN detectados | — (control) | — | Observado 28/10 | S | T1046 |
| H-04.1 | Keycloak | Admin por defecto en `master` | Alta | 8.8 | Confirmado | S | T1078.001 |
| H-04.2 | Wazuh dashboard | Sin autenticación | Alta | 6.5 | Confirmado | S | T1078 |
| H-04.3 | Keycloak | Auditoría de Events apagada | Alta | 3.5 | Cerrado 28/10 | S | T1078 |
| H-R04.1 | Cowrie | Sesión aceptada, regla 100110 en cero | Media | 5.3 | Cerrado 28/10 | S | T1021.004 |
| H-05.1 | Suricata / Wazuh | Sin correlación de DNS | Media | 4.3 | Cerrado 28/10 | S | T1048 |
| H-R07.1 | Reglas locales | Públicas y de coincidencia estrecha | Media | 5.3 | Cerrado 28/10 | S | T1562 |
| H-EST-01 | Dockerfiles de blancos | Corren como root | Alta | 7.8 | Estático | S | — |
| H-EST-02 | Imagen DVWA | Tag `:latest` | Media | 4.8 | Estático | S | — |
| H-EST-03 | Scripts del manager | Expansiones sin comillas | Baja | 3.0 | Estático | S | — |
| H-07.1 | Wazuh 4.9.0 | CVE-2025-24016 | Crítica | 9.9 | Por versión | N | T1190 |
| H-07.2 | API Wazuh 4.9.0 | GHSA-gj9h-8hmr-xjjr | Alta | 8.2 | Por versión | N | T1078 |
| H-07.3 | Dashboard 4.9.0 | GHSA-648q-8m78-5cwv | Media | 4.6 | Por versión | N | T1078 |
| H-07.4 | Keycloak 26.0 | CVE-2026-18963 | Crítica | 9.1 | Por versión | N | T1078 |
| H-07.5 | Keycloak 26.0 | CVE-2026-7507 | Alta | 7.5 | Por versión | N | T1563 |
| H-07.6 | Keycloak 26.0 | CVE-2026-4634 | Alta | 7.5 | Por versión | N | T1499 |
| H-07.7 | App de préstamos | DVWA a propósito | Alta | 8.3 | Por diseño | S | T1190 |
| H-08.1 | Wazo | No desplegado | Informativa | — | Cerrado 27/10 | S | — |
| H-09.1 | Keycloak | MFA administrativo ausente | Alta | 8.1 | Cerrado 27/10 | S | T1078 |
| H-10.1 | Wazuh | Consola del SIEM sin login | Alta | 6.5 | Cerrado 27/10 | S | T1078 |
| H-11.1 | Suricata | Sin regla de DoS | Media | 5.3 | Cerrado 27/10 | S | T1499 |
| H-12.1 | Repositorio | Contraseñas de arranque públicas | Alta | 7.5 | Cerrado 28/10 | S | T1552 |
| H-00 | Agentes Wazuh | Detección caída tras un redespliegue | Media | 4.4 | Documentado | S | — |

### Vectores

Los de H-07.1 a H-07.6 son el base del aviso. No se ejecutó ese código. En este laboratorio la API de Wazuh y Keycloak no están publicados a la WAN: el vector oficial asume red. El informe de evidencias decía 9.0 para CVE-2025-24016. El vector del CNA es 9.9 y es el que queda acá.

El resto se calculó para este despliegue. Las consolas de Gestión usan vector adyacente, porque el firewall no publica 8080 ni 5601 hacia la WAN. El repositorio, el puerto 2222 y los huecos de detección de servicios alcanzables desde la WAN usan vector de red.

| ID | Vector | Por qué ese impacto |
|---|---|---|
| H-01.2 | `AV:A/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` | Desde Usuarios, la diferencia drop/RST deja ver que hay un filtro con estado. Confidencialidad baja. |
| H-04.1 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | `admin` / `changeme` da el realm `master`. La cuenta es pública, así que no se exige privilegio previo. |
| H-04.2 y H-10.1 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N` | El mismo hueco, dos id. Se leyeron agentes y alertas. No se modificó la configuración, por eso integridad ninguna. El 6.5 es medio y la severidad cualitativa sigue alta: lo que se lee es el SOC. |
| H-04.3 | `AV:A/AC:L/PR:L/UI:N/S:U/C:N/I:L/A:N` | La auditoría apagada, sola, no abre datos. Integridad baja del registro. El 3.5 es bajo. La severidad cualitativa sigue alta porque el acceso de H-04.1 no deja rastro. |
| H-R04.1 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N` | El 2222 está publicado. La sesión es el honeypot haciendo su trabajo. Lo que se puntúa es que esa acción no queda como alerta. |
| H-05.1 | `AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N` | Hueco de detección. No se envió una consulta DNS. Confidencialidad baja: un dato podría salir sin alerta. Hace falta un privilegio bajo en un host interno. |
| H-R07.1 | `AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` | El archivo de reglas es público. Se conoce el campo exacto que no va a alertar. |
| H-EST-01 | `AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` | El proceso del blanco corre como root. Hace falta ya estar dentro del contenedor. |
| H-EST-02 | `AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:L/A:N` | El tag `:latest` no fija el parche. No se resolvió la imagen ni se le asignó un CVE. |
| H-EST-03 | `AV:L/AC:H/PR:H/UI:N/S:U/C:L/I:L/A:N` | Expansiones sin comillas en scripts del manager. Hace falta un contexto local y privilegiado. |
| H-07.1 | `AV:N/AC:L/PR:L/UI:N/S:C/C:L/I:H/A:H` | Aviso. 9.9. |
| H-07.2 | `AV:N/AC:L/PR:H/UI:N/S:C/C:L/I:L/A:H` | Aviso. 8.2. |
| H-07.3 | `AV:N/AC:L/PR:L/UI:R/S:U/C:L/I:L/A:N` | Aviso. 4.6. En este laboratorio el efecto ya lo cubre H-04.2. |
| H-07.4 | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` | Aviso. 9.1. |
| H-07.5 | `AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:H` | Aviso. 7.5. |
| H-07.6 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H` | Aviso. 7.5. |
| H-07.7 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:L` | DVWA, desde la VLAN 30, con la cuenta de ejemplo. Se subió un marcador. No se ejecutó un shell. Disponibilidad baja por el aislamiento que sí corrió. |
| H-09.1 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` | No hay segundo factor. La cuenta de ejemplo alcanza para la consola de identidades. |
| H-11.1 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L` | No hay regla de volumen sobre los servicios publicados. No se envió tráfico. Disponibilidad baja: no se mostró que el servicio caiga, sí que no se vería. |
| H-12.1 | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N` | El repo público muestra las contraseñas. El uso de esas cuentas está en H-04.1, no se vuelve a sumar como integridad. |
| H-00 | `AV:L/AC:L/PR:H/UI:N/S:U/C:N/I:N/A:H` | Tras recrear el contenedor, el agente puede quedar afuera y la detección de ese host cae. Lo dispara quien redespliega. |

## 5. Detalle de hallazgos

El paso a paso y las horas están en `informe-evidencias-redteam.md`. Acá va el resultado. El vector de cada id está en la sección 4.

### H-04.1 y H-12.1 — Credenciales de arranque

La consola de Keycloak entra con el admin temporal del realm `master`. El `Makefile` copia los `.env.example` a `.env`, y el `README.md` publica esas cuentas. No hay clave privada ni `.env` en el historial de git. La auditoría de ese realm está apagada: `events_enabled` y `admin_events_enabled` en falso, y cero filas en las tablas de eventos (H-04.3). El login con la cuenta de ejemplo no deja rastro y Keycloak no reenvía esos logs a Wazuh. Recomendación: sacar los valores reales del árbol público, rotar lo que ya se desplegó con el ejemplo, y prender Events.

### H-04.2, H-09.1 y H-10.1 — Consolas sin segundo factor

El realm `lab`, donde el Blue Team documentó TOTP, no existe en esta copia. El selector de realms muestra solo `master`, sin pedido de código. `http://localhost:5601/app/home` abre sin login; desde el menú se ven los agentes y 234 eventos de Threat Hunting, entre ellos fuerza bruta y webshell. Recomendación: exigir MFA en la consola de identidades y volver a poner autenticación delante del dashboard.

### H-R04.1 — Honeypot

Desde Kali, por la WAN, Cowrie aceptó `nosoy@10.10.20.30:2222` y dio un prompt. La regla `100110` no devolvió resultados: solo coincide con `cowrie.login.failed`, y además es nivel 8, por debajo del mail. Recomendación: alertar también el login aceptado, en nivel 10 o más.

### H-05.1 y H-11.1 — Huecos de visibilidad

No hay firma de DNS, de exfiltración ni de DoS. Suricata está en `10.10.20.50` y no tiene espejo del resto de la red. Esas pruebas no se ejecutaron: no había alerta que medir. Recomendación: espejo hacia el NIDS y una regla para volumen de DNS y para denegación de servicio.

### H-R07.1 — Reglas locales

`local_rules.xml` está en el repo. La `100100`, la `100110` y la `100200` exigen un campo concreto. El ruleset de serie sigue activo. El ingreso aceptado en Cowrie ya mostró que lo que no coincide no alerta. Recomendación: no publicar el archivo de reglas con el mismo detalle, y ampliar las condiciones.

### H-08.1 — Wazo

No hay contenedor. `10.10.20.40` no responde. El objetivo no es ejecutable. El firewall igual publica UDP 5060 hacia la DMZ.

### H-07.1 a H-07.7 y H-EST-01 a H-EST-03

Contraste de versiones y análisis estático, sin tráfico. Wazuh 4.9.0 y Keycloak `26.0` caen en avisos críticos y altos. DVWA es vulnerable a propósito. Los Dockerfiles de los blancos corren como root. El repro de cada CVE no se ejecutó. El detalle está en las secciones CU-06 y CU-07 del informe de evidencias.

### H-00 y H-01

Tras un redespliegue, los agentes pueden quedar desenrolados y la app no arranca si el enrolamiento falla. Desde la VLAN Usuarios, la segmentación impide el reconocimiento hacia Servidores y la DMZ (H-01.1). El firewall descarta el SYN y responde RST al NULL/FIN (H-01.2). Desde la WAN, el NULL y el FIN contra `10.10.20.50` sí llegan al sensor: Suricata emitió las firmas 1000002 y 1000003, y Wazuh las subió con la regla 100100, nivel 10, sin bloqueo (H-01.3). El SYN de tres puertos no alcanzó el umbral de 20 en 10 segundos, y el escaneo al honeypot `.30` no lo ve Suricata.

## 6. Mapeo a MITRE ATT&CK

| Táctica | Técnica | Qué pasó |
|---|---|---|
| Discovery | T1046 Network Service Discovery | Parte A: la segmentación contuvo el escaneo y Suricata no lo vio. Parte B: NULL y FIN desde la WAN, detectados (1000002, 1000003, regla 100100). |
| Credential Access | T1110 Brute Force | CU-02. Wazuh 5763 y `firewall-drop`. Detectado y bloqueado. |
| Persistence | T1505.003 Web Shell | CU-03. Regla 100200 e `isolate-webapp`. Detectado y aislado. |
| Initial Access | T1078 Valid Accounts | H-04.1, H-09.1, H-10.1, H-12.1. Consolas y contraseñas de ejemplo. |
| Lateral Movement | T1021.004 SSH | H-R04.1. Sesión aceptada por Cowrie, sin alerta. |
| Exfiltration | T1048 | H-05.1. Sin regla. |
| Defense Evasion | T1562 Impair Defenses | H-R07.1. Reglas públicas y estrechas. |
| Impact | T1499 Endpoint Denial of Service | H-11.1. Sin regla. No se envió tráfico. |

## 7. Evaluación de la respuesta del Blue Team

| Ataque | Detección | Respuesta | Mail |
|---|---|---|---|
| CU-02, fuerza bruta SSH, 25/10 | Regla 5763, nivel 10, ~3 s | `firewall-drop`, ~3 s | Sí, ~15 s |
| CU-03, PHP en la app, 25/10 | Regla 100200, nivel 12, mismo segundo | `isolate-webapp`, mismo segundo | Sí, ~14 s |
| CU-01 Parte A, 25/10 | Suricata: 0 eventos | La segmentación descartó el tráfico antes | No |
| CU-01 Parte B, 28/10 | Suricata 1000002 y 1000003; Wazuh 100100, nivel 10 | Ninguna. El diseño no bloquea el reconocimiento | El nivel 10 está en el umbral del mail. El buzón no se revisó en esta prueba |
| RT-04, sesión en Cowrie, 28/10 | Regla 100110: 0 resultados | Ninguna | No |
| RT-05, RT-07, RT-11 | No hay regla que matchee | Ninguna | No |
| RT-09, RT-10 | La consola no pide usuario | No aplica | No |

Los dos playbooks que el Blue Team cerró (bloqueo de IP y aislamiento) funcionan y notifican. TheHive no está; el SOAR es el Active Response de Wazuh. El MFA administrativo declarado en `09-gestion-accesos.md` no está aplicado en este despliegue. La SoA pide una detección que en DNS, DoS y honeypot aceptado no existe.

## 8. Lecciones aprendidas y recomendaciones

En este orden:

1. Poner autenticación y MFA delante del dashboard y de la consola de Keycloak. Importar el realm con TOTP, o dejar de declararlo.
2. Sacar las contraseñas de arranque del repositorio público y rotar las que ya se copiaron a `.env`.
3. Alertar el login aceptado de Cowrie, en un nivel que también mande mail.
4. Darle a Suricata visibilidad más allá de `10.10.20.50`, y sumar reglas de DNS y de DoS.
5. Actualizar Wazuh 4.9.0 y Keycloak `26.0`, que concentran los dos hallazgos críticos por versión.
6. Dejar de publicar `local_rules.xml` con el campo exacto que cada regla exige.

## 9. Anexos

- Anexo A — Bitácora: [`bitacora.md`](../docs-red-team/bitacora.md).
- Anexo B — Evidencias: `docs-red-team/evidencias/`. CU-01 a CU-03 y CU-06 a CU-07 son casos de uso. RT-04, RT-05 y RT-07 a RT-12 son objetivos de la letra que no comparten número con un CU.
- Anexo C — Conteo al 31/10: 12 objetivos de la letra, los 12 cerrados. Hallazgos de la sección 4: 2 críticos, 11 altos, 7 medios, 1 bajo, 1 informativo, más H-01.1, H-01.2 y H-01.3, que son observaciones del reconocimiento y no una debilidad explotada. H-04.3 entra en los 11 altos por la severidad cualitativa. Su base es 3.5.

Queda fuera de este archivo la presentación de 10 minutos del 09/11.
