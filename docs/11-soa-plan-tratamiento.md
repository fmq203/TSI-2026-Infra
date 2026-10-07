# Declaración de Aplicabilidad (SoA) y Plan de Tratamiento — FinSegura S.A.

> Plantilla base: `plantilla/isaca/11-soa-plan-tratamiento.md` (SI-SOA-11). Fuentes:
> `excel/01-controles-mcu5-perfil-avanzado.xlsx` (brecha MCU), `03-analisis-riesgos.md`
> (plan de tratamiento), `excel/02-registro-activos-mcu5.xlsx` (activos).

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Gobernar + Proteger** | Perfil de cumplimiento y priorización. |
| **MCU 5.0 (categorías)** | GV-01 a GV-06, PR-01 a PR-08 | Perfil **Avanzado**. |
| **COBIT 2019** | EDM01, EDM03, APO13, MEA01 | Gobierno, riesgo y aseguramiento. |
| **ISO/IEC 27001:2022** | Anexo A completo + cláusula 6.1.3 | Controles aplicables o no, con justificación. |
| **ISO/IEC 27002** | Controles del Anexo A | Definición de aplicabilidad. |
| **BCU — GSI** | Esquema de requerimientos | Evidencia del cumplimiento. |
| **URCDP — Ley 18.331, Art. 9 y 12** | Medidas de seguridad | Controles que protegen datos personales. |
| **MCU 5.0 + BCU Com. 2026/098** | Brecha de madurez | Nivel por función. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-SOA-11 |
| Versión | 0.1 (borrador) |
| Metodología | ISO/IEC 27001:2022 (Anexo A) + MCU 5.0 |
| Fecha | 07/10/2026 |

> **Nota sobre la plantilla:** dice que el Anexo A tiene 79 controles (37 + 4 + 5 + 33).
> ISO/IEC 27001:2022 tiene **93**: 37 organizacionales, 8 de personas, 14 físicos y 34
> tecnológicos. Acá se usan los 93. En el ejemplo de la plantilla, "Controles
> criptográficos" figura como A.8.1; en la norma es **A.8.24** (A.8.1 es "Dispositivos de
> usuario final").

---

## 1. Alcance de la declaración

- **Sistema:** infraestructura de red de defensa de FinSegura S.A. (LETRA.md, Tarea 3).
- **Componentes en alcance:** router/firewall, 4 VLANs, `docker-host`, Wazuh (manager,
  indexer, dashboard), Suricata, Cowrie, Keycloak, correo, app de préstamos y base de
  clientes (representadas por DVWA y MySQL), puesto de usuario, repositorio
  `TSI-2026-Infra` — activos A01-A22.
- **Criterios de aplicabilidad:** se declaran **N/A** los controles que suponen
  instalaciones físicas propias (laboratorio virtual), personal real (empresa ficticia) o
  actividades que la solución no realiza (desarrollo tercerizado, desarrollo de la app).
  Cada N/A lleva su justificación; ninguno se omite.

## 2. Resumen de estado

Contado sobre la tabla de §3.

| Categoría | Total | Aplicables | N/A (justificados) | Implementado | Parcial | Pendiente |
|---|---|---|---|---|---|---|
| A.5 Controles organizacionales | 37 | 35 | 2 | 3 | 20 | 12 |
| A.6 Controles de personas | 8 | 2 | 6 | 0 | 1 | 1 |
| A.7 Controles físicos | 14 | 0 | 14 | 0 | 0 | 0 |
| A.8 Controles tecnológicos | 34 | 31 | 3 | 4 | 18 | 9 |
| **Total** | **93** | **68** | **25** | **7** | **39** | **22** |

## 3. Declaración de aplicabilidad (Anexo A completo)

"Estado" solo aplica a los controles que aplican: **Implementado** = funcionando y con
evidencia en el repo; **Parcial** = existe pero incompleto o sin verificar;
**Pendiente** = definido, no implementado.

