# Gestión de Incidentes de Seguridad — FinSegura S.A.

> Plantilla base: `plantilla/isaca/04-gestion-incidentes.md` (SI-INC-04). Escenario:
> `40-consigna-propia.md`. Arquitectura e IPs: `00-arquitectura.md`.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Detectar** + **Responder** + **Recuperar** | Detección de eventos (DE), respuesta (RS), recuperación (RC). |
| **MCU 5.0 (categorías)** | DE-01 a DE-03, RS-01 a RS-05, RC-01 a RC-03 | Registro, análisis, respuesta y recuperación de incidentes. |
| **COBIT 2019** | DSS02, DSS04, APO12 | Proceso de operación de incidentes. |
| **ISO/IEC 27001:2022** | A.5.24, A.5.25, A.5.26, A.5.27, A.5.28 | Planificación y respuesta a incidentes. |
| **ISO/IEC 27035** | Todo el estándar | Marco internacional de gestión de incidentes. |
| **BCU — Guía de Seguridad de la Información** | Requisito de incidentes y notificación | Notificación de incidentes relevantes al BCU y escalamiento. |
| **URCDP — Ley 18.331** | Art. 20 (notificación de violaciones) | Notificación de incidentes de datos personales a la URCDP. |
| **MCU 5.0 + BCU Com. 2026/098** | Respuesta a incidentes reportados trimestralmente | Evidencia del nivel de madurez de respuesta. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-INC-04 |
| Versión | 0.1 (borrador) |
| Responsable | Blue Team — fmq203, Renzo Rampoldi |
| Fecha | 07/10/2026 |

### Historial de versiones

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 0.1 | 07/10/2026 | fmq203 | Primera versión: severidades, procedimiento, playbooks por caso de uso, registro con INC-2026-001..003. |
| 0.2 | 11/10/2026 | fmq203 (sobre evidencia de R. Rampoldi, commit `40364c8`) | Cierre de INC-2026-002 y 003 con evidencia real en `docs/evidencias/`; CU-03 implementado (FIM + Active Response `isolate-webapp`). |

Todas las horas en **UTC** (hora local de Uruguay = UTC−3).

---

## 1. Definiciones

- **Evento**: ocurrencia observable en un sensor (Suricata, agente Wazuh, Cowrie,
  Keycloak). No todo evento es incidente.
- **Incidente**: evento que compromete la confidencialidad, integridad o disponibilidad
  de un activo de FinSegura, o viola la política de seguridad.
- **Incidente simulado**: ataque ejecutado por el propio Blue Team para probar la cadena
  detección → respuesta → notificación (LETRA.md RF-17). Se registra igual que uno real,
  con el prefijo de caso de uso.

### Bandas de severidad

| Severidad | Criterio (FinSegura) | Ejemplo | Nivel Wazuh orientativo |
|---|---|---|---|
| **S0 — Crítica** | Fuga o alteración de datos personales/financieros de clientes, o compromiso de una consola de seguridad | Volcado de la base de la app de préstamos; acceso a Wazuh/Keycloak con credenciales robadas | ≥ 13 |
| **S1 — Alta** | Compromiso de un activo (ejecución de código, persistencia) sin fuga confirmada | Webshell en la app de préstamos (CU-03) | 10-12 |
| **S2 — Media** | Intento de intrusión detectado y contenido | Fuerza bruta SSH bloqueada (CU-02) | 10 |
| **S3 — Baja** | Reconocimiento o actividad sospechosa sin intento de acceso | Escaneo de puertos (CU-01), login en el honeypot | 3-9 |

Las alertas de nivel **≥ 10** generan mail automático a `soc@lab.local`
(`infra/siem-hids/configure-manager.sh`).

---

## 2. Clasificación y registro de incidentes

### Registro de incidentes

