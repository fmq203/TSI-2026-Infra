# LETRA DE TAREA 3 — Infraestructura de Red de Defensa Completa

**Curso:** Seguridad de la Información
**Módulo:** Práctica integradora — Blue Team / Red Team
**Equipos:** 2 (Blue Team y Red Team)
**Modalidad:** Open source obligatorio
**Versión:** 1.0
**Fecha:** `[DD/MM/AAAA]`

---

## 0. Resumen de la tarea

Diseñar e implementar, en un entorno de laboratorio (VMs/KVM/contenedores), una **infraestructura de red de defensa integral** que incluya como mínimo:

- **IDS/IPS** (red y host).
- **SIEM** con correlación de eventos.
- **SOAR** (orquestación, automatización y respuesta).
- **Alertas** en múltiples canales.
- **HIDS/FIM** (integridad de archivos).
- **Wazo** (plataforma de comunicaciones/PBX) como canal operativo.
- **Security Onion** como distribución de monitoreo si se decide.
- Todo lo que el equipo considere necesario (honeypots, tarpits, gestión de identidades, DNS seguro, proxy, etc.).

Se debe construir una **red completa**, analizarla, y el equipo debe **generar su propia consigna**, definiendo el escenario empresarial ficticio, el diagrama de red, los activos a proteger y los casos de uso de seguridad que la infraestructura debe cubrir.

Se exige: **TOTP, WebAuthn/U2F, Windows Hello** configurables, y elección de algoritmo (Argon2 por ejemplo) para autenticación administrativa.

Se desarrolla en dos partes: **Blue Team** (construcción) y **Red Team** (ataque).

### 0.1 Perfil MCU 5.0 objetivo: **AVANZADO**

El perfil de cumplimiento del **Marco de Ciberseguridad 5.0 (AGESIC)** exigido es el **perfil comunitario AVANZADO**, incluso tratándose de infraestructura. Esto implica:

- Justificar los controles del perfil **Avanzado** en las seis funciones: **Gobernar, Identificar, Proteger, Detectar, Responder, Recuperar**.
- Completar y entregar los **Excel** de `plantilla/mcu5/excel/`:
  - `01-controles-mcu5-perfil-avanzado.xlsx` — controles con **evidencia** y **cómo se demuestra**.
  - `02-registro-activos-mcu5.xlsx` — inventario de activos (hosts, VLANs, sensores, consolas).
  - `03-matriz-raci-mcu5.xlsx` — RACI de los procesos de seguridad de la red.
  - `04-bitacora-planilla.xlsx` — bitácora de trabajo diaria.
- Cada control declara **Sí/No/N.A.** y los N.A. llevan **justificación aceptada** (por ejemplo: controles físicos de un CPD real no aplican en un laboratorio virtual; se justifica y se acepta).

### 0.2 Modelo de arquitectura obligatorio

Presentar la arquitectura con `plantilla/plantilla-arquitectura-4más1.md` y `plantilla/plantilla-arquitectura-C4.md`, **antes** de la demo funcional. En una infraestructura de red, las vistas que se precisan y su contenido son:

| Vista (según tarea) | Qué contiene |
|---|---|
| **Contexto (C4)** | La infra como una sola caja: actores externos (internet, usuarios, SIEM externo), flujos de datos de entrada/salida. |
| **Contenedores (C4)** | Cada dispositivo/nodo (FW, NIDS, SIEM, SOAR, HIDS, correo, Wazo, honeypots) como un contenedor con tecnología y protocolos. |
| **Componentes (C4)** | El interno de cada contenedor crítico (módulos del SIEM: ingesta, correlación, índice, alertas). |
| **Código (C4)** | Solo módulos de seguridad relevantes (playbooks SOAR, reglas). |
| **Vista Física (4+1)** | Diagrama de red completo: VLANs, IPs, puertos, enlaces, TAP/SPAN, FW, DMZ, segmentos. **Obligatoria y central en esta tarea.** |
| **Vista de Procesos (4+1)** | Flujos de las 3 simulaciones de ataque (reconocimiento → detección → respuesta). |
| **Vista Lógica (4+1)** | Módulos funcionales de la plataforma de defensa y sus relaciones. |
| **Escenarios (4+1)** | Los 5+ casos de uso de seguridad definidos por el equipo (RF-01). |

