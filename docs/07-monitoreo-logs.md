# Monitoreo, Logs y SIEM — FinSegura S.A.

> Plantilla base: `plantilla/isaca/07-monitoreo-logs.md` (SI-MON-07). Configuración real:
> `infra/siem-hids/`, `infra/nids/`, `infra/honeypot/`.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Detectar** | Detección temprana de eventos y análisis continuo. |
| **MCU 5.0 (categorías)** | DE-01, DE-02, DE-03 | Anomalías y eventos, monitoreo continuo, análisis de detección. |
| **COBIT 2019** | DSS04, DSS05 | Registro y revisión de eventos. |
| **ISO/IEC 27001:2022** | A.8.15, A.8.16 | Registro y monitorización. |
| **NIST SP 800-92 (referencial)** | Gestión de logs | Retención y correlación. |
| **BCU — GSI** | Monitoreo y registro | Monitoreo de eventos de seguridad. |
| **URCDP — Ley 18.331, Art. 9 y 12** | Trazabilidad | Registro de accesos a datos personales. |
| **MCU 5.0 + BCU Com. 2026/098** | Madurez en Detectar | Indicadores de monitoreo. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-MON-07 |
| Versión | 0.1 (borrador) |
| Responsable | Analista SOC (ver `excel/03`, hoja Roles) |
| Fecha | 07/10/2026 |

Horas en **UTC** en todos los registros (RNF-05).

---

## 1. Arquitectura de monitoreo

| Capa | Herramienta | Dónde | Rol | Estado al 07/10 |
|---|---|---|---|---|
| Red (NIDS) | Suricata (`jasonish/suricata`) | DMZ, 10.10.20.50 | Detección de tráfico; escribe `eve.json` | ✅ verificado (CU-01) |
| Engaño | Cowrie | DMZ, 10.10.20.30 | Honeypot SSH/Telnet; escribe `cowrie.json` | 🔶 conectado, sin verificar |
| Host (HIDS) | Agente Wazuh 4.9.0 | Embebido en `target-ssh-client` (10.10.30.10) | `auth.log`, FIM, Active Response | ✅ conectado 07/10 (FIM, SCA y rootcheck corriendo); Active Response sin probar |
| SIEM | Wazuh manager + indexer + dashboard 4.9.0 | Gestión, 10.10.90.10/.11/.12 | Decodificación, reglas, correlación, almacenamiento, consola | ✅ |
| SOAR | Wazuh Active Response | Manager → agentes | Respuesta automatizada (`firewall-drop`) | 🔶 sin verificar |
| Alertas | `email_notification` del manager → docker-mailserver | DMZ, 10.10.20.20 | Mail a `soc@lab.local` para nivel ≥ 10 | 🔶 configurado, sin captura |

Flujo: sensores → manager (Suricata y Cowrie por volumen compartido; agentes por
1514/1515 TCP) → reglas (`local_rules.xml`) → indexer (Filebeat) → dashboard; en
paralelo, Active Response y mail. Toda la configuración del manager la aplica
`infra/siem-hids/configure-manager.sh` (idempotente, la corre `make up`).

**Decisiones:** sin TheHive/Cortex (SOAR = Active Response, `brain/decisions.md`
2026-09-14); 2º canal de alerta (webhook/Wazo) recortado con justificación
(2026-10-05).

## 2. Fuentes de log

| Fuente | Componente | Eventos | Relevancia | ¿Llega al SIEM? |
|---|---|---|---|---|
| NIDS | Suricata `eve.json` | Alertas de firmas, flows | Alta | ✅ Sí (verificado 05/10) |
| Honeypot | Cowrie `cowrie.json` | Logins, comandos del atacante | Alta | 🔶 Configurado, sin verificar |
| Puesto de usuario | `auth.log` vía agente | Logins SSH exitosos/fallidos | Alta | 🔶 Agente conectado (07/10); eventos de login sin verificar |
| App de préstamos | Apache/PHP de DVWA | Accesos, 4xx/5xx, archivos del webroot | Alta | ❌ No (falta agente — CU-03) |
| Base de clientes | MySQL | Conexiones, errores | Alta | ❌ No |
| Identidad | Keycloak | Autenticaciones, MFA | Alta | ❌ No (CU-04) |
| Correo | docker-mailserver | Auth, envío | Media | ❌ No |
| Router/firewall | nftables / OPNsense | Bloqueos y permisos | Alta | ❌ No (y la regla de bloqueo por defecto no tiene log — lección de INC-2026-001) |

