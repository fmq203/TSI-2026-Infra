# Informe de evaluación técnica — Red Team

> Versión 1.1 del 31/10/2026, para la entrega del 09/11. El detalle de cada prueba está en
> [`informe-evidencias-redteam.md`](informe-evidencias-redteam.md).
>
> **Nomenclatura (actualizada 31/10):** el trabajo se organiza en dos ejes —
> **RT-01 a RT-12**, los objetivos de ataque de la letra, y **AE-01 / AE-02**, los
> análisis estático y documental que no son objetivos de la letra. Los **hallazgos usan
> numeración corrida `H-01` a `H-25`**; la columna *Objetivo* de la §4 liga cada hallazgo
> a su RT o AE. Este esquema reemplaza los identificadores previos (`H-04.1`, `H-R07.1`,
> `H-EST-01`, las carpetas `CU-…`), que mezclaban casos de uso del Blue Team con objetivos
> de la letra. RT-01 Parte B y los Events de Keycloak se toman del informe de evidencias
> (Andres, 28/10).

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
| Versión | 1.1 |
| Fecha | 31/10/2026 |

## 1. Resumen ejecutivo

Se evaluó la infraestructura de defensa del Blue Team: firewall nftables, Suricata en la DMZ, Wazuh como SIEM y como SOAR (Active Response), Cowrie, DVWA como app de préstamos y Keycloak. Wazo y el segundo canal de alertas no están desplegados.

Los 12 objetivos de la letra (§7.2) tienen estado documentado. La Parte B del RT-01, desde la WAN, hizo que Suricata viera los escaneos NULL y FIN y que Wazuh los subiera con la regla 100100. Para RT-06 se documenta el acceso con la cuenta de ejemplo de Keycloak, la consola Wazuh sin autenticación y la revisión de Events: la auditoría del realm `master` está apagada y no hay registros. No se probó una credencial obtenida mediante robo; el cierre se limita a esos accesos observados.

La defensa responde cuando el evento coincide con una regla que ya probaron: la fuerza bruta SSH se bloquea y avisa, y un `.php` nuevo en la app aísla el contenedor y avisa. Fuera de esa forma, la actividad no deja alerta. Las consolas de administración se abren sin segundo factor, y las contraseñas de arranque están en el repositorio público.

| Severidad cualitativa | Cantidad |
|---|---|
| Crítica | 2 |
| Alta | 11 |
| Media | 8 |
| Baja | 1 |
| Informativa | 1 |

Los hallazgos H-01, H-02 y H-03 son observaciones del reconocimiento (dos de ellas, controles que funcionaron) y no entran en el conteo de arriba. El CVSS v3.1 está en la sección 4. La severidad de esa tabla sigue siendo la cualitativa del informe de evidencias: no se reescribió cuando el base da otro número. Donde difieren, la sección 4 lo dice. Madurez observada en MCU 5.0: Detectar y Responder funcionan en la fuerza bruta, en el PHP de la app y en el reconocimiento NULL/FIN desde la WAN. No cubren DNS, DoS, el login aceptado por el honeypot ni el acceso a las consolas.

## 2. Alcance y reglas de compromiso

Objetivos de la §7.2 y estado al 31/10:

| ID | Objetivo | Estado |
|---|---|---|
| RT-01 | Reconocimiento del perímetro evadiendo el NIDS | Cerrado. Parte A: desde Usuarios el tráfico no llega al sensor. Parte B: desde la WAN, NULL y FIN contra `10.10.20.50` disparan Suricata y la regla 100100. |
| RT-02 | Fuerza bruta SSH | Cerrado. El control funcionó. |
| RT-03 | Webshell / inyección en la app | Cerrado. El control funcionó. La app está en Servidores, no en la DMZ. |
| RT-04 | Honeypot | Cerrado. Cowrie acepta la sesión y no alerta. |
| RT-05 | Exfiltración DNS/TLS | Cerrado. No hay correlación. |
| RT-06 | Credenciales robadas contra consolas | Cerrado: acceso con la cuenta de ejemplo de Keycloak (H-04), consola Wazuh sin autenticación (H-05) y Events apagados con cero registros (H-06). No se probó una credencial obtenida mediante robo. |
| RT-07 | Evasión del SIEM | Cerrado. Reglas locales públicas y de coincidencia estrecha. |
| RT-08 | Wazo | Cerrado. El activo no existe. |
| RT-09 | MFA administrativo | Cerrado. El segundo factor no está en este despliegue. |
| RT-10 | Consola del SIEM | Cerrado. Se lee sin autenticación. |
| RT-11 | DoS acotado | Cerrado sin enviar tráfico. No hay regla de DoS. |
| RT-12 | OSINT del repositorio | Cerrado. Contraseñas de arranque en el árbol público. |