| ID | Fecha (UTC) | Descripción | Severidad | Vector | Activo | Estado | Responsable |
|---|---|---|---|---|---|---|---|
| INC-2026-001 | 05/10/2026 ≈11:45 | CU-01: barrido de ping y escaneo SYN desde la VLAN Servidores contra la DMZ | S3 | Red interna | DMZ — `suricata` (10.10.20.50) | **Cerrado** (simulación ejecutada) | fmq203 |
| INC-2026-002 | 11/10/2026 | CU-02: fuerza bruta SSH contra `target-ssh-client` (usuario inexistente) | S2 | Red interna (SSH) | `target-ssh-client` (10.10.30.10) | **Cerrado** (detectado y mitigado, evidencia en `docs/evidencias/CU-02/`) | R. Rampoldi |
| INC-2026-003 | 11/10/2026 | CU-03: webshell (archivo PHP) en el webroot de la app de préstamos | S1 | Web | `target-webapp` (10.10.10.10) | **Cerrado** (detectado y aislado, evidencia en `docs/evidencias/CU-03_INC-2026-003/`) | R. Rampoldi |
| INC-2026-004 | — | **Ejercicio de escritorio** (no ocurrió): exfiltración de la base de clientes por DNS (CU-05) para probar la notificación | S0 (supuesto) | Red (DNS saliente) | A04 base de clientes | Ejercicio documentado en `12-notificacion-incidentes.md` | RSI |

Los hallazgos del Red Team (desde el 28/10/2026) se agregan a esta tabla como
INC-2026-1xx.

### INC-2026-001 — Reconocimiento contra la DMZ (CU-01)

| Campo | Valor |
|---|---|
| Fecha y hora (UTC) | 05/10/2026, ≈11:45 (hora del commit `2ed8e4a` que registra la detección). **Timestamp exacto de la alerta: tomar de la captura del dashboard.** |
| Descripción / síntomas | Barrido de ping y escaneo SYN contra la DMZ desde un host de la VLAN Servidores. |
| Severidad inicial | S3 (reconocimiento, sin intento de acceso) |
| Vector de ingreso | Red interna (VLAN 10 → VLAN 20) |
| Activos involucrados | DMZ; el tráfico observado llega a `suricata` (10.10.20.50) |
| Detección | Suricata, firmas propias **1000005** (barrido de ping) y **1000001** (escaneo SYN, ≥ 20 SYN en 10 s por origen) → Wazuh regla **86601** → regla local **100100** (nivel 10, MITRE T1046) → dashboard |
| Respuesta | Solo detección y notificación (por diseño, ver `40-consigna-propia.md` §3): no hay bloqueo automático de un escaneo. |
| Evidencia preservada | `eve.json` de Suricata y `alerts.json` del manager en el entorno de referencia. **Capturas a `docs/evidencias/`: pendientes.** IP de origen: completar con la captura. |
| Estado | Cerrado |

### INC-2026-002 — Fuerza bruta SSH (CU-02)

Cadena construida el 05/10/2026 (commit `fd562cf`), restaurada el 07/10 (`543c519`),
verificada en detección y respuesta el 11/10/2026 por R. Rampoldi (commit `40364c8`), y
**verificada de punta a punta incluida la notificación el 14/10/2026**. La notificación
no llegaba por dos causas de red/config (firewall Gestión→DMZ puerto 25 cerrado +
`mynetworks` de Postfix sin `net_mgmt`), corregidas ese mismo día — detalle en
`brain/LEARNINGS.md` 2026-10-14. Evidencia completa en `docs/evidencias/CU-02/README.md`.

| Campo | Valor |
|---|---|
| Fecha y hora (UTC) | 14/10/2026, 00:45:31 (primer intento) — 00:45:55 (mail entregado) |
| Descripción / síntomas | Múltiples intentos fallidos de login SSH contra `10.10.30.10:2222` con usuario **inexistente**, desde un host atacante en `10.10.30.50`. |
| Severidad inicial | S2 |
| Vector de ingreso | Red interna (SSH) |
| Activo | `target-ssh-client` — simula un puesto de Atención al cliente |
| Detección | Agente Wazuh embebido → regla estándar de sshd **5712** ("brute force trying to get access to the system. Non existent user."), nivel 10 |
| Respuesta | Active Response `firewall-drop` ejecutado contra `10.10.30.50`, confirmado en `iptables -L INPUT -n` |
| Notificación | Mail entregado en `soc@lab.local` (ver mensaje completo en la evidencia) |
| MTTD | ≈ 13 s (00:45:31 primer intento → 00:45:44 alerta) |
| MTTR (detección → contención) | ≈ 0 s (el Active Response se ejecuta en el mismo segundo que la alerta) |
| Detección → notificación | ≈ 24 s (00:45:44 alerta → 00:45:55 mail entregado) |
| Evidencia preservada | `docs/evidencias/CU-02/` — capturas del 11/10 (detección/respuesta) + `2026-10-14_CU-02_deteccion-respuesta.txt` y `2026-10-14_CU-02_mail.txt` (notificación, con timestamps) |
| Estado | **Cerrado, verificado de punta a punta** |

