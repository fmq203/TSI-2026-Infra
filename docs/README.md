# docs — Carpeta de trabajo del equipo (Tarea 3)

Esta carpeta es el **espacio de trabajo** del equipo. Aquí se van copiando y completando las plantillas de `../plantilla/isaca/` conforme a la matriz de documentación de `../LETRA.md` (sección 8).

## Documentos a generar (se completa a medida que se avanza)

| Archivo esperado | Origen (plantilla) | Estado |
|---|---|---|
| `00-arquitectura.md` | nueva (diagrama de red + segmentación) | 🔶 borrador |
| `40-consigna-propia.md` | nueva (escenario empresarial + casos de uso) | 🔶 borrador |
| `01-politica-seguridad.md` | `plantilla/isaca/01-politica-seguridad.md` | 🔶 borrador — falta aprobación de la Dirección (simulada) |
| `02-Registro-Activos.md` | `plantilla/isaca/02-registro-activos.md` | ☐ |
| `03-analisis-riesgos.md` | `plantilla/isaca/03-analisis-riesgos.md` | 🔶 borrador — 13 riesgos (9 altos) con plan de tratamiento; falta aceptación del residual por el RSI |
| `04-gestion-incidentes.md` | `plantilla/isaca/04-gestion-incidentes.md` | 🔶 borrador — INC-001 (CU-01) cerrado; CU-02 sin ejecutar; CU-03 sin implementar |
| `06-Plan-Continuidad.md` | `plantilla/isaca/06-plan-continuidad.md` | ☐ |
| `07-monitoreo-logs.md` | `plantilla/isaca/07-monitoreo-logs.md` | 🔶 borrador — 1 de 8 fuentes de log verificada; retención de 90 días sin configurar |
| `09-gestion-accesos.md` | `plantilla/isaca/09-gestion-accesos.md` | 🔶 política definida — MFA sin implementar; decidir cómo proteger el dashboard de Wazuh (§1.1) |
| `10-Gestion-Vulnerabilidades.md` | `plantilla/isaca/10-gestion-vulnerabilidades.md` | ☐ |
| `11-SoA-Plan-Tratamiento.md` | `plantilla/isaca/11-soa-plan-tratamiento.md` | ☐ |
| `12-Notificacion-Incidentes.md` | `plantilla/isaca/12-notificacion-incidentes.md` | ☐ |
| `28-Informe-Blue-Team.md` | nueva (incluye análisis de la red) | ☐ |
| `99-bitacora-trabajo.md` | `plantilla/isaca/99-bitacora-trabajo.md` | 🔶 desde 01/10 (01-06/10 carga diferida, declarada); falta firma de ambos. Copia en Excel: `excel/04-bitacora-planilla.xlsx` |
| `evidencias/` | capturas, vídeos, pcap, logs | ☐ |

### Excel MCU 5.0 (`excel/`, plantillas de `plantilla/mcu5/excel/`)

| Archivo | Estado |
|---|---|
| `excel/01-controles-mcu5-perfil-avanzado.xlsx` | 🔶 47 controles: 5 implementados, 26 parciales, 15 pendientes, 1 N.A. (capacitación). Hoja Resumen por función |
| `excel/02-registro-activos-mcu5.xlsx` | 🔶 22 activos (A01-A22): hosts, servicios, datos, consolas y las 4 VLANs. Revisar dueños y clasificación entre los dos |
| `excel/03-matriz-raci-mcu5.xlsx` | 🔶 16 procesos de seguridad de la red (una sola A por proceso) + hoja `Roles` con propuesta de quién cubre cada rol — confirmar entre los dos |
| `excel/04-bitacora-planilla.xlsx` | 🔶 mismo contenido que `99-bitacora-trabajo.md` (lagunas en gris). Se carga a diario desde el 07/10 |

> Para el **Red Team**: copie esta carpeta (o el tag de git) y genere su informe en `02-informe-red-team.md` (nuevo), completando además las plantillas de incidentes/vulnerabilidades con cada hallazgo.