Fuera de la letra, dos análisis sin tráfico contra el laboratorio: **AE-01** (inspección estática con Trivy y Semgrep) y **AE-02** (avisos públicos y auditoría de dependencias por versión).

No se hizo denegación de servicio, ni exfiltración, ni inyección de logs. No se modificaron reglas. No se dejó un artefacto en el honeypot: la sesión se cerró con `exit`. El diagrama de red es el de `docs/00-arquitectura.md`.

## 3. Metodología

Referencias usadas como marco: PTES, OWASP Testing Guide, MITRE ATT&CK y NIST SP 800-115. Se ejecutó reconocimiento, acceso a consolas, una subida a la app, un SSH al honeypot, revisión de reglas y OSINT del git. No hubo fase de post-explotación sobre un sistema operativo.

Herramientas: navegador por túnel SSH, cliente SSH de Kali, `ping`, `git`, y lectura de `local.rules` y `local_rules.xml`. El análisis estático (Trivy, Semgrep) y el contraste de CVE quedaron en AE-01 y AE-02.

## 4. Inventario de hallazgos

La columna de severidad es cualitativa. La columna **Objetivo** liga el hallazgo a un objetivo de la letra (RT) o a un análisis (AE); «Transversal» es un hallazgo de entorno. «Repro» es S cuando hay captura o comando en `evidencias/`, o cuando el repro es un archivo del repo. El CVSS es v3.1, base. Un guion significa que no es una debilidad: el control funcionó, o el activo no existe.