**Notas de aprendizaje:** el equipo había intentado antes la simulación con un usuario
**válido** (`labuser`) y contraseñas incorrectas, sin generar la alerta 5712/5763 en las
pruebas previas. Lo que destrabó la detección fue atacar con un usuario que **no
existe** en el sistema, que es el patrón que cubre la regla 5712, y lanzar el ataque
desde un host directo en `net_usr` (no desde el router). Además, la notificación por
mail estuvo bloqueada 14 días por dos causas de red/config no relacionadas con la
detección — ver `brain/LEARNINGS.md` 2026-10-14.

### INC-2026-003 — Webshell en la app de préstamos (CU-03)

Implementado y verificado en detección y respuesta el 11/10/2026 por R. Rampoldi
(commit `40364c8`): agente Wazuh + FIM en tiempo real sobre `/var/www/html` de
`target-webapp`, regla local `100200` y Active Response `isolate-webapp`. El agente
dejó de estar activo poco después (el contenedor vivo nunca se recreó con la imagen
nueva) y la regla 100200 nunca llegó a sincronizarse al manager en vivo — **corregido y
verificado de punta a punta, incluida la notificación, el 14/10/2026** (detalle en
`brain/LEARNINGS.md` 2026-10-14). Evidencia completa en
`docs/evidencias/CU-03_INC-2026-003/README.md`.

| Campo | Valor |
|---|---|
| Fecha y hora (UTC) | 14/10/2026, 01:08:34 (archivo creado y alerta/aislamiento, mismo segundo) — 01:08:49 (mail entregado) |
| Descripción / síntomas | Archivo PHP sospechoso agregado al webroot, simulando el depósito de una webshell |
| Severidad inicial | S1 |
| Vector de ingreso | Web (webroot de la app de préstamos) |
| Activo | `target-webapp` (10.10.10.10) |
| Detección | FIM (`syscheck`, regla base **554** "File added to the system") → regla local **100200** (nivel 12, MITRE T1505.003 Web Shell) al coincidir con `/var/www/html/*.php` |
| Respuesta | Active Response `isolate-webapp`: elimina la ruta por defecto del contenedor (deja inalcanzables DMZ y demás redes) pero preserva una ruta específica al Wazuh Manager por TCP 1514 |
| Notificación | Mail entregado en `soc@lab.local` (ver mensaje completo en la evidencia) |
| MTTD / MTTR | ≈ 0 s ambos (alerta y Active Response se ejecutan en el mismo segundo que el archivo) |
| Detección → notificación | ≈ 15 s |
| Evidencia preservada | 10 capturas del 11/10 (FIM, regla, Active Response, rutas antes/después) + `2026-10-14_CU-03_reenrolamiento-y-cierre.txt` y `2026-10-14_CU-03_mail.txt` (notificación, con timestamps) en `docs/evidencias/CU-03_INC-2026-003/` |
| Estado | **Cerrado** |

---

## 3. Procedimiento de respuesta

### 3.1 Línea de tiempo general

1. **Detección**: alerta en Wazuh (origen: agente, Suricata o Cowrie). Nivel ≥ 10 →
   mail automático al SOC.
2. **Registro**: el responsable de turno carga el incidente en §2 con ID `INC-2026-###`
   y severidad inicial.
3. **Contención**: automática donde hay playbook (§3.2); si no, manual (regla de
   bloqueo en el router o detención del contenedor afectado).
4. **Erradicación**: eliminar la causa (archivo malicioso, cuenta comprometida,
   configuración débil).
5. **Recuperación**: restaurar el servicio desde la definición en el repo
   (`docker compose up -d --force-recreate`) y verificar que vuelve a reportar a Wazuh.
6. **Lecciones aprendidas**: completar §5 y, si corresponde, entrada en
   `brain/LEARNINGS.md`.

### 3.2 Playbooks por caso de uso (RF-06)