| ID | Control | ¿Aplica? | Justificación | Insumo / evidencia | Estado al 07/10 |
|---|---|---|---|---|---|
| A.5.1 | Políticas de seguridad de la información | Sí | — | docs/01-politica-seguridad.md | Parcial — borrador sin aprobar |
| A.5.2 | Roles y responsabilidades | Sí | — | excel/03 (RACI + Roles) | Parcial — RSI y Admin IAM sin asignar |
| A.5.3 | Segregación de funciones | Sí | — | excel/03 (A ≠ R donde es posible) | Parcial — equipo de 2 personas |
| A.5.4 | Responsabilidades de la dirección | Sí | — | docs/01 §6 | Pendiente — aprobación de la Dirección |
| A.5.5 | Contacto con las autoridades | Sí | — | docs/12-notificacion-incidentes.md | Parcial — plazos a confirmar |
| A.5.6 | Contacto con grupos de interés especial | Sí | — | CERTuy como referente (docs/12) | Pendiente |
| A.5.7 | Inteligencia de amenazas | Sí | — | Ruleset público de Suricata (03 R07) | Pendiente |
| A.5.8 | Seguridad en la gestión de proyectos | Sí | — | brain/decisions.md, plan de recuperación | Parcial |
| A.5.9 | Inventario de información y activos | Sí | — | excel/02 (A01-A22) | Implementado |
| A.5.10 | Uso aceptable de la información y activos | Sí | — | docs/01 §5 (reglas para todos) | Parcial |
| A.5.11 | Devolución de activos | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. | — | — |
| A.5.12 | Clasificación de la información | Sí | — | excel/02 (Clasificación) | Parcial — a revisar |
| A.5.13 | Etiquetado de la información | Sí | — | — | Pendiente |
| A.5.14 | Transferencia de información | Sí | — | TLS en mail; config.xml por canal privado | Parcial |
| A.5.15 | Control de accesos | Sí | — | Segmentación (docs/00) + docs/09 | Parcial — MFA pendiente |
| A.5.16 | Gestión de identidades | Sí | — | docs/09 §2-3; Keycloak | Pendiente |
| A.5.17 | Información de autenticación | Sí | — | docs/09 §4-5; .env fuera del repo | Parcial — contraseñas por defecto (03 R02) |
| A.5.18 | Derechos de acceso | Sí | — | docs/09 §2 (revisión mensual) | Pendiente |
| A.5.19 | Seguridad en relaciones con proveedores | Sí | — | docs/01 §5 (terceros) | Parcial |
| A.5.20 | Seguridad en acuerdos con proveedores | N/A | No hay contratos: los terceros son imágenes open source y GitHub con términos estándar. El riesgo se trata en A.5.21. | — | — |
| A.5.21 | Seguridad en la cadena de suministro TIC | Sí | — | 03 R10 (imágenes :latest) | Parcial |
| A.5.22 | Monitoreo y cambios de servicios de proveedores | Sí | — | Seguimiento de versiones/CVE de imágenes | Pendiente |
| A.5.23 | Seguridad en servicios en la nube | Sí | — | GitHub: repo público sin secretos (.gitignore) | Parcial — sin escaneo de secretos (03 R13) |
| A.5.24 | Planificación de la gestión de incidentes | Sí | — | docs/04 §1-3 | Parcial — borrador |
| A.5.25 | Evaluación y decisión sobre eventos | Sí | — | docs/04 §1 (S0-S3) | Parcial |
| A.5.26 | Respuesta a incidentes | Sí | — | docs/04 §3.2; Active Response | Parcial — CU-02 sin verificar |
| A.5.27 | Aprendizaje de los incidentes | Sí | — | docs/04 §5; brain/LEARNINGS.md | Implementado |
| A.5.28 | Recolección de evidencia | Sí | — | docs/evidencias/README.md | Parcial — sin artefactos |
| A.5.29 | Seguridad durante una disrupción | Sí | — | docs/06 §4 | Pendiente |
| A.5.30 | Preparación TIC para la continuidad | Sí | — | docs/06 §0 (reconstrucción desde el repo) | Parcial — datos sin respaldo |
| A.5.31 | Requisitos legales, regulatorios y contractuales | Sí | — | Ley 18.331, GSI BCU (docs/01 §3) | Parcial — plazos a confirmar |
| A.5.32 | Derechos de propiedad intelectual | Sí | — | Licencias de las imágenes usadas | Pendiente — no revisadas |
| A.5.33 | Protección de registros | Sí | — | docs/07 §4 (retención 90 días) | Pendiente — sin configurar |
| A.5.34 | Privacidad y protección de datos personales | Sí | — | excel/02 (Dato personal); 03 R05 | Parcial — sin cifrado en reposo |
| A.5.35 | Revisión independiente de la seguridad | Sí | — | Auditoría 14/10 y Red Team 28/10-09/11 | Pendiente (planificada) |
| A.5.36 | Cumplimiento de políticas y normas | Sí | — | excel/01 (brecha MCU) | Pendiente |
| A.5.37 | Procedimientos operativos documentados | Sí | — | README, infra/README, vagrant/README, evidencias/README | Implementado |
| A.6.1 | Verificación de antecedentes | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. | — | — |
| A.6.2 | Términos y condiciones de empleo | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. | — | — |
| A.6.3 | Concienciación, educación y capacitación | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. Coherente con el Excel 01 (capacitación N.A.). | docs/01 §7 | — |
| A.6.4 | Proceso disciplinario | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. | — | — |
| A.6.5 | Responsabilidades tras la desvinculación | Sí | — | docs/09 §2 (baja ≤ 24 h) | Pendiente |
| A.6.6 | Acuerdos de confidencialidad | N/A | Empresa ficticia sin personal real: no hay contratación, empleo ni desvinculación que gestionar. | — | — |
| A.6.7 | Trabajo remoto | N/A | El escenario no contempla teletrabajo; el acceso administrativo es solo desde la VLAN de Gestión. | — | — |
| A.6.8 | Reporte de eventos de seguridad | Sí | — | Canal soc@lab.local (docs/01 §7) | Parcial |
| A.7.1 | Perímetros de seguridad física | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.2 | Controles de entrada física | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.3 | Seguridad de oficinas, salas e instalaciones | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.4 | Monitoreo de la seguridad física | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.5 | Protección contra amenazas físicas y ambientales | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.6 | Trabajo en áreas seguras | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.7 | Escritorio y pantalla limpios | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.8 | Ubicación y protección del equipamiento | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.9 | Seguridad de activos fuera de las instalaciones | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.10 | Medios de almacenamiento | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.11 | Servicios de suministro | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.12 | Seguridad del cableado | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.13 | Mantenimiento del equipamiento | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.7.14 | Eliminación o reutilización segura del equipamiento | N/A | Laboratorio 100 % virtual sobre infraestructura del curso; la seguridad física del hardware está fuera del alcance de la solución. | — | — |
| A.8.1 | Dispositivos de usuario final | Sí | — | Puesto A05 con agente Wazuh | Parcial — sin verificar |
| A.8.2 | Derechos de acceso privilegiado | Sí | — | docs/09 §3 | Pendiente — cuentas compartidas de laboratorio |
| A.8.3 | Restricción del acceso a la información | Sí | — | Segmentación VLAN (docs/40 §2) | Parcial |
| A.8.4 | Acceso al código fuente | Sí | — | Repo público (IaC sin secretos); escritura solo del equipo | Parcial — revisión previa desde 07/10 |
| A.8.5 | Autenticación segura | Sí | — | docs/09 §1 (MFA, Argon2) | Pendiente |
| A.8.6 | Gestión de la capacidad | Sí | — | infra/README (RAM por stack); 03 R12 | Parcial |
| A.8.7 | Protección contra malware | Sí | — | HIDS Wazuh (rootcheck, FIM) | Parcial — sin antimalware |
| A.8.8 | Gestión de vulnerabilidades técnicas | Sí | — | docs/10 (pendiente) | Pendiente |
| A.8.9 | Gestión de la configuración | Sí | — | Infraestructura como código (repo) | Parcial — 4 imágenes :latest |
| A.8.10 | Eliminación de información | Sí | — | Política de retención (docs/07 §4) | Pendiente |
| A.8.11 | Enmascaramiento de datos | N/A | No hay datos reales de clientes en ningún entorno: la app es DVWA con datos de prueba (ver A.8.33). | — | — |
| A.8.12 | Prevención de fuga de datos | Sí | — | 03 R05 (egress), CU-05 | Pendiente |
| A.8.13 | Copias de seguridad | Sí | — | docs/06 §2 | Pendiente |
| A.8.14 | Redundancia de instalaciones | Sí | Un solo nodo en el laboratorio: la redundancia se reemplaza por reconstrucción desde el repo (docs/06 §0). Riesgo a aceptar por el RSI. | docs/06 | Pendiente — riesgo a aceptar |
| A.8.15 | Registro (logging) | Sí | — | docs/07 §2 | Parcial — 1 de 8 fuentes verificada |
| A.8.16 | Actividades de monitoreo | Sí | — | Wazuh + Suricata; CU-01 (INC-2026-001) | Parcial |
| A.8.17 | Sincronización de relojes | Sí | — | Contenedores usan el reloj del host; registros en UTC (RNF-05) | Parcial — NTP del host sin verificar |
| A.8.18 | Uso de utilitarios privilegiados | Sí | — | NET_ADMIN solo en ssh-client y mailserver; docker-host LXC privilegiado | Parcial — justificar |
| A.8.19 | Instalación de software en sistemas operativos | Sí | — | Solo vía imágenes definidas en el repo | Parcial |
| A.8.20 | Seguridad de redes | Sí | — | Router + reglas (docs/00, provision-router.sh) | Implementado |
| A.8.21 | Seguridad de los servicios de red | Sí | — | Reglas por puerto entre dominios | Parcial — TLS faltante (03 R09) |
| A.8.22 | Segregación de redes | Sí | — | 4 VLANs, política por defecto: denegar | Implementado |
| A.8.23 | Filtrado web | Sí | — | Salida a Internet sin restringir (03 R05) | Pendiente |
| A.8.24 | Uso de criptografía | Sí | — | TLS en mail; Argon2 (docs/09) | Parcial |
| A.8.25 | Ciclo de vida de desarrollo seguro | Sí | Aplica al código de infraestructura (compose, scripts); no hay desarrollo de aplicaciones. | Revisión previa al merge (docs/01 §5) | Parcial |
| A.8.26 | Requisitos de seguridad de las aplicaciones | N/A | La app de negocio está representada por DVWA, vulnerable a propósito como blanco de simulación; su desarrollo está fuera del alcance. | — | — |
| A.8.27 | Arquitectura y principios de ingeniería segura | Sí | — | docs/00 (defensa en profundidad), docs/01 §4 | Parcial |
| A.8.28 | Codificación segura | Sí | Aplica a scripts y compose del repo. | semgrep + gitleaks (Excel 01, SAST) | Pendiente |
| A.8.29 | Pruebas de seguridad en desarrollo y aceptación | Sí | — | CU-01 verificado; Red Team 28/10 | Parcial |
| A.8.30 | Desarrollo tercerizado | N/A | No se terceriza desarrollo. | — | — |
| A.8.31 | Separación de entornos | Sí | — | Despliegue de referencia (Proxmox) separado de vagrant/ (prueba y Red Team) | Implementado |
| A.8.32 | Gestión de cambios | Sí | — | git + brain/decisions.md; revisión previa (03 T11) | Parcial |
| A.8.33 | Información de prueba | Sí | — | No se usan datos reales de clientes en pruebas | Implementado |
| A.8.34 | Protección de sistemas durante auditorías | Sí | — | Reglas de compromiso del Red Team (LETRA.md §7.1) | Parcial |

