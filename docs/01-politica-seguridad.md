# Política de Seguridad de la Información — FinSegura S.A.

> Plantilla base: `plantilla/isaca/01-politica-seguridad.md` (SI-POL-01). Escenario:
> `40-consigna-propia.md`.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | Gobernar | Aporta a la función **Gobernar** (GV-01, GV-02) del Marco de Ciberseguridad 5.0. |
| **MCU 5.0 (categorías)** | GV-01 a GV-06, PR-01 | Marco de gobierno y reglas de protección de la información. |
| **Perfil comunitario** | **Avanzado** | Perfil que FinSegura declara como objetivo (LETRA.md §0.1). |
| **COBIT 2019** | APO13, APO01, EDM03 | La política es el insumo controlador de APO13. |
| **ISO/IEC 27001:2022** | A.5.1, A.5.9, A.5.24 | Políticas de seguridad, inventario, planificación de incidentes. |
| **ISO/IEC 27002** | 5.1, 5.9, 6.2 | Guía de implementación de políticas. |
| **BCU — Guía de Seguridad de la Información** | Requisito 1 (política de seguridad) | Política formal aprobada por la Dirección. |
| **URCDP — Ley 18.331** | Art. 9 y 12 | Medidas de seguridad sobre los datos personales de clientes. |
| **Documento de cumplimiento** | `docs/01-politica-seguridad.md` | Este documento. |

## Control del documento

| Campo | Valor |
|---|---|
| Nombre del documento | Política de Seguridad de la Información |
| Código | SI-POL-01 |
| Versión | 0.1 (borrador) |
| Fecha de aprobación | **pendiente** |
| Aprobado por | Dirección de FinSegura (rol simulado) — **pendiente** |
| Autor | Blue Team (fmq203, Renzo Rampoldi) |
| Próxima revisión | 12 meses después de la aprobación, o ante un cambio significativo |

### Historial de versiones

| Versión | Fecha | Autor | Descripción de cambios |
|---|---|---|---|
| 0.1 | 07/10/2026 | fmq203 | Primera versión sobre la infraestructura desplegada. |

---

## 1. Objetivo

Establecer los principios, responsabilidades y reglas para proteger la confidencialidad,
integridad y disponibilidad de la información de **FinSegura S.A.** —en particular los
datos personales y financieros de sus clientes— y de la **infraestructura de red de
defensa** que la soporta.

## 2. Alcance

Aplica a:

- **Infraestructura de red:** router/firewall perimetral y los cuatro dominios de
  seguridad (VLAN 10 Servidores, 20 DMZ, 30 Usuarios, 90 Gestión), según
  `00-arquitectura.md`.
- **Servicios:** app de préstamos y su base de datos, correo, honeypot, NIDS (Suricata),
  SIEM/HIDS/SOAR (Wazuh) e identidad (Keycloak). Inventario completo:
  `excel/02-registro-activos-mcu5.xlsx` (A01-A22).
- **Personas:** todo el personal con acceso a sistemas (Desarrollo/IT, Atención al
  cliente, Administración) y los administradores de las consolas de seguridad.
- **Repositorio de infraestructura** (`TSI-2026-Infra`), que es la definición ejecutable
  de todo lo anterior.

Fuera de alcance: la app DVWA como software (representa a la app de préstamos y es
vulnerable a propósito para las simulaciones).

## 3. Marco normativo

- **MCU 5.0 (AGESIC), perfil Avanzado:** esta política es el control base de la función
  Gobernar; el resto de las funciones se implementa en las políticas específicas (§5) y
  se mide en `excel/01-controles-mcu5-perfil-avanzado.xlsx`.
- **BCU — Guía de Seguridad de la Información:** FinSegura opera en el escenario como
  entidad supervisada; aplican política aprobada, monitoreo de eventos, gestión y
  notificación de incidentes, respaldos y doble factor en operaciones críticas.
- **ISO/IEC 27001:2022 y COBIT 2019:** referencia de controles y procesos.
- **Ley 18.331 (URCDP):** la base de clientes (A04) contiene datos personales; aplican
  medidas de seguridad (Art. 9-12) y notificación de violaciones (Art. 20).

## 4. Principios de seguridad