| ID | Activo | Tipo | Objetivo | Severidad | CVSS | Estado | Repro | MITRE |
|---|---|---|---|---|---|---|---|---|
| H-01 | Firewall | Segmentación efectiva desde Usuarios | RT-01 | — (control) | — | Observado | S | T1046 |
| H-02 | Firewall | SYN descartado y NULL/FIN con RST | RT-01 | Baja (obs.) | 4.3 | Observado | S | T1046 |
| H-03 | Suricata / Wazuh | NULL/FIN desde la WAN detectados | RT-01 | — (control) | — | Observado 28/10 | S | T1046 |
| H-04 | Keycloak | Admin por defecto en `master` | RT-06 | Alta | 8.8 | Confirmado | S | T1078.001 |
| H-05 | Wazuh dashboard | Sin autenticación (RT-06 y RT-10) | RT-06 / RT-10 | Alta | 6.5 | Confirmado | S | T1078 |
| H-06 | Keycloak | Auditoría de Events apagada | RT-06 | Alta | 3.5 | Cerrado 28/10 | S | T1078 |
| H-07 | Cowrie | Sesión aceptada, regla 100110 en cero | RT-04 | Media | 5.3 | Cerrado 28/10 | S | T1021.004 |
| H-08 | Suricata / Wazuh | Sin correlación de DNS | RT-05 | Media | 4.3 | Cerrado 28/10 | S | T1048 |
| H-09 | Reglas locales | Públicas y de coincidencia estrecha | RT-07 | Media | 5.3 | Cerrado 28/10 | S | T1562 |
| H-10 | Dockerfiles de blancos | Corren como root | AE-01 | Alta | 7.8 | Estático | S | — |
| H-11 | Imagen DVWA | Tag `:latest` | AE-01 | Media | 4.8 | Estático | S | — |
| H-12 | Scripts del manager | Expansiones sin comillas | AE-01 | Baja | 3.0 | Estático | S | — |
| H-13 | Wazuh 4.9.0 | CVE-2025-24016 | AE-02 | Crítica | 9.9 | Por versión | N | T1190 |
| H-14 | API Wazuh 4.9.0 | GHSA-gj9h-8hmr-xjjr | AE-02 | Alta | 8.2 | Por versión | N | T1078 |
| H-15 | Dashboard 4.9.0 | GHSA-648q-8m78-5cwv | AE-02 | Media | 4.6 | Por versión | N | T1078 |
| H-16 | Keycloak 26.0 | CVE-2026-18963 | AE-02 | Crítica | 9.1 | Por versión | N | T1078 |
| H-17 | Keycloak 26.0 | CVE-2026-7507 | AE-02 | Alta | 7.5 | Por versión | N | T1563 |
| H-18 | Keycloak 26.0 | CVE-2026-4634 | AE-02 | Alta | 7.5 | Por versión | N | T1499 |
| H-19 | App de préstamos | DVWA a propósito | AE-02 | Alta | 8.3 | Por diseño | S | T1190 |
| H-26 | Wazuh dashboard 4.9.0 | CVE-2025-64483 (creds de enrolamiento) | AE-02 | Media | 5.3 | Por versión | N | T1078 |
| H-27 | web-victim (Debian Stretch) | Base EOL + APT sin autenticar (`trusted=yes`, `--allow-unauthenticated`) | AE-02 | Alta | — | Estático | S | — |
| H-20 | Wazo | No desplegado | RT-08 | Informativa | — | Cerrado 27/10 | S | — |
| H-21 | Keycloak | MFA administrativo ausente | RT-09 | Alta | 8.1 | Cerrado 27/10 | S | T1078 |
| H-23 | Suricata | Sin regla de DoS | RT-11 | Media | 5.3 | Cerrado 27/10 | S | T1499 |
| H-24 | Repositorio | Contraseñas de arranque públicas | RT-12 | Alta | 7.5 | Cerrado 28/10 | S | T1552 |
| H-25 | Agentes Wazuh | Detección caída tras un redespliegue | Transversal | Media | 4.4 | Documentado | S | — |

> H-05 es el dashboard de Wazuh sin autenticación. Aparece tanto en RT-06 (uso de credenciales) como en RT-10 (consola del SIEM), pero es **una sola debilidad y se cuenta una vez**. El id H-22, que antes duplicaba este hueco, se retiró (unificado en H-05); por eso la numeración salta de H-21 a H-23.
>
> **Nota — tres hallazgos tocan el dashboard de Wazuh, pero son distintos:** **H-05** es el problema real y demostrado (abre **sin autenticación**); **H-15** y **H-26** son **avisos por versión** del mismo componente (4.9.0) — un rol de pocos privilegios podría ver los agentes (H-15) o leer credenciales de enrolamiento (H-26). En la práctica H-05 ya cubre el efecto de ambos (si no hay login, el rol no importa); se listan aparte porque son CVE/avisos **distintos**, no debilidades repetidas. Lo mismo con los CVE de Keycloak (H-16, H-17, H-18): mismo producto, tres avisos diferentes.

### Vectores

Los de H-13 a H-18 son el base del aviso. No se ejecutó ese código. En este laboratorio la API de Wazuh y Keycloak no están publicados a la WAN: el vector oficial asume red. El informe de evidencias decía 9.0 para CVE-2025-24016. El vector del CNA es 9.9 y es el que queda acá.

El resto se calculó para este despliegue. Las consolas de Gestión usan vector adyacente, porque el firewall no publica 8080 ni 5601 hacia la WAN. El repositorio, el puerto 2222 y los huecos de detección de servicios alcanzables desde la WAN usan vector de red.