### 0.3 Calendario del curso (obligatorio)

| Hito | Fecha | Evento |
|---|---|---|
| Pre-entrega Blue Team | **miércoles 7 de octubre de 2026** | Entrega congelada + arranque de auditoría |
| Entrega / Defensa Blue Team | **miércoles 14 de octubre de 2026** | Auditoría formal por función |
| Pre-entrega Red Team | **miércoles 28 de octubre de 2026** | Informe Red Team preliminar |
| Entrega final Red Team | **lunes 9 de noviembre de 2026** | Informe Red Team final + presentación |

---

## 1. Marco teórico

### 1.1 Defensa en profundidad (defense in depth)

Múltiples capas de control: perímetro, red, host, aplicación, datos y personas. Cada capa puede fallar individualmente pero el daño global queda acotado.

### 1.2 Detección: IDS/IPS, HIDS/NIDS

- **NIDS** (Suricata/Zeek): análisis de tráfico de red, firmas.
- **HIDS** (Wazuh/OSSEC): integridad de archivos (FIM), detección en host, auditoría de procesos.
- **IPS**: bloqueo activo de tráfico malicioso (Suricata en modo IPS).
- **SIEM** (Wazuh/ELK/Security Onion): correlación de eventos multi-fuente.

### 1.3 Respuesta: SOAR

- Orquestación: playbooks que ejecutan acciones (bloquear IP, aislar host).
- Automatización: reduzco MTTR.
- Respuesta: comunicación, notificación, escalamiento.
- Herramientas: TheHive (casos) + Cortex (acciones), Wazuh Active Response, Shuffle (open source).

### 1.4 Comunicaciones y alerta (Wazo)

Wazo (PBX open source basado en Asterisk) da un canal de **verificación humana** (llamada/SMS) para alertas críticas del SIEM/SOAR.

### 1.5 Marqués normativo aplicable (Uruguay)

- **MCU 5.0:** funciones **Proteger**, **Detectar**, **Responder**, **Recuperar**.
- **BCU — GSI:** monitoreo de eventos de seguridad, IDS/IPS, logs con retención, respuesta a incidentes, backups y continuidad, 2FA operaciones clave.
- **ISO/IEC 27001:2022:** A.8.15/16 (monitoreo), A.5.24 (incidentes), A.8.8 (vulnerabilidades), A.8.13/14 (backup/continuidad).
- **COBIT 2019:** DSS04, DSS05, DSS02.
- **NIST SP 800-41/800-92** (firewalls, SIEM) referencial.

---

## 2. Glosario

| Término | Definición |
|---|---|
| IDS/IPS | Detección / Prevención de intrusos. |
| HIDS/NIDS | Detección a nivel host / red. |
| SIEM | Correlación de eventos y almacenamiento. |
| SOAR | Orquestación, automatización y respuesta. |
| Playbook | Secuencia automatizable de respuesta a incidentes. |
| FIM | Monitoreo de integridad de archivos. |
| Honeypot | Recurso trampa que simula un servicio para atraer atacantes. |
| Tarpit | Servicio que responde lentamente para frenar ataques/escaneos. |
| Suricata | NIDS/IPS open source. |
| Zeek | Analizador de tráfico. |
| Wazuh | HIDS+SIEM open source. |
| TheHive/Cortex | Gestión de casos y respuesta (SOAR). |
| Security Onion | Distribución de monitoreo (Suricata+Zeek+Elastic+...) |
| Wazo | PBX open source (comunicaciones). |
| VLAN/segmentación | Separación lógica de red en dominios de seguridad. |
| SPAN/TAP | Puertos de espejo de tráfico para NIDS. |
| Zero Trust | Verificar siempre; segmentación micro. |

---

## 3. Requerimientos funcionales (RF)

