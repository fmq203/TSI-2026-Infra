# Notificación de Incidentes (BCU / URCDP) — FinSegura S.A.

> Plantilla base: `plantilla/isaca/12-notificacion-incidentes.md` (SI-NOT-12). Proceso
> de incidentes: `04-gestion-incidentes.md`. Escalamiento: `04` §4.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Responder** | Notificación y comunicación de incidentes (RS-05). |
| **MCU 5.0 (categorías)** | RS-04, RS-05 | Análisis y reporte. |
| **COBIT 2019** | DSS02, MEA01 | Escalamiento y aseguramiento. |
| **ISO/IEC 27001:2022** | A.5.5, A.5.26, A.5.27 | Contacto con autoridades, respuesta, aprendizaje. |
| **BCU — GSI** | Notificación de incidentes | Notificar incidentes relevantes al BCU en plazo. |
| **URCDP — Ley 18.331 + Dec. 414/009** | Art. 20 | Notificación de violaciones de datos personales a la URCDP y a los titulares. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-NOT-12 |
| Versión | 0.1 (borrador) |
| Responsable | RSI (**rol sin asignar**, ver `excel/03` hoja Roles) |
| Fecha | 07/10/2026 |

---

## 1. Instrucciones de llenado

- Un formulario por incidente; horas en **UTC** y en hora local de Uruguay (UTC−3).
- Evidencia técnica en `docs/evidencias/` con el prefijo del incidente.
- **Plazos legales: a confirmar.** No figuran en las plantillas del curso ni en el repo.
  Referencias a verificar antes de la auditoría: GSI del BCU para incidentes relevantes;
  para la URCDP, Ley 18.331 Art. 20 y su reglamentación (posiblemente Decreto 64/020).
  Hasta confirmarlos, el criterio interno es **notificar dentro de las 24 h siguientes a
  confirmar el incidente**.

## 2. Criterios de decisión

| Pregunta | Si la respuesta es sí |
|---|---|
| ¿Hay compromiso confirmado o probable de **datos personales** (A04, A13)? | Evaluar el riesgo para los titulares (fila siguiente) y notificar a la URCDP |
| ¿Hay riesgo real para los derechos de los titulares (robo de identidad, fraude)? | Notificar también a los titulares |
| ¿El incidente es **S0 o S1** (`04` §1), o afecta la disponibilidad del otorgamiento de préstamos más que el RTO (`06` §1)? | Notificar al BCU como incidente relevante |
| ¿Es S2 o S3 sin datos personales? | Solo registro interno (`04` §2) |

Toda evaluación —incluidas las que concluyen "no notificar"— se registra en §5 con su
fundamento.

## 3. Formulario de notificación al BCU — ejercicio de escritorio

> **EJERCICIO DE ESCRITORIO (INC-2026-004). No ocurrió.** Escenario hipotético para
> probar el circuito de notificación, basado en CU-05 (exfiltración por DNS), que **no
> está implementado**. Los valores marcados como *supuesto* son parte del ejercicio.

| Campo | Valor |
|---|---|
| Fecha y hora del incidente (UTC) | *Supuesto:* 06/10/2026 03:10 (00:10 UTC−3) |
| Fecha y hora de detección (UTC) | *Supuesto:* 06/10/2026 09:40, revisión diaria del dashboard (`07` §5) |
| Institución | FinSegura S.A. |
| Tipo de incidente | Fuga de datos (exfiltración) |
| Sistemas afectados | A03 app de préstamos, A04 base de clientes, A19 segmento Servidores |
| Datos afectados | Sí: datos personales y financieros de clientes (cédula, ingresos, historial de pagos) |
| Impacto estimado | *Supuesto:* 1.200 registros de clientes; sin indisponibilidad del servicio |
| Acciones de contención | Bloqueo de la salida a Internet de la VLAN Servidores en el router; contenedor de la app detenido y su volumen preservado como evidencia; credenciales de la base rotadas |
| Estado actual | Contenido, en análisis |
| Contacto de reporte | RSI de FinSegura — `soc@lab.local` |
| Plazo cumplido | A confirmar (§1) |

## 4. Formulario de notificación a la URCDP — ejercicio de escritorio

| Campo | Valor |
|---|---|
| Titular del tratamiento | FinSegura S.A. |
| Encargado del tratamiento | No aplica (infraestructura propia) |
| Fecha del incidente | *Supuesto:* 06/10/2026 |
| Descripción | Un atacante que comprometió la app de préstamos extrajo registros de la base de clientes codificándolos en consultas DNS hacia un dominio externo. La salida se produjo porque la VLAN Servidores tenía salida a Internet sin restricción (`03-analisis-riesgos.md` R05). |
| Categoría de datos | Identificación (cédula), económicos (ingresos, historial de pagos) |
| Personas afectadas | *Supuesto:* 1.200 |
| Riesgos para los afectados | Robo de identidad, fraude financiero, phishing dirigido |
| Medidas para mitigar | Contención (§3); restricción de la salida de Servidores (T05); detección de exfiltración por DNS (CU-05); revisión de accesos a la base |
| Notificación a los titulares | Plan: correo a cada titular afectado con lo ocurrido, los datos comprometidos y las precauciones recomendadas |
| Responsable del informe | RSI de FinSegura |

**Lo que dejó el ejercicio** (vale como lección aprendida aunque el incidente sea
hipotético): (1) el camino de exfiltración existe hoy en la configuración real del
router; (2) no hay detección para él (CU-05 pendiente); (3) no hay plazos legales
confirmados ni RSI asignado para firmar. Los tres están en el plan de tratamiento
(`03` T05 y `11` §5).

## 5. Registro de evaluaciones y notificaciones

| ID incidente | ¿Datos personales? | Severidad | Decisión | Fundamento | Fecha |
|---|---|---|---|---|---|
| INC-2026-001 (CU-01) | No | S3 | No notificar | Reconocimiento sin acceso a datos; simulación propia | 07/10/2026 |
| INC-2026-002 (CU-02) | No | S2 | No notificar | Intento contenido sobre un puesto de prueba; simulación propia (pendiente de ejecutar) | 07/10/2026 |
| INC-2026-003 (CU-03) | — | — | — | No implementado | — |
| INC-2026-004 (ejercicio) | Sí (supuesto) | S0 | Notificar a BCU y URCDP | §2: datos personales + S0 | 07/10/2026 |

| ID incidente | Autoridad | Fecha de envío | Canal | Estado | Responsable |
|---|---|---|---|---|---|
| INC-2026-004 | BCU / URCDP | **No enviado** (ejercicio de escritorio) | — | — | RSI |

---

## Check de aceptación

- [x] Plantilla de notificación BCU completa (ejercicio).
- [x] Plantilla de notificación URCDP completa (ejercicio).
- [x] Criterios de decisión definidos.
- [ ] Al menos un incidente simulado documentado de punta a punta — el circuito de
  notificación se recorrió en el ejercicio de escritorio; un incidente técnico de punta a
  punta (INC-2026-002) está pendiente de ejecutar.
- [ ] Plazos legales confirmados — pendiente.