| ID | Vector | Por qué ese impacto |
|---|---|---|
| H-02 | `AV:A/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` | Desde Usuarios, la diferencia drop/RST deja ver que hay un filtro con estado. Confidencialidad baja. |
| H-04 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | `admin` / `changeme` da el realm `master`. La cuenta es pública, así que no se exige privilegio previo. |
| H-05 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N` | El dashboard sin autenticación (surge en RT-06 y RT-10). Se leyeron agentes y alertas. No se modificó la configuración, por eso integridad ninguna. El 6.5 es medio y la severidad cualitativa sigue alta: lo que se lee es el SOC. |
| H-06 | `AV:A/AC:L/PR:L/UI:N/S:U/C:N/I:L/A:N` | La auditoría apagada, sola, no abre datos. Integridad baja del registro. El 3.5 es bajo. La severidad cualitativa sigue alta porque el acceso de H-04 no deja rastro. |
| H-07 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N` | El 2222 está publicado. La sesión es el honeypot haciendo su trabajo. Lo que se puntúa es que esa acción no queda como alerta. |
| H-08 | `AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N` | Hueco de detección. No se envió una consulta DNS. Confidencialidad baja: un dato podría salir sin alerta. Hace falta un privilegio bajo en un host interno. |
| H-09 | `AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` | El archivo de reglas es público. Se conoce el campo exacto que no va a alertar. |
| H-10 | `AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` | El proceso del blanco corre como root. Hace falta ya estar dentro del contenedor. |
| H-11 | `AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:L/A:N` | El tag `:latest` no fija el parche. No se resolvió la imagen ni se le asignó un CVE. |
| H-12 | `AV:L/AC:H/PR:H/UI:N/S:U/C:L/I:L/A:N` | Expansiones sin comillas en scripts del manager. Hace falta un contexto local y privilegiado. |
| H-13 | `AV:N/AC:L/PR:L/UI:N/S:C/C:L/I:H/A:H` | Aviso. 9.9. |
| H-14 | `AV:N/AC:L/PR:H/UI:N/S:C/C:L/I:L/A:H` | Aviso. 8.2. |
| H-15 | `AV:N/AC:L/PR:L/UI:R/S:U/C:L/I:L/A:N` | Aviso. 4.6. En este laboratorio el efecto ya lo cubre H-05. |
| H-16 | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` | Aviso. 9.1. |
| H-17 | `AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:H` | Aviso. 7.5. |
| H-18 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H` | Aviso. 7.5. |
| H-19 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:L` | DVWA, desde la VLAN 30, con la cuenta de ejemplo. Se subió un marcador. No se ejecutó un shell. Disponibilidad baja por el aislamiento que sí corrió. |
| H-21 | `AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` | No hay segundo factor. La cuenta de ejemplo alcanza para la consola de identidades. |
| H-23 | `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L` | No hay regla de volumen sobre los servicios publicados. No se envió tráfico. Disponibilidad baja: no se mostró que el servicio caiga, sí que no se vería. |
| H-24 | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N` | El repo público muestra las contraseñas. El uso de esas cuentas está en H-04, no se vuelve a sumar como integridad. |
| H-25 | `AV:L/AC:L/PR:H/UI:N/S:U/C:N/I:N/A:H` | Tras recrear el contenedor, el agente puede quedar afuera y la detección de ese host cae. Lo dispara quien redespliega. |
| H-26 | `AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N` | Aviso. Un rol de solo lectura podría leer las credenciales de enrolamiento del dashboard. 5.3. |
| H-27 | (sin CVSS) | Base Debian Stretch fuera de soporte (fin de LTS 2022) y repos APT por HTTP con `trusted=yes` / `--allow-unauthenticated`. Riesgo de cadena de suministro e integridad de la build, no un CVE puntual; sin imagen resuelta no se atribuye versión de paquete. |

## 5. Detalle de hallazgos

El paso a paso y las horas están en `informe-evidencias-redteam.md`. Acá va el resultado. El vector de cada id está en la sección 4.

### H-04, H-06 y H-24 — Credenciales y auditoría de Keycloak

La consola de Keycloak entra con el admin temporal del realm `master`. El `Makefile` copia los `.env.example` a `.env`, y el `README.md` publica esas cuentas. No hay clave privada ni `.env` en el historial de git. La auditoría de ese realm está apagada: `events_enabled` y `admin_events_enabled` en falso, y cero filas en las tablas de eventos (H-06). El login con la cuenta de ejemplo no deja rastro y Keycloak no reenvía esos logs a Wazuh. Recomendación: sacar los valores reales del árbol público, rotar lo que ya se desplegó con el ejemplo, y prender Events.