| Principio | Cómo se aplica en FinSegura |
|---|---|
| Confidencialidad | Los datos de clientes y las credenciales administrativas se clasifican como **Secreto** y solo se acceden desde su dominio de red y con identidad verificada. |
| Integridad | Cambios en archivos de servidores críticos monitoreados (FIM); la configuración de la infraestructura solo cambia vía el repositorio, con historial. |
| Disponibilidad | Toda la infraestructura se reconstruye desde el repositorio (`make up` / `vagrant up`); respaldos con restauración probada (`06-plan-continuidad`). |
| Mínimo privilegio | Cada dominio de red solo tiene los flujos imprescindibles (política por defecto: denegar). Los usuarios solo acceden a la app de préstamos (HTTP/HTTPS). |
| Defensa en profundidad | Capas: firewall perimetral → segmentación → NIDS → HIDS/FIM → SIEM con respuesta automática → MFA en consolas. |
| Zero Trust (Gestión) | La VLAN de Gestión no acepta tráfico de otros dominios salvo los agentes Wazuh (1514/1515); el acceso administrativo exige MFA. |

## 5. Estructura de la política

Política (este documento) → políticas específicas → procedimientos y configuración en el
repositorio.

| Política específica | Contenido mínimo | Referencia |
|---|---|---|
| Control de accesos | Identidad en Keycloak, MFA (TOTP/WebAuthn), revisión de accesos, hash Argon2 | `09-gestion-accesos.md` |
| Monitoreo y logs | Fuentes, casos de uso, retención ≥ 90 días, revisión diaria | `07-monitoreo-logs.md` |
| Gestión de incidentes | Severidades S0-S3, respuesta, escalamiento, notificación | `04-gestion-incidentes.md` |
| Gestión de vulnerabilidades | Escaneo periódico, remediación con plazos | `10-gestion-vulnerabilidades` (pendiente) |
| Copias de seguridad y continuidad | Retención, prueba de restauración, RTO/RPO | `06-plan-continuidad` (pendiente) |
| Gestión de cambios de infraestructura | Todo cambio pasa por el repositorio, con revisión de un segundo integrante antes de integrarlo | `brain/decisions.md`, RACI |
| Terceros y cadena de suministro | Imágenes Docker públicas con versión fijada (no `:latest`), GitHub como repositorio, boxes de Vagrant oficiales | `03-analisis-riesgos.md` R10 |

**Reglas que aplican a todos:**

1. Prohibido commitear secretos al repositorio (es público): `.env`, certificados y
   backups del router van en `.gitignore`.
2. Las contraseñas por defecto de laboratorio (`.env.example`) se cambian antes de poner
   un entorno en uso.
3. Todo contenedor nuevo lleva IP fija dentro de su dominio de red.
4. Toda decisión de arquitectura se registra con fecha y motivo en `brain/decisions.md`.

## 6. Roles y responsabilidades

Detalle por proceso en `excel/03-matriz-raci-mcu5.xlsx`.

| Rol | Responsabilidades |
|---|---|
| RSI | Accountable de todos los procesos de seguridad; mantiene esta política; acepta el riesgo residual; cierra incidentes. |
| Administrador de red | Router/firewall, VLANs y reglas entre dominios. |
| Administrador de infraestructura | docker-host, stacks, repositorio, respaldos y despliegue. |
| Administrador IAM | Keycloak: usuarios administradores y MFA. |
| Analista SOC | Opera Wazuh/Suricata/Cowrie, triage de alertas, ejecuta y ajusta playbooks. |
| Usuarios | Usan la app de préstamos y el correo; reportan incidentes a `soc@lab.local`. |
| Blue Team | Diseña, implementa y opera los controles; mantiene la bitácora diaria. |
| Red Team | Evalúa los controles atacándolos dentro de las reglas de compromiso (LETRA.md §7.1); no modifica esta política. |

## 7. Concientización y cumplimiento

- **Capacitación:** anual para todo el personal y al ingreso. En el laboratorio se
  declara **N.A. justificado** (empresa ficticia sin personal real; ver Excel 01).
- **Incumplimiento:** se registra como incidente (S2 o superior según impacto) y se
  trata según `04-gestion-incidentes.md`.
- **Canal de reporte:** `soc@lab.local`.

## 8. Vigencia y revisión

- Entra en vigencia en la fecha de aprobación por la Dirección (pendiente).
- Se revisa como mínimo una vez al año, después de cada ejercicio de Red Team y ante
  cambios significativos de la infraestructura.

---

## Check de aceptación

- [ ] Aprobada formalmente con fecha y firmas — **pendiente**.
- [x] Menciona MCU 5.0, BCU, ISO y Ley 18.331.
- [x] Define roles y responsabilidades.
- [x] Referencia el resto de las políticas de `docs/`.
