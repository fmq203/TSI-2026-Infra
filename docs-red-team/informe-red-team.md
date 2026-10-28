# Informe de evaluación técnica — Red Team

> Preliminar del 28/10/2026, para la pre-entrega. El detalle de cada prueba está en
> [`informe-evidencias-redteam.md`](informe-evidencias-redteam.md). La versión final
> (09/11) suma el vector CVSS, el DOCX y lo que sigue abierto.
> Los identificadores `RT-` de la letra son objetivos de ataque. Los hallazgos de este
> informe usan `H-`, para no mezclar las dos listas.

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
| Periodo de evaluación | 25/10/2026 → 28/10/2026 (preliminar). Ventana de la letra: 28/10 → 09/11. |
| Equipo Red Team | Andres, Horacio, Pablo |
| Sistemas evaluados | Laboratorio FinSegura S.A. (Tarea 3), copia VirtualBox + Vagrant |
| Alcance autorizado | VLAN WAN `203.0.113.0/24`, Servidores `10.10.10.0/24`, DMZ `10.10.20.0/24`, Usuarios `10.10.30.0/24`, Gestión `10.10.90.0/24`, y el repositorio público |
| Versión | 0.7 — preliminar |
| Fecha | 28/10/2026 |

## 1. Resumen ejecutivo

Se evaluó la infraestructura de defensa del Blue Team: firewall nftables, Suricata en la DMZ, Wazuh como SIEM y como SOAR (Active Response), Cowrie, DVWA como app de préstamos y Keycloak. Wazo y el segundo canal de alertas no están desplegados.

De los 12 objetivos de la letra (§7.2), 10 están cerrados. Falta completar el RT-01 (la Parte B, escaneo desde la WAN para que Suricata lo vea; la tiene Andres) y revisar si Keycloak dejó Events del RT-06.

La defensa responde cuando el evento coincide con una regla que ya probaron: la fuerza bruta SSH se bloquea y avisa, y un `.php` nuevo en la app aísla el contenedor y avisa. Fuera de esa forma, la actividad no deja alerta. Las consolas de administración se abren sin segundo factor, y las contraseñas de arranque están en el repositorio público.

| Severidad cualitativa | Cantidad |
|---|---|
| Crítica | 2 |
| Alta | 10 |
| Media | 7 |
| Baja | 1 |
| Informativa | 1 |

El vector CVSS v3 no está calculado en esta preliminar. La severidad de la tabla es la del informe de evidencias. Madurez observada en MCU 5.0: Detectar y Responder funcionan en dos playbooks. No cubren DNS, DoS, el login aceptado por el honeypot ni el acceso a las consolas.

## 2. Alcance y reglas de compromiso

Objetivos de la §7.2 y estado al 28/10:

| ID | Objetivo | Estado |
|---|---|---|
| RT-01 | Reconocimiento del perímetro evadiendo el NIDS | Parte A hecha (desde Usuarios). Parte B pendiente. |
| RT-02 | Fuerza bruta SSH | Cerrado. El control funcionó. |
| RT-03 | Webshell / inyección en la app | Cerrado. El control funcionó. La app está en Servidores, no en la DMZ. |
| RT-04 | Honeypot | Cerrado. Cowrie acepta la sesión y no alerta. |
| RT-05 | Exfiltración DNS/TLS | Cerrado. No hay correlación. |
| RT-06 | Credenciales robadas contra consolas | Acceso demostrado (H-04.1, H-04.2, H-12.1). Falta Events de Keycloak. |
| RT-07 | Evasión del SIEM | Cerrado. Reglas locales públicas y de coincidencia estrecha. |
| RT-08 | Wazo | Cerrado. El activo no existe. |
| RT-09 | MFA administrativo | Cerrado. El segundo factor no está en este despliegue. |
| RT-10 | Consola del SIEM | Cerrado. Se lee sin autenticación. |
| RT-11 | DoS acotado | Cerrado sin enviar tráfico. No hay regla de DoS. |
| RT-12 | OSINT del repositorio | Cerrado. Contraseñas de arranque en el árbol público. |

No se hizo denegación de servicio, ni exfiltración, ni inyección de logs. No se modificaron reglas. No se dejó un artefacto en el honeypot: la sesión se cerró con `exit`. El diagrama de red es el de `docs/00-arquitectura.md`.

## 3. Metodología

Referencias usadas como marco: PTES, OWASP Testing Guide, MITRE ATT&CK y NIST SP 800-115. En esta preliminar se ejecutó reconocimiento, acceso a consolas, una subida a la app, un SSH al honeypot, revisión de reglas y OSINT del git. No hubo fase de post-explotación sobre un sistema operativo.

Herramientas: navegador por túnel SSH, cliente SSH de Kali, `ping`, `git`, y lectura de `local.rules` y `local_rules.xml`. El análisis estático (Trivy, Semgrep) y el contraste de CVE quedaron en CU-06 y CU-07.

## 4. Inventario de hallazgos

La columna de severidad es cualitativa. «Repro» es S cuando hay captura o comando en `evidencias/`, o cuando el repro es un archivo del repo.