| ID | Requerimiento |
|---|---|
| RF-01 | Generar la **consigna propia** del equipo: escenario empresarial (sector, tamaño, activos), red completa diseñada y justificada. |
| RF-02 | **Diagrama** de red con segmentación (UPL/DMZ/VLANs servidores, usuarios) y puntos de captura de tráfico (TAP/SPAN). |
| RF-03 | Implementar **NIDS** (Suricata/Zeek) con firmas actualizadas. |
| RF-04 | Implementar **HIDS/FIM** (Wazuh) en todos los servidores críticos del dominio. |
| RF-05 | **SIEM** que correlacione eventos de NIDS+HIDS+servidores+app. |
| RF-06 | **SOAR**: al menos 3 playbooks (bloqueo de IP, aislamiento de host, respuesta a detección de webshell) con ejecución demostrada. |
| RF-07 | **Alertas** multicanal: email (servidor SMTP propio), y al menos un segundo canal (webhook/discord/slack/Telegram o llamada Wazo). |
| RF-08 | **Wazo** desplegado y usado para verificación/aviso en al menos 1 caso real simulado. |
| RF-09 | **Honeypot** y/o tarpit operativo que detecte actividad de reconocimiento. |
| RF-10 | **Dashboards** del SIEM (anomalías, top fuentes, top destinos, alertas por severidad) y de funcionamiento general. |
| RF-11 | **Registro y gestión de incidentes** (TheHive/Wazuh) con ciclo completo (detección→investigación→mitigación→cierre). |
| RF-12 | **Autenticación administrativa**: TOTP + WebAuthn/U2F + Windows Hello opcional; algoritmo de hash seleccionable (Argon2). |
| RF-13 | **Backup** de la configuración del SIEM/SOAR/nodos + prueba de restauración. |
| RF-14 | **Análisis de la red** emitido: informe de exposición, inventario de servicios y vulnerabilidades antes y después de los controles. |
| RF-15 | Registro de eventos con retención ≥ 90 días. |
| RF-16 | Búsqueda/correlación manual (consola del SIEM) funcional. |
| RF-17 | **Simulación documentada** de al menos 3 ataques (reconocimiento, fuerza bruta SSH, webshell/exfiltración) con detección y respuesta. |

## 4. Requerimientos no funcionales (RNF)

| ID | Requerimiento |
|---|---|
| RNF-01 | Todo el stack **open source** y desplegado en laboratorio del curso. |
| RNF-02 | Rendimiento: el NIDS soporta el tráfico del laboratorio sin pérdida de paquetes. |
| RNF-03 | Disponibilidad de las consolas 99% durante el periodo de evaluación. |
| RNF-04 | Seguridad: TLS 1.2+, MFA obligatorio para administradores, mínimo privilegio. |
| RNF-05 | Trazabilidad: registros con fecha/hora (UTC), formato estándar (CEF/JSON). |
| RNF-06 | Mantenibilidad: scripts/ansible opcional para reproducir el despliegue. |
| RNF-07 | Documentación completa de despliegue y operación. |
| RNF-08 | Respaldo y restauración del SIEM probado (RA/RPO definidos). |
| RNF-09 | Cumplimiento trazable: MCU 5.0 (DE/RS/RC), BCU (SIEM, incidentes, backups), ISO A.8.15/16. |
| RNF-10 | Escalabilidad: diseño documentado para crecer a N+40 hosts. |

---

## 5. Arquitectura sugerida

**Red de laboratorio (VMs / KVM / Proxmox / Dockers for Services)**

```
[ Inet simulator ]
      │
   ┌──▼──────────────┐
   │ FW / Router (pfSense/OPNsense/IPFire) │ NAC/VLAN
   └──┬──────────────┘
      ├─────────── UPL / WAN segment
      │
   ┌──┴──────────────┐
   │ DMZ: Wazo, SMTP, honeypot │
   └──────────────────┘
      │  SPAN/TAP ──► NIDS (Suricata/Zeek)
   ┌──▼──────────────┐
   │ Internal segment: Servidores (App, DB), Agentes (SSH/FIM), Clientes │
   │    VLAN Servidores / VLAN Usuarios (segmentación)                  │
   └──────────────────┘
      │
   ┌──▼──────────────────────────────┐
   │ Management (SIEM/SOAR): Wazuh Server (Elasticso?) / ELK / TheHive+Cortex │
   │ Security Onion (opcional) + OPNsense FW                        │
   └──────────────────────────────────┘
```

**Componentes mapeados**

