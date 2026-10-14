# docs — Carpeta de trabajo del equipo (Tarea 3)

Esta carpeta es el **espacio de trabajo** del equipo. Aquí se van copiando y completando las plantillas de `../plantilla/isaca/` conforme a la matriz de documentación de `../LETRA.md` (sección 8).

## Documentos a generar (se completa a medida que se avanza)

| Archivo esperado | Origen (plantilla) | Estado |
|---|---|---|
| `00-arquitectura.md` | nueva (diagrama de red + segmentación) | 🔶 borrador — diagramas de topología y de las 3 cadenas detección→respuesta→notificación en Mermaid |
| `40-consigna-propia.md` | nueva (escenario empresarial + casos de uso) | 🔶 borrador |
| `01-politica-seguridad.md` | `plantilla/isaca/01-politica-seguridad.md` | 🔶 borrador — falta aprobación de la Dirección (simulada) |
| `02-Registro-Activos.md` | `plantilla/isaca/02-registro-activos.md` | ☐ (ver `excel/02-registro-activos-mcu5.xlsx`) |
| `03-analisis-riesgos.md` | `plantilla/isaca/03-analisis-riesgos.md` | 🔶 borrador — 13 riesgos con plan de tratamiento; R03/R04 (CU-02/CU-03) mitigados y verificados (14/10); falta aceptación del residual por el RSI |
| `04-gestion-incidentes.md` | `plantilla/isaca/04-gestion-incidentes.md` | 🔶 borrador — **CU-01, CU-02 y CU-03 verificados de punta a punta** (detección→respuesta→notificación, 14/10), con MTTD/MTTR reales |
| `06-plan-continuidad.md` | `plantilla/isaca/06-plan-continuidad.md` | 🔶 borrador — RTO/RPO e inventario de respaldo definidos; **sin respaldos de datos ni prueba de restauración** |
| `07-monitoreo-logs.md` | `plantilla/isaca/07-monitoreo-logs.md` | 🔶 borrador — 3 de 8 fuentes de log verificadas (NIDS, puesto de usuario, FIM de la app); retención de 90 días sin configurar |
| `09-gestion-accesos.md` | `plantilla/isaca/09-gestion-accesos.md` | 🔶 política definida — TOTP validado en Keycloak (realm `lab`); WebAuthn pendiente de HTTPS; decidir cómo proteger el dashboard de Wazuh (§1.1) |
| `10-Gestion-Vulnerabilidades.md` | `plantilla/isaca/10-gestion-vulnerabilidades.md` | ☐ |
| `11-soa-plan-tratamiento.md` | `plantilla/isaca/11-soa-plan-tratamiento.md` | 🔶 borrador — Anexo A completo (93: 68 aplican, 25 N/A); brecha MCU por función (Detectar y Responder subieron de madurez el 14/10); falta aprobación |
| `12-notificacion-incidentes.md` | `plantilla/isaca/12-notificacion-incidentes.md` | 🔶 borrador — criterios, evaluación de INC-001..004 (INC-002/003 cerrados de punta a punta) y ejercicio de escritorio (INC-004); plazos legales a confirmar |
| `28-Informe-Blue-Team.md` | nueva (incluye análisis de la red) | ☐ |
| `99-bitacora-trabajo.md` | `plantilla/isaca/99-bitacora-trabajo.md` | 🔶 desde 01/10 (01-06/10 carga diferida, declarada); falta firma de ambos. Copia en Excel: `excel/04-bitacora-planilla.xlsx` |
| `evidencias/` | capturas, vídeos, pcap, logs | ✅ `CU-01_INC-2026-001/`, `CU-02/` y `CU-03_INC-2026-003/` con evidencia real (detección, respuesta y notificación por mail), última tanda 14/10 |

### Excel MCU 5.0 (`excel/`, plantillas de `plantilla/mcu5/excel/`)

| Archivo | Estado |
|---|---|
| `excel/01-controles-mcu5-perfil-avanzado.xlsx` | 🔶 47 controles: 11 implementados, 26 parciales, 9 pendientes, 1 N.A. (capacitación). Hoja Resumen por función |
| `excel/02-registro-activos-mcu5.xlsx` | 🔶 22 activos (A01-A22): hosts, servicios, datos, consolas y las 4 VLANs. Revisar dueños y clasificación entre los dos |
| `excel/03-matriz-raci-mcu5.xlsx` | 🔶 16 procesos de seguridad de la red (una sola A por proceso) + hoja `Roles` con propuesta de quién cubre cada rol — confirmar entre los dos |
| `excel/04-bitacora-planilla.xlsx` | 🔶 mismo contenido que `99-bitacora-trabajo.md` (lagunas en gris). Se carga a diario desde el 07/10 |

> Para el **Red Team**: copie esta carpeta (o el tag de git) y genere su informe en `02-informe-red-team.md` (nuevo), completando además las plantillas de incidentes/vulnerabilidades con cada hallazgo.