| ID | Activo | Tipo | Severidad | Estado | Repro | MITRE |
|---|---|---|---|---|---|---|
| H-01.1 | Firewall | Segmentación efectiva desde Usuarios | — (control) | Observado | S | T1046 |
| H-01.2 | Firewall | SYN descartado y NULL/FIN con RST | Baja (observación) | Observado | S | T1046 |
| H-04.1 | Keycloak | Admin por defecto en `master` | Alta | Confirmado | S | T1078.001 |
| H-04.2 | Wazuh dashboard | Sin autenticación | Alta | Confirmado | S | T1078 |
| H-R04.1 | Cowrie | Sesión aceptada, regla 100110 en cero | Media | Cerrado 28/10 | S | T1021.004 |
| H-05.1 | Suricata / Wazuh | Sin correlación de DNS | Media | Cerrado 28/10 | S | T1048 |
| H-R07.1 | Reglas locales | Públicas y de coincidencia estrecha | Media | Cerrado 28/10 | S | T1562 |
| H-EST-01 | Dockerfiles de blancos | Corren como root | Alta | Estático | S | — |
| H-EST-02 | Imagen DVWA | Tag `:latest` | Media | Estático | S | — |
| H-EST-03 | Scripts del manager | Expansiones sin comillas | Baja | Estático | S | — |
| H-07.1 | Wazuh 4.9.0 | CVE-2025-24016 | Crítica | Por versión | N | T1190 |
| H-07.2 | API Wazuh 4.9.0 | GHSA-gj9h-8hmr-xjjr | Alta | Por versión | N | T1078 |
| H-07.3 | Dashboard 4.9.0 | GHSA-648q-8m78-5cwv | Media | Por versión | N | T1078 |
| H-07.4 | Keycloak 26.0 | CVE-2026-18963 | Crítica | Por versión | N | T1078 |
| H-07.5 | Keycloak 26.0 | CVE-2026-7507 | Alta | Por versión | N | T1563 |
| H-07.6 | Keycloak 26.0 | CVE-2026-4634 | Alta | Por versión | N | T1499 |
| H-07.7 | App de préstamos | DVWA a propósito | Alta | Por diseño | S | T1190 |
| H-08.1 | Wazo | No desplegado | Informativa | Cerrado 27/10 | S | — |
| H-09.1 | Keycloak | MFA administrativo ausente | Alta | Cerrado 27/10 | S | T1078 |
| H-10.1 | Wazuh | Consola del SIEM sin login | Alta | Cerrado 27/10 | S | T1078 |
| H-11.1 | Suricata | Sin regla de DoS | Media | Cerrado 27/10 | S | T1499 |
| H-12.1 | Repositorio | Contraseñas de arranque públicas | Alta | Cerrado 28/10 | S | T1552 |
| H-00 | Agentes Wazuh | Detección caída tras un redespliegue | Media | Documentado | S | — |

## 5. Detalle de hallazgos

El paso a paso y las horas están en `informe-evidencias-redteam.md`. Acá va el resultado que sostiene la pre-entrega. El CVSS se completa el 09/11.

### H-04.1 y H-12.1 — Credenciales de arranque

La consola de Keycloak entra con el admin temporal del realm `master`. El `Makefile` copia los `.env.example` a `.env`, y el `README.md` publica esas cuentas. No hay clave privada ni `.env` en el historial de git. Recomendación: sacar los valores reales del árbol público y rotar lo que ya se desplegó con el ejemplo.

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

Tras un redespliegue, los agentes pueden quedar desenrolados y la app no arranca si el enrolamiento falla. Desde la VLAN Usuarios, la segmentación impide el reconocimiento hacia Servidores y la DMZ (H-01.1). El firewall descarta el SYN y responde RST al NULL/FIN (H-01.2).

## 6. Mapeo a MITRE ATT&CK

| Táctica | Técnica | Qué pasó |
|---|---|---|
| Discovery | T1046 Network Service Discovery | CU-01 Parte A. La segmentación contuvo el escaneo. Suricata no lo vio. |
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
| RT-04, sesión en Cowrie, 28/10 | Regla 100110: 0 resultados | Ninguna | No |
| RT-05, RT-07, RT-11 | No hay regla que matchee | Ninguna | No |
| RT-09, RT-10 | La consola no pide usuario | No aplica | No |

Los dos playbooks que el Blue Team cerró (bloqueo de IP y aislamiento) funcionan y notifican. TheHive no está; el SOAR es el Active Response de Wazuh. El MFA administrativo declarado en `docs/09-gestion-accesos.md` no está aplicado en este despliegue. La SoA pide una detección que en DNS, DoS y honeypot aceptado no existe.

## 8. Lecciones aprendidas y recomendaciones

En este orden:

1. Poner autenticación y MFA delante del dashboard y de la consola de Keycloak. Importar el realm con TOTP, o dejar de declararlo.
2. Sacar las contraseñas de arranque del repositorio público y rotar las que ya se copiaron a `.env`.
3. Alertar el login aceptado de Cowrie, en un nivel que también mande mail.
4. Darle a Suricata visibilidad más allá de `10.10.20.50`, y sumar reglas de DNS y de DoS.
5. Actualizar Wazuh 4.9.0 y Keycloak `26.0`, que concentran los dos hallazgos críticos por versión.
6. Dejar de publicar `local_rules.xml` con el campo exacto que cada regla exige.

## 9. Anexos

- Anexo A — Bitácora: [`bitacora.md`](bitacora.md).
- Anexo B — Evidencias: `docs-red-team/evidencias/`. CU-01 a CU-03 y CU-06 a CU-07 son casos de uso. RT-04, RT-05 y RT-07 a RT-12 son objetivos de la letra que no comparten número con un CU.
- Anexo C — Conteo al 28/10: 12 objetivos de la letra, 10 cerrados, RT-01 incompleto, RT-06 sin Events. Hallazgos de la sección 4: 2 críticos, 10 altos, 7 medios, 1 bajo, 1 informativo, más 2 observaciones de CU-01 que no son una debilidad explotada.

### Pendiente para el 09/11

- CVSS v3 de cada hallazgo y el DOCX.
- RT-01 Parte B (Andres): escaneo desde `203.0.113.100` para que Suricata lo vea.
- Events de Keycloak del acceso de administrador.
- Copia de entrega en `docs/informe-red-team.md`, como pide la plantilla.