| Capa | Herramienta open source | Rol |
|---|---|---|
| Router/Firewall | OPNsense / pfSense / IPFire | perímetro, segmentación, VLANs |
| NIDS | Suricata + Zeek | detección de red |
| HIDS | Wazuh agent (FIM, logs) | endpoints/servidores |
| SIEM | Wazuh / ELK (or Security Onion) | correlación y almacenamiento |
| SOAR | TheHive + Cortex; Wazuh Active Response; (opcional Shuffle) | respuesta automatizada |
| Alertas | SMTP propio (Postfix/Mailu) + webhook / Telegram / Wazo | canales de alerta |
| Comunicaciones | Wazo (PBX) | verificación humana por llamada |
| Honeypot | Cowrie / honeyd / T-Pot | engaño y detección temprana |
| Identidad | Keycloak / Auth + MFA (TOTP/WebAuthn/Hello) | acceso administrativo |
| Dashboard | Grafana + Kibana own | visibilidad |
| Gestión | Gitea (repo), Ansible (opcional) | mantenimiento |

### Flujo de eventos

```
Sensores (Suricata/Zeek/Wazuh agents) ──► SIEM ──► reglas → alerta
                                                        ├─► email / webhook / Wazo call
                                                        ▼
                                        TheHive (caso) ─► Cortex playbook
                                                        ├─► bloqueo en FW (API)
                                                        └─► aislar agent (active response)
```

---

## 6. Parte 1 — Blue Team

### 6.1 Consigna propia (entregable de diseño)

Listo como RF-01, el equipo debe definir:
- Escenario: sector (financiero, edu, salud, retail), tamaño, procesos críticos, datos críticos.
- Red diseñada: dominios de seguridad, servidores, clientes, flujos permitidos/prohibidos.
- Casos de uso: mínimo 5 (ej.: fuerza bruta SSH, escaneo de puertos, webshell, ransomware simulado, exfiltración por DNS, uso de credenciales robadas).
- Medidas frente a cada caso: firma/regla, correlación, respuesta automatizada.

### 6.2 Entregables Blue Team

| # | Entregable | Documento | Fase |
|---|---|---|---|
| 1 | Consigna propia + diagrama | `docs/00-arquitectura.md` y `docs/40-consigna-propia.md` | Diseño |
| 2 | Política de seguridad | `01-politica-seguridad` | Inicio |
| 3 | Inventario/activos | `02-registro-activos` | Diseño |
| 4 | Análisis de riesgos | `03-analisis-riesgos` | Diseño |
| 5 | Gestión de accesos | `09-gestion-accesos` | Implementación |
| 6 | Monitoreo/logs/SIEM | `07-monitoreo-logs` | Implementación |
| 7 | Vulnerabilidades | `10-gestion-vulnerabilidades` | Pre-entrega |
| 8 | Continuidad | `06-plan-continuidad` | Implementación |
| 9 | Incidentes | `04-gestion-incidentes` | Validación |
| 10 | SoA + brecha MCU | `11-soa-plan-tratamiento` | Cierre |
| 11 | Notificaciones | `12-notificacion-incidentes` | Cierre |
| 12 | Repositorio + tag | — | Entrega |
| 13 | Evidencias (demo ≤ 8 min video) | `docs/evidencias/` | Entrega |
| 14 | Informe Blue Team (incl. análisis de la red) | `docs/28-informe-blue-team.md` | Entrega |

### 6.3 Hitos

| Hito | Fecha | Ítem |
|---|---|---|
| H1 | Lunes 21/09/2026 | Consigna propia + diagrama aprobados |
| H2 | Lunes 28/09/2026 | FW + segmentación + NIDS + HIDS operativos |
| H3 | Viernes 02/10/2026 | SIEM + SOAR + Wazo + honeypots + dashboards |
| H4 | **Miércoles 07/10/2026 (pre-entrega)** | Entrega congelada (`git tag v1.0`) con 3 ataques simulados documentados |
| H5 | **Miércoles 14/10/2026 (defensa)** | Auditoría formal |

### 6.4 KPIs

- MTTD (tiempo de detección) por ataque simulado.
- MTTR (tiempo de respuesta) del SOAR.
- % de ataques simulados detectados y mitigados (objetivo ≥ 90%).
- Cobertura de logs (todos los hosts críticos reportando al SIEM).
- Falsos positivos (< 20%).
- Uptime de consolas.

