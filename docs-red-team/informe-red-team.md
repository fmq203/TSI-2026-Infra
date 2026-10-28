# Plantilla de Informe de Evaluación Red Team

> Este documento es la **plantilla del informe** que el equipo Red Team debe entregar al finalizar la Parte 2 de cada tarea. Se completa y se entrega en `docs/informe-red-team.md` (+ DOCX).
> Estructura alineada al reporte de una **prueba de penetración / auditoría técnica**, con mapeo a normativa uruguaya.

---

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0** | **Detectar** (DE-03) / **Responder** (RS-01) | El informe evidencia la eficacia de los controles de detección y respuesta. |
| **BCU — GSI** | Requisito de evaluación de controles / incidentes | Insumo para gestión de incidentes y mejora. |
| **ISO/IEC 27001:2022** | A.5.24 – A.5.28 | Gestión de incidentes y aprendizaje. |
| **ISO/IEC 27005 / 31000** | Riesgo | Priorización de hallazgos por riesgo. |
| **COBIT 2019** | MEA02 (Evaluación del sistema de control) | Evaluación de controles. |

---

## Control del documento

| Campo | Valor |
|---|---|
| Título | Informe de evaluación técnica — Red Team |
| Código | `RT-T3-2026` |
| Cliente/cátedra | `[Docente]` |
| Periodo de evaluación | `[inicio] → [fin]` |
| Equipo Red Team | `[integrantes]` |
| Sistemas evaluados | `[Solución T1/T2/T3]` |
| Alcance autorizado | `[IPs/VMs/hosts]` |
| Versión | 1.0 |
| Fecha | `[DD/MM/AAAA]` |

---

## 1. Resumen ejecutivo

- Contexto del objetivo evaluado (breve descripción de la solución).
- **Principales hallazgos** (tabla con severidad y cantidad).
- **Postura de seguridad**: conclusión general (p. ej.: "la solución presenta una exposición media-baja, con 3 hallazgos altos resueltos durante la evaluación").
- Valoración de madurez MCU 5.0 observada.

## 2. Alcance y reglas de compromiso

- Inventario de objetivos evaluados y técnicas autorizadas.
- Vetos (no se realizó: DoS destructivo, exfiltración real, etc.).
- Entorno (diagrama de la red de laboratorio del Blue Team).

## 3. Metodología

- Referencias: **PTES / OWASP Testing Guide / MITRE ATT&CK / NIST SP 800-115**.
- Fases ejecutadas: Planificación → Reconocimiento → Escaneo → Explotación → Post-explotación → Reporte.
- Herramientas utilizadas (todas open source).

## 4. Inventario de hallazgos (resumen)

| ID | Activo | Tipo | Severidad (CVSS) | Estado | Repro (S/N) | Técnica MITRE |
|---|---|---|---|---|---|---|
| RT-01 | | | | | | |
| RT-02 | | | | | | |

## 5. Detalle de hallazgos

Para cada hallazgo (uno por bloque):

| Campo | Contenido |
|---|---|
| **ID** | RT-`NN` |
| **Descripción** | Qué y dónde |
| **Vulnerabilidad** | CVE/CWE o debilidad concreta |
| **Severidad** | CVSS v3.x base vector |
| **Reproducción (repro)** | Paso a paso técnico (comandos/capturas) |
| **Impacto** | Qué se logró (acceso, datos, control) |
| **Técnica** | MITRE ATT&CK ID/táctica |
| **Evidencia** | Capturas/logs en `docs/evidencias/red-team/` |
| **Recomendación** | Cómo corregir (control ISO/MCU recomendado) |

## 6. Mapeo a MITRE ATT&CK

Tabla de tácticas → técnicas → hallazgos asociados (opcional incluir diagrama de navegación).

## 7. Evaluación de la respuesta del Blue Team

- ¿Cómo respondió el Blue Team a cada ataque? (bitácora/registros: bloqueo, alerta, aislamiento).
- ¿Fueron efectivos los controles SIEM/SOAR?
- Comparación contra lo declarado en la `SoA` (brechas de madurez).

## 8. Lecciones aprendidas y recomendaciones

- Acciones correctivas prioritarias (orden por riesgo).
- Mejoras de arquitectura y monitoreo.
- Recomendaciones de cumplimiento (MCU 5.0 / BCU / URCDP / ISO).

## 9. Anexos

- Anexo A — Bitácora del Red Team (tabla completa → `docs/`).
- Anexo B — Evidencias (índice de archivos en `docs/evidencias/red-team/`).
- Anexo C — Conteo de resultados: IPs escaneadas, servicios identificados, hallazgos por severidad.