## 3. Casos de uso / reglas de detección

| ID | Nombre | Fuente | Condición de alerta | Severidad | Respuesta | Estado |
|---|---|---|---|---|---|---|
| CU-01 | Reconocimiento contra la red interna | Suricata → Wazuh 86601 → **100100** | SIDs propios 1000001 (≥ 20 SYN en 10 s por origen), 1000002-1000004 (escaneos NULL/FIN/XMAS), 1000005 (≥ 10 ICMP echo en 5 s) | S3 (nivel 10 para que notifique) | Alerta + mail | ✅ verificado 05/10 |
| CU-02 | Fuerza bruta SSH | Agente → reglas sshd **5712/5763** | Fallos de autenticación repetidos | S2 (nivel 10) | `firewall-drop` 10 min (regla 651) + mail | 🔶 sin verificar |
| — | Login en el honeypot | Cowrie → **100110** | `eventid = cowrie.login.failed` | S3 (nivel 8, sin mail) | Alerta en el dashboard | 🔶 sin verificar |
| CU-03 | Webshell en la app | Agente FIM | Archivo nuevo/modificado en el webroot | S1 | Aislar el contenedor | ❌ pendiente |
| CU-04 | Credenciales robadas contra consolas | Keycloak | Login fallido / MFA fallido | S0-S1 | Deshabilitar cuenta (playbook 3) | ❌ pendiente |
| CU-05 | Exfiltración por DNS | Suricata | Volumen/patrón anómalo de consultas DNS | S0 | Alerta + mail | ❌ pendiente |

Reglas en el repo: `infra/nids/rules/local.rules` y
`infra/siem-hids/config/wazuh_manager/local_rules.xml`. **Brecha:** Suricata no carga
ningún ruleset público (solo las 5 reglas propias) — ver `03-analisis-riesgos.md` R07.

## 4. Retención y almacenamiento

| Índice/log | Retención online | Retención fría | Formato | Estado |
|---|---|---|---|---|
| Alertas SIEM (`wazuh-alerts-*`) | 90 días (RF-15) | Snapshot del indexer | JSON | ❌ **No configurado**: hoy los índices no tienen política de borrado ni respaldo |
| Logs del manager (`alerts.json`, `archives`) | 90 días | — | JSON | Rotación por defecto de Wazuh, sin respaldo |
| `eve.json` / `cowrie.json` | Hasta que los lee el manager | — | JSON | Volúmenes Docker |

Pendiente: política ISM de 90 días en el indexer y snapshot con prueba de restauración
(`03-analisis-riesgos.md` T08; `06-plan-continuidad`).

## 5. Revisión y operación

- **Revisión diaria** del dashboard (alertas nivel ≥ 7) por el Analista SOC; cada
  alerta S0-S2 se registra en `04-gestion-incidentes.md`.
- **SLA de triage:** S0/S1 < 1 h; S2 < 4 h; S3 en la revisión diaria.
- **Cambios de reglas:** solo vía el repo; `configure-manager.sh` valida con
  `wazuh-analysisd -t` antes de reiniciar el manager.
- **Diagnóstico por tramos** cuando una alerta no aparece (aprendido en CU-01):
  1. `eve.json` / `cowrie.json` / `auth.log` en el origen.
  2. `grep` en `/var/ossec/logs/alerts/alerts.json` del manager.
  3. `filebeat test output`.
  4. `curl wazuh.indexer:9200/_cat/indices/wazuh-alerts*`.

## 6. Evidencias de detección (KPIs)

| Indicador | Valor medido |
|---|---|
| Eventos de anormalidad detectados | CU-01: alertas 1000005 y 1000001 (05/10). Cantidad exacta: tomar de la captura del dashboard |
| Alertas críticas generadas | No medido |
| Tiempo de detección promedio | No medido (falta registrar la hora del ataque frente a la de la alerta) |
| Falsos positivos | No medido |

---

## Check de aceptación

- [ ] Todos los componentes de la solución emiten logs al SIEM — **no**: 1 de 8 fuentes
  verificada (§2).
- [ ] Al menos 4 casos de uso implementados — 1 verificado, 2 construidos sin verificar.
- [ ] Retención definida y respaldo de logs — definida (90 días), **no configurada**.
- [ ] Evidencia de alertas reales durante la validación — CU-01 sin capturas todavía.