### 6.5 Bitácora de trabajo (obligatoria)

Cada equipo lleva **bitácora diaria** del trabajo (modelo `plantilla/isaca/99-bitacora-trabajo.md` y Excel `plantilla/mcu5/excel/04-bitacora-planilla.xlsx`). Reglas: registro **diario**, cada miembro firma, **no se omiten fallos**, hora UTC, evidencia real en `docs/evidencias/`. El Red Team registra cada intento de ataque contra el SIEM/SOAR/FW.

### 6.6 La auditoría (evaluación de la Parte 1)

Instancia formal de **auditoría de seguridad** recorriendo las seis funciones del **MCU 5.0** (perfil Avanzado). Orden obligatorio de presentación:

| Paso | Qué se presenta | Tiempo sugerido |
|---|---|---|
| 1 | **Demo funcional**: infraestructura arrancando + **diagrama de red (arquitectura física/C4)** en vivo | 15 min |
| 2 | **Gobernar** (política, RACI de red, planes) | 5 min |
| 3 | **Identificar** (activos, riesgos, vulnerabilidades de la red) | 10 min |
| 4 | **Proteger** (segmentación, FW, accesos/MFA, cifrado) | 10 min |
| 5 | **Detectar** (NIDS/HIDS/SIEM/reglas/alertas) | 10 min |
| 6 | **Responder** (SOAR/playbooks, incidentes, notificaciones) | 10 min |
| 7 | **Recuperar** (BCP, restauración de consolas) | 5 min |
| 8 | Cierre: 3 simulaciones de ataque documentadas + preguntas | 10 min |

**Cómo se evalúa cada control:** para cada control del Excel `01-controles-mcu5-perfil-avanzado` se presenta **evidencia**, **cómo se demuestra** y **aplicabilidad justificada**. El auditor puede pedir la **demostración en vivo de cualquier control** (bloqueo automático, alerta SIEM, restauración).

**Obligatorio en la auditoría**: demostrar en vivo al menos **una detección y respuesta automatizada** de extremo a extremo (ataque → regla SIEM → playbook SOAR → bloqueo/aislamiento → notificación).

---

## 7. Parte 2 — Red Team

### 7.1 Reglas de compromiso

- Solo laboratorio del curso; no denegar servicio fuera de ventanas pactadas.
- Puede interactuar con honeypots y simular artefactos; **no** dejar artefactos permanentes.
- **Ventana activa**: del **28 de octubre al 9 de noviembre de 2026** (pre-entrega 28/10; entrega final 09/11).
- El Red Team mantiene **bitácora diaria de ataques**.
- **Pre-entrega (28/10)**: informe preliminar con ≥ 70% de hallazgos.
- **Entrega final (09/11)**: informe completo según `plantilla/informe-red-team.md` + presentación ejecutiva.

### 7.2 Objetivos Red Team

| ID | Objetivo |
|---|---|
| RT-01 | Reconocimiento del perímetro (escaneo de la red DMZ/servicios) evadiendo o intentado evadir NIDS. |
| RT-02 | Fuerza bruta SSH a servidores (validando si bloqueo delel SOAR responde y alerta). |
| RT-03 | Webshell / inyección web en algún servicio de la DMZ (Wazo, app web) detectado por Wazuh. |
| RT-04 | Explotación de honeypot → ¿es detectado? ¿se alerta? |
| RT-05 | Exfiltración de datos simulada por DNS/TLS → correlación en SIEM. |
| RT-06 | Uso de credenciales robadas (de la Tarea 1 o simulado) para acceder a consolas de gestión. |
| RT-07 | Evasión de SIEM (log injection / formato malicioso) o abuso de reglas. |
| RT-08 | Atacar el propio Wazo (extensiones falsas, IVR exploit, enumeración) |
| RT-09 | Bypass del MFA administrativo. |
| RT-10 | Compromiso del servidor SIEM/SOAR (si llega) y documentación del impacto. |
| RT-11 | DoS acotado hacia un servicio no crítico para probar respuesta de monitoreo. |
| RT-12 | OSINT del repositorio (secretos/credenciales). |

### 7.3 Herramientas Red Team (open source)