## 4. Análisis de brecha MCU 5.0

**Escala de madurez** (valoración del equipo): 0 inexistente · 1 inicial (documentado en
borrador o ad hoc) · 2 implementado en parte y repetible · 3 definido, implementado y
verificado con evidencia · 4 gestionado y medido. **Objetivo del perfil Avanzado: 3.**

Base: hoja "Resumen" de `excel/01-controles-mcu5-perfil-avanzado.xlsx` (47 controles).

| Función MCU 5.0 | Perfil objetivo | Evidencia que lo sostiene | Controles (impl / parcial / pend / N.A.) | Madurez actual | Acciones prioritarias |
|---|---|---|---|---|---|
| Gobernar | Avanzado (3) | Política (01), RACI (excel/03), decisiones fechadas | 0 / 7 / 1 / 0 | **1** | Aprobar la política; asignar RSI; SoA aprobada |
| Identificar | Avanzado (3) | Inventario A01-A22, riesgos (03) | 1 / 5 / 2 / 0 | **1** | Escaneo de vulnerabilidades (10); aceptación del residual |
| Proteger | Avanzado (3) | Segmentación en 4 VLANs con reglas | 1 / 4 / 6 / 1 | **1** | MFA en consolas (T01); credenciales (T02); respaldos (06) |
| Detectar | Avanzado (3) | CU-01 verificado; reglas de umbral | 2 / 5 / 1 / 0 | **2** | Fuentes de log al SIEM; ruleset público (T07); retención (T08) |
| Responder | Avanzado (3) | Plan (04), lecciones aprendidas | 1 / 3 / 2 / 0 | **1** | Verificar CU-02 con evidencia (T03); CU-03 (T04) |
| Recuperar | Avanzado (3) | Reconstrucción desde el repo (06 §0) | 0 / 2 / 3 / 0 | **1** | Respaldos de datos y prueba de restauración (06 §3) |