### H-05 y H-21 — Consolas sin segundo factor

El realm `lab`, donde el Blue Team documentó TOTP, no existe en esta copia. El selector de realms muestra solo `master`, sin pedido de código. `http://localhost:5601/app/home` abre sin login; desde el menú se ven los agentes y 234 eventos de Threat Hunting, entre ellos fuerza bruta y webshell. Recomendación: exigir MFA en la consola de identidades y volver a poner autenticación delante del dashboard.

### H-07 — Honeypot

Desde Kali, por la WAN, Cowrie aceptó `nosoy@10.10.20.30:2222` y dio un prompt. La regla `100110` no devolvió resultados: solo coincide con `cowrie.login.failed`, y además es nivel 8, por debajo del mail. Recomendación: alertar también el login aceptado, en nivel 10 o más.

### H-08 y H-23 — Huecos de visibilidad

No hay firma de DNS, de exfiltración ni de DoS. Suricata está en `10.10.20.50` y no tiene espejo del resto de la red. Esas pruebas no se ejecutaron: no había alerta que medir. Recomendación: espejo hacia el NIDS y una regla para volumen de DNS y para denegación de servicio.

### H-09 — Reglas locales

`local_rules.xml` está en el repo. La `100100`, la `100110` y la `100200` exigen un campo concreto. El ruleset de serie sigue activo. El ingreso aceptado en Cowrie ya mostró que lo que no coincide no alerta. Recomendación: no publicar el archivo de reglas con el mismo detalle, y ampliar las condiciones.

### H-20 — Wazo

No hay contenedor. `10.10.20.40` no responde. El objetivo no es ejecutable. El firewall igual publica UDP 5060 hacia la DMZ.

### H-10 a H-19, H-26 y H-27 — Versiones, avisos y análisis estático

Contraste de versiones y análisis estático, sin tráfico. Wazuh 4.9.0 y Keycloak `26.0` caen en avisos críticos y altos. DVWA es vulnerable a propósito. Los Dockerfiles de los blancos corren como root. El repro de cada CVE no se ejecutó. La auditoría de dependencias (AE-02) suma además CVE-2025-64483 en el dashboard (H-26) y la base Debian Stretch fuera de soporte con repositorios APT sin autenticar (H-27). El detalle está en los análisis AE-01 (Trivy, Semgrep) y AE-02 (avisos y dependencias) del informe de evidencias.

### H-25 y H-01 a H-03 — Entorno y reconocimiento

Tras un redespliegue, los agentes pueden quedar desenrolados y la app no arranca si el enrolamiento falla (H-25). Desde la VLAN Usuarios, la segmentación impide el reconocimiento hacia Servidores y la DMZ (H-01). El firewall descarta el SYN y responde RST al NULL/FIN (H-02). Desde la WAN, el NULL y el FIN contra `10.10.20.50` sí llegan al sensor: Suricata emitió las firmas 1000002 y 1000003, y Wazuh las subió con la regla 100100, nivel 10, sin bloqueo (H-03). El SYN de tres puertos no alcanzó el umbral de 20 en 10 segundos, y el escaneo al honeypot `.30` no lo ve Suricata.

## 6. Mapeo a MITRE ATT&CK

| Táctica | Técnica | Qué pasó |
|---|---|---|
| Discovery | T1046 Network Service Discovery | Parte A: la segmentación contuvo el escaneo y Suricata no lo vio. Parte B: NULL y FIN desde la WAN, detectados (1000002, 1000003, regla 100100). |
| Credential Access | T1110 Brute Force | RT-02. Wazuh 5763 y `firewall-drop`. Detectado y bloqueado. |
| Persistence | T1505.003 Web Shell | RT-03. Regla 100200 e `isolate-webapp`. Detectado y aislado. |
| Initial Access | T1078 Valid Accounts | H-04, H-05, H-21, H-24. Consolas y contraseñas de ejemplo. |
| Lateral Movement | T1021.004 SSH | H-07. Sesión aceptada por Cowrie, sin alerta. |
| Exfiltration | T1048 | H-08. Sin regla. |
| Defense Evasion | T1562 Impair Defenses | H-09. Reglas públicas y estrechas. |
| Impact | T1499 Endpoint Denial of Service | H-23. Sin regla. No se envió tráfico. |