| Caso | Detección | Contención automática | Notificación | Estado |
|---|---|---|---|---|
| CU-01 Reconocimiento | Suricata 1000001-1000005 → Wazuh 100100 | Ninguna (por diseño) | Mail SOC (nivel 10) | ✅ Verificado 05/10 |
| CU-02 Fuerza bruta SSH | Wazuh 5712/5763 | **Playbook 1**: `firewall-drop` en el host (10 min) | Mail SOC (nivel 10) — **verificado** | ✅ Verificado de punta a punta 14/10 |
| CU-03 Webshell | Wazuh FIM sobre el webroot → regla local 100200 | **Playbook 2**: `isolate-webapp` (aísla red, preserva TCP 1514 al manager) | Mail SOC (nivel 12) — **verificado** | ✅ Verificado de punta a punta 14/10 |
| CU-04 Credenciales robadas | Logs de Keycloak (MFA) | **Playbook 3** (a definir: deshabilitar cuenta) | Mail SOC | ❌ Pendiente |
| CU-05 Exfiltración DNS | Suricata/Wazuh | — | Mail SOC | ❌ Pendiente |

---

## 4. Notificación y escalamiento

| Escenario | Notificar a | Plazo | Plantilla |
|---|---|---|---|
| Incidente con datos personales de clientes (S0) | URCDP (Ley 18.331, Art. 20) | **a confirmar** — referencia probable: Decreto 64/020 | `12-Notificacion-Incidentes.md` |
| Incidente relevante (S0/S1) | BCU, según GSI | **a confirmar** en la GSI del BCU (no figura en las plantillas del curso) | `12-Notificacion-Incidentes.md` |
| Incidente operativo interno (S2/S3) | Responsable de Seguridad (RSI) / Dirección | Mail automático inmediato (nivel ≥ 10); registro en §2 en el día | Registro interno |

Ninguno de los incidentes simulados (INC-2026-001..003) involucra datos personales
reales: no corresponde notificación externa.

---

## 5. Lecciones aprendidas

### INC-2026-001 (CU-01)

| Campo | Valor |
|---|---|
| Qué ocurrió | El primer escaneo no generó ninguna alerta, aunque Suricata veía tráfico. |
| Por qué ocurrió | Tres causas encadenadas: (1) el firewall solo dejaba pasar TCP/443 de Servidores a DMZ, así que el escaneo nunca llegaba al sensor; (2) checksums incompletos en NICs virtuales hacían que Suricata descartara paquetes; (3) Filebeat 7.10 no publicaba en el indexer OpenSearch 2.x, así que el dashboard quedaba vacío aunque el manager tuviera las alertas. |
| Qué funcionó | Diagnóstico por tramos (`eve.json` → `alerts.json` → `filebeat test output` → índices del indexer) para aislar en qué salto se perdía la alerta. |
| Qué falló | La regla de bloqueo por defecto del router no tenía log: los descartes no se veían en OPNsense. |
| Acciones de mejora | (1) Activar log en la regla de bloqueo por defecto del router. (2) Documentar en `00-arquitectura.md` qué flujos necesitan los sensores. (3) Resolver cómo llega tráfico espejado a Suricata (hoy solo ve el tráfico dirigido a su IP). |
| Responsable y fecha | fmq203 — 05/10/2026 |

---

## 6. KPIs (LETRA.md §6.4)

| KPI | Valor al 14/10/2026 |
|---|---|
| MTTD por ataque simulado | CU-02: **≈ 13 s** (00:45:31 → 00:45:44). CU-03: **≈ 0 s** (alerta en el mismo segundo que el archivo, 01:08:34). CU-01: no medido con precisión de reloj, pendiente extraerlo de `alerts.json` |
| MTTR del SOAR | CU-02: **≈ 0 s** detección→`firewall-drop` (mismo segundo). CU-03: **≈ 0 s** detección→`isolate-webapp` (mismo segundo) |
| Detección → notificación (mail) | CU-02: **≈ 24 s**. CU-03: **≈ 15 s** |
| % ataques simulados detectados y mitigados | 3 de 3 ejecutados y detectados (CU-01, CU-02, CU-03); mitigación automática verificada en 2 de 3 (CU-02 `firewall-drop`, CU-03 `isolate-webapp`; CU-01 no tiene contención por diseño) |
| % con notificación verificada | 2 de 2 que debían notificar: CU-02 ✅ y CU-03 ✅ (mail confirmado en ambos, 14/10) |
| Falsos positivos | No medido |

---

## Check de aceptación

- [x] Definiciones de severidad y clasificación.
- [x] Procedimiento de respuesta completo (D→C→E→R→L).
- [x] Registro de incidentes con los simulados — 3 de 3 (CU-01, CU-02, CU-03) ejecutados
  y cerrados con evidencia.
- [ ] Hallazgos del Red Team — desde el 28/10.
- [ ] Procedimiento de notificación a BCU/URCDP — plazos a confirmar.