**Lectura:** la brecha está concentrada en evidencia y en controles de identidad y
recuperación. Detectar es la función más avanzada porque es la única con una cadena
verificada de punta a punta (CU-01).

## 5. Plan de tratamiento (resumen)

El detalle (control, recurso, prioridad) está en `03-analisis-riesgos.md` §5; acá solo
el orden de ejecución.

| ID | Riesgo/Control | Acción | Prioridad | Responsable | Fecha límite |
|---|---|---|---|---|---|
| T03 | R03 / A.5.26 | Verificar CU-02 con evidencia (`docs/evidencias/README.md`) | 1 | Analista SOC | 08/10/2026 |
| T01 | R01 / A.8.5, A.5.16 | MFA en Keycloak y en el dashboard de Wazuh | 1 | Admin IAM | 14/10/2026 |
| T02 | R02 / A.5.17 | Cambiar credenciales de laboratorio | 1 | Admin de infraestructura | 14/10/2026 |
| T11 | R11 / A.8.32 | Revisión de un segundo integrante antes de integrar a `main` | 1 | RSI | Vigente |
| — | A.5.1, A.5.4 | Aprobación de política y SoA; asignar RSI | 1 | Equipo | 14/10/2026 |
| T08 | R08 / A.5.33, A.8.13 | Retención 90 días + respaldo y prueba de restauración | 2 | Admin de infraestructura | 14/10/2026 |
| T07 | R07 / A.5.7 | Ruleset público en Suricata | 2 | Analista SOC | 14/10/2026 |
| T04 | R04 | CU-03: FIM en la app + playbook de aislamiento | 2 | Analista SOC | 14/10/2026 |
| T05 | R05 / A.8.12, A.8.23 | Restringir salida a Internet de Servidores; CU-05 | 2 | Admin de red | 14/10/2026 |
| T06 | R06 | Mirror de tráfico o Suricata en OPNsense | 2 | Admin de red | 14/10/2026 |
| — | A.8.8 | Gestión de vulnerabilidades (doc 10, RF-14) | 2 | Admin de infraestructura | 14/10/2026 |
| T09, T10, T12, T13 | R09, R10, R12, R13 | TLS en Keycloak, fijar imágenes, capacidad, gitleaks | 3 | Varios (ver 03) | Antes del Red Team (28/10) |

---

## Check de aceptación

- [x] Anexo A completo con aplicabilidad justificada (93 controles).
- [x] Brecha MCU 5.0 por función con objetivo de perfil.
- [x] Plan de tratamiento con fechas y responsables.
- [x] Vinculados los entregables `docs/*` como evidencia.
- [ ] Aprobación de la SoA por el RSI/Dirección — pendiente.