## 7. Evaluación de la respuesta del Blue Team

| Ataque | Detección | Respuesta | Mail |
|---|---|---|---|
| RT-02, fuerza bruta SSH, 25/10 | Regla 5763, nivel 10, ~3 s | `firewall-drop`, ~3 s | Sí, ~15 s |
| RT-03, PHP en la app, 25/10 | Regla 100200, nivel 12, mismo segundo | `isolate-webapp`, mismo segundo | Sí, ~14 s |
| RT-01 Parte A, 25/10 | Suricata: 0 eventos | La segmentación descartó el tráfico antes | No |
| RT-01 Parte B, 28/10 | Suricata 1000002 y 1000003; Wazuh 100100, nivel 10 | Ninguna. El diseño no bloquea el reconocimiento | El nivel 10 está en el umbral del mail. El buzón no se revisó en esta prueba |
| RT-04, sesión en Cowrie, 28/10 | Regla 100110: 0 resultados | Ninguna | No |
| RT-05, RT-07, RT-11 | No hay regla que matchee | Ninguna | No |
| RT-09, RT-10 | La consola no pide usuario | No aplica | No |
| RT-06, 28/10 | Acceso con credencial por defecto demostrado; Events desactivado y sin registros | No quedó evento de login ni de administración; el SOC no lo recibe | No |

Los dos playbooks que el Blue Team cerró (bloqueo de IP y aislamiento) funcionan y notifican. TheHive no está; el SOAR es el Active Response de Wazuh. El MFA administrativo declarado en `docs/09-gestion-accesos.md` no está aplicado en este despliegue. La SoA pide una detección que en DNS, DoS y honeypot aceptado no existe.

## 8. Lecciones aprendidas y recomendaciones

En este orden:

1. Poner autenticación y MFA delante del dashboard y de la consola de Keycloak. Importar el realm con TOTP, o dejar de declararlo; activar y centralizar Events para registrar accesos y acciones administrativas.
2. Sacar las contraseñas de arranque del repositorio público y rotar las que ya se copiaron a `.env`.
3. Alertar el login aceptado de Cowrie, en un nivel que también mande mail.
4. Darle a Suricata visibilidad más allá de `10.10.20.50`, y sumar reglas de DNS y de DoS.
5. Actualizar Wazuh 4.9.0 y Keycloak `26.0`, que concentran los dos hallazgos críticos por versión.
6. Dejar de publicar `local_rules.xml` con el campo exacto que cada regla exige.

## 9. Anexos

- Anexo A — Bitácora: [`bitacora.md`](bitacora.md).
- Anexo B — Evidencias: `docs-red-team/evidencias/`. Las carpetas siguen los objetivos de la letra **RT-01 a RT-12** y los análisis **AE-01** (estático: Trivy y Semgrep) y **AE-02** (avisos públicos y auditoría de dependencias). RT-01 a RT-03 reúnen las pruebas que antes se documentaron como casos de uso; RT-06 incluye el acceso a identidad (antes CU-04). Índice en [`evidencias/index.md`](evidencias/index.md).
- Anexo C — Conteo al 03/11: 12 objetivos de la letra, los 12 cerrados. Hallazgos de la sección 4: 2 críticos, 11 altos, 8 medios, 1 bajo, 1 informativo (**23 en total**), más H-01, H-02 y H-03, que son observaciones del reconocimiento y no una debilidad explotada. El dashboard de Wazuh sin autenticación se cuenta una sola vez (H-05); el id H-22, que lo duplicaba, se unificó en H-05 (numeración salta H-22). H-06 entra en los altos por la severidad cualitativa; su base es 3.5. H-26 y H-27 se sumaron el 31/10 desde la auditoría de dependencias (AE-02); H-27 no tiene CVSS (riesgo de mantenimiento/cadena de suministro, sin CVE atribuido).

Queda fuera de este archivo la presentación de 10 minutos del 09/11.