nmap, masscan, ffuf, nuclei, nikto, hydra/patator, sqlmap (autorizado), metasploit (sandbox), cowrie/honeypot check, crackmapexec/impacket si corresponde, mitmproxy, curl/jq, gitleaks.

### 7.4 Entregables Red Team

| # | Entregable |
|---|---|
| 1 | Informe técnico de evaluación (plantilla `informe-red-team.md`) |
| 2 | Hallazgos con CVSS + repro |
| 3 | Mapeo MITRE ATT&CK (qué detectó o no la defensa) |
| 4 | Registro de incidentes (por plantilla) |
| 5 | Evaluación de la eficacia de los controles VS consigna del Blue Team |
| 6 | Presentación ejecutiva (10 min) |
| 7 | Bitácora Red Team diaria |

### 7.5 Presentación del Red Team (entrega final 09/11)

| Paso | Contenido |
|---|---|
| 1 | Resumen ejecutivo de hallazgos por severidad |
| 2 | Demo del top 3 de hallazgos críticos (repro) |
| 3 | Evaluación de la eficacia de los controles de red por función MCU |
| 4 | Respuesta del Blue Team a cada hallazgo |
| 5 | Entrega informe final (`plantilla/informe-red-team.md`) + bitácora |

---

## 8. Matriz de documentación

### 8.1 Blue Team

| Plantilla | Cuándo | Evidencia |
|---|---|---|
| `01-politica-seguridad` | 1ª semana-30/09 | Política de la infra |
| `02-registro-activos` | 1ª semana y 06/10 | Hosts, VLANs, servicios |
| `03-analisis-riesgos` | 18/09 y 06/10 | Riesgos de la infra |
| `09-gestion-accesos` | 23-30/09 | MFA de consolas |
| `07-monitoreo-logs` | 28/09-01/10 | Reglas SIEM + alertas |
| `10-gestion-vulnerabilidades` | 01-05/10 | Escaneos + corrección |
| `06-plan-continuidad` | 28/09-01/10 | Backup de consolas + restauración |
| `04-gestion-incidentes` | 02-05/10 | Ataques simulados |
| `11-soa-plan-tratamiento` | 05-07/10 | SoA + brecha MCU (Avanzado) |
| `12-notificacion-incidentes` | 05-07/10 | Notificación simulada |
| **Excel `01-controles-mcu5-perfil-avanzado`** | Semanal | Evidencia + cómo se demuestra por control |
| **Excel `02-registro-activos-mcu5`** | 1ª semana | Activos reales de la red |
| **Excel `03-matriz-raci-mcu5`** | 23/09 | RACI de procesos de red |
| **Excel `04-bitacora-planilla`** | Diario | Entradas firmadas |
| **Arquitectura 4+1 (vista física/red) + C4** | 18/09 | Diagrama de red completo |

### 8.2 Entrega a Red Team

**Cómo**: `git tag v1.0` + docs congelada + demo. **Cuándo**: pre-entrega **07/10/2026**.

### 8.3 Red Team

Pre-entrega **28/10/2026**, entrega final **09/11/2026**. Esquema idéntico: hallazgos → `04`/`10`; informe final `plantilla/informe-red-team.md`; bitácora diaria; foro; cierre con correcciones.

## 9. Criterios de evaluación

| Criterio | Peso |
|---|---|
| Consigna propia (escenario + casos de uso) | 15% |
| RF implementados y demostrables | 30% |
| Documentación (plantillas + Excel MCU Avanzado) | 20% |
| Demostración en vivo de detección→respuesta automatizada | 10% |
| Desempeño Red Team | 15% |
| Presentación + bitácora | 10% |

## 10. Anexos

- Anexo A — Plantilla de consigna propia (escenario, red, casos de uso).
- Anexo B — Lista de firmas/reglas mínimas a instalar en el SIEM.
- Anexo C — Formato de documentación de los ataques simulados.
- Anexo D — Plantillas de arquitectura 4+1 y C4 (`plantilla/`), con las vistas de red detalladas en la sección 0.2.
- Anexo E — Excel de controles/activos/RACI/bitácora (`plantilla/mcu5/excel/`).
- Anexo F — Plantilla de informe Red Team (`plantilla/informe-red-team.md`).