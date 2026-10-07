# Análisis y Tratamiento de Riesgos — Infraestructura de FinSegura S.A.

> Plantilla base: `plantilla/isaca/03-analisis-riesgos.md` (SI-RSK-03). Activos:
> `excel/02-registro-activos-mcu5.xlsx` (A01-A22).

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Identificar** + **Responder** | Identificación y evaluación de riesgos (ID-02, ID-03); respuesta al riesgo. |
| **MCU 5.0 (categorías)** | ID-02, ID-03, RS-01 | Evaluación de riesgos internos/externos. |
| **COBIT 2019** | APO12, EDM03 | Gestión del riesgo. |
| **ISO/IEC 27001:2022** | Cláusula 6.1; A.5.1, A.5.8, A.5.28 | Acciones frente a riesgos. |
| **ISO 31000** | Todas | Marco de gestión del riesgo. |
| **BCU — GSI** | Requisito de gestión de riesgo | Evaluación periódica y documentada. |
| **URCDP — Ley 18.331** | Art. 9 | Riesgo del tratamiento de datos personales. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-RSK-03 |
| Versión | 0.1 (borrador) |
| Metodología | ISO 31000 + COBIT APO12 + MCU 5.0 |
| Fecha | 07/10/2026 |

### Historial de versiones

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 0.1 | 07/10/2026 | fmq203 | Primera evaluación sobre la infraestructura desplegada (13 riesgos). |

---

## 1. Contexto

- **Organización:** FinSegura S.A., fintech de préstamos online, ~40 empleados
  (`40-consigna-propia.md`).
- **Solución analizada:** infraestructura de red de defensa — router, 4 VLANs, Wazuh,
  Suricata, Cowrie, Keycloak, correo y los activos de negocio (app de préstamos, base de
  clientes, puestos de usuario).
- **Criterios de aceptación:** **Bajo** se acepta; **Medio** se acepta solo con
  justificación escrita del RSI; **Alto** y **Crítico** exigen tratamiento antes de la
  auditoría (14/10/2026) o una aceptación explícita y fundada.
- **Horizonte temporal:** hasta el fin del ejercicio de Red Team (09/11/2026).

**Cómo se identificaron:** cada riesgo sale de una brecha concreta observada en el
código o en la configuración del repo al 07/10 (columna "Evidencia" de §2), y de los
controles marcados como Parcial/Pendiente en `excel/01-controles-mcu5-perfil-avanzado.xlsx`.
La probabilidad y el impacto son valoración del equipo, a revisar entre los dos.

## 2. Identificación de activos y amenazas

| ID | Activo | Amenaza | Origen | Vulnerabilidad asociada (evidencia) |
|---|---|---|---|---|
| R01 | A06-A08 Wazuh, A12 Keycloak | Acceso no autorizado a consolas de seguridad | Externo / interno, deliberado | Dashboard de Wazuh sin login; MFA de Keycloak sin configurar (`infra/siem-hids/docker-compose.yml`) |
| R02 | A14, A17 credenciales | Uso de credenciales por defecto | Externo / interno, deliberado | Contraseñas `changeme` en `.env.example` que se copian tal cual a `.env` con `make up` |
| R03 | A05 puesto de usuario | Fuerza bruta SSH | Interno, deliberado | Contraseña débil (a propósito para CU-02); respuesta automática sin verificar |
| R04 | A03 app, A04 base de clientes | Webshell / inyección en la app | Externo, deliberado | App vulnerable (DVWA); sin FIM ni agente en `target-webapp` |
| R05 | A04 base de clientes | Exfiltración de datos de clientes (DNS u otro canal) | Externo / interno, deliberado | El router deja salir a Internet desde **todas** las VLAN, incluida Servidores (`vagrant/provision-router.sh:52`); sin detección de CU-05 |
| R06 | A09 Suricata, A20 DMZ | Reconocimiento no detectado | Externo, deliberado | Suricata solo ve el tráfico dirigido a su IP (sin mirror/SPAN) |
| R07 | A09 Suricata | Ataques conocidos sin firma | Externo, deliberado | Solo 5 reglas propias; ningún ruleset público cargado (`infra/nids/suricata.yaml`) |
| R08 | A07 indexer | Pérdida de evidencia de incidentes | Accidental / deliberado | Sin política de retención (RF-15) ni respaldo del indexer |
| R09 | A12, A07 | Captura de credenciales en tránsito dentro de Gestión | Interno, deliberado | Keycloak por HTTP; indexer sin TLS interno (plugin de seguridad desactivado) |
| R10 | A02 docker-host y servicios | Imagen de tercero comprometida o cambio no controlado | Externo, deliberado / accidental | 4 imágenes en `:latest` (suricata, docker-mailserver, cowrie, DVWA) |
| R11 | A16 repositorio, todos | Cambio en la infra que desactiva un control sin que se note | Interno, accidental | Integración sin revisión previa (caso `ecf697c`, 06/10: rompió CU-02) |
| R12 | A06-A08 SIEM | Indisponibilidad del SIEM por falta de recursos | Accidental | Host compartido con RAM ajustada; Wazuh es el stack más pesado (~3-4 GB) |
| R13 | A16 repositorio, A17 | Publicación de secretos en el repo público | Interno, accidental | Depende solo de `.gitignore`; sin escaneo automático (gitleaks) |

## 3. Análisis de riesgo (cualitativo)

Escalas de probabilidad (1 Muy baja … 5 Muy alta) e impacto (1 Insignificante … 5
Catastrófico) y matriz 5×5 según la plantilla:

| I \ P | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 5 | M | M | A | A | C |
| 4 | M | M | A | A | A |
| 3 | B | M | M | A | A |
| 2 | B | B | M | M | A |
| 1 | B | B | B | M | M |

## 4. Registro de riesgos y evaluación

| ID | Riesgo | Activos | Prob. | Impacto | Nivel | Resultado (P×I) | Tratamiento | Responsable | Plan | Estado | Fecha |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R01 | Acceso no autorizado a consolas de seguridad | A06-A08, A12 | 4 | 5 | **A** | 20 | M | Admin IAM | T01 | Abierto | 07/10/2026 |
| R02 | Credenciales por defecto en servicios | A14, A17 | 4 | 5 | **A** | 20 | M | Admin de infraestructura | T02 | Abierto | 07/10/2026 |
| R03 | Fuerza bruta SSH contra puestos de usuario | A05 | 5 | 3 | **A** | 15 | M | Analista SOC | T03 | En tratamiento | 07/10/2026 |
| R04 | Webshell / inyección en la app de préstamos | A03, A04 | 3 | 5 | **A** | 15 | M | Analista SOC | T04 | Abierto | 07/10/2026 |
| R05 | Exfiltración de datos de clientes | A04 | 3 | 5 | **A** | 15 | M | Admin de red | T05 | Abierto | 07/10/2026 |
| R06 | Reconocimiento no detectado (sin mirror) | A09, A20 | 4 | 3 | **A** | 12 | M | Admin de red | T06 | Abierto | 07/10/2026 |
| R07 | Ataques conocidos sin firma | A09 | 4 | 3 | **A** | 12 | M | Analista SOC | T07 | Abierto | 07/10/2026 |
| R08 | Pérdida de evidencia de incidentes | A07 | 3 | 4 | **A** | 12 | M | Admin de infraestructura | T08 | Abierto | 07/10/2026 |
| R11 | Cambio en la infra desactiva un control | A16, todos | 3 | 4 | **A** | 12 | M | RSI | T11 | En tratamiento | 07/10/2026 |
| R13 | Secretos publicados en el repo | A16, A17 | 2 | 5 | M | 10 | M | Admin de infraestructura | T13 | Abierto | 07/10/2026 |
| R12 | Indisponibilidad del SIEM por recursos | A06-A08 | 3 | 3 | M | 9 | M | Admin de infraestructura | T12 | Abierto | 07/10/2026 |
| R09 | Credenciales en tránsito dentro de Gestión | A07, A12 | 2 | 4 | M | 8 | M (Keycloak) / R (indexer) | Admin IAM | T09 | Abierto | 07/10/2026 |
| R10 | Imagen de tercero comprometida | A02 | 2 | 4 | M | 8 | M | Admin de infraestructura | T10 | Abierto | 07/10/2026 |

M = Mitigar; T = Transferir; R = Retener (aceptar); A = Evitar. Ordenado por nivel y
resultado.

## 5. Plan de tratamiento de riesgos

| ID Riesgo | Acción de tratamiento | Control/medida | Prioridad | Fecha objetivo |
|---|---|---|---|---|
| T01 → R01 | Realm de FinSegura con MFA obligatorio (TOTP + WebAuthn); login en el dashboard de Wazuh delegado en Keycloak (proxy de autenticación u OIDC) | `09-gestion-accesos.md`; RF-12 | 1 | 14/10/2026 |
| T02 → R02 | Cambiar todas las contraseñas de laboratorio y documentar que `.env.example` no es para uso real | README → "Seguridad" | 1 | 14/10/2026 |
| T03 → R03 | Verificar Active Response `firewall-drop` (CU-02) de punta a punta con evidencia | `04-gestion-incidentes.md` INC-2026-002 | 1 | 08/10/2026 |
| T04 → R04 | Agente Wazuh con FIM sobre el webroot de la app + playbook de aislamiento (CU-03) | RF-06, RF-17 | 2 | 14/10/2026 |
| T05 → R05 | Restringir la salida a Internet de la VLAN Servidores (solo lo necesario, DNS por resolver interno) + regla de detección de CU-05 | Reglas del router; Suricata | 2 | 14/10/2026 |
| T06 → R06 | Decidir mirror de tráfico (bridge del hipervisor) o Suricata en OPNsense (`os-suricata`) | `infra/README.md` "Qué falta" §7 | 2 | 14/10/2026 |
| T07 → R07 | Cargar ruleset público (Emerging Threats Open vía `suricata-update`) además de las reglas propias | RF-03 | 2 | 14/10/2026 |
| T08 → R08 | Política de retención de 90 días en el indexer + respaldo (snapshot) con prueba de restauración | RF-15, RF-13; `06-plan-continuidad` | 2 | 14/10/2026 |
| T11 → R11 | Revisión obligatoria de un segundo integrante antes de integrar cambios a `main` | Proceso de cambios en la RACI; `01-politica-seguridad.md` §5 | 1 | Vigente desde 07/10/2026 |
| T12 → R12 | Límites de memoria por stack y alerta de salud del SIEM | `infra/` | 3 | Antes del Red Team (28/10) |
| T09 → R09 | Keycloak con TLS. Indexer: aceptar el riesgo (servicio interno de la VLAN Gestión, sin acceso desde otros dominios) o activar el plugin de seguridad | `09-gestion-accesos.md` | 3 | 14/10/2026 |
| T10 → R10 | Fijar versión (o digest) de las 4 imágenes en `:latest` | `infra/*/docker-compose.yml` | 3 | 14/10/2026 |
| T13 → R13 | Correr gitleaks sobre el historial y antes de cada push | Excel 01 (SAST) | 3 | 14/10/2026 |

## 6. Riesgo residual y aceptación

Se completa después de aplicar los tratamientos. Riesgos que ya se sabe que van a quedar
con residual explícito:

| ID | Riesgo residual (post-tratamiento) | Aceptado por | Firma | Fecha |
|---|---|---|---|---|
| R03 | La contraseña del puesto A05 sigue siendo débil **a propósito** (es el blanco de CU-02); el control es la respuesta automática, no la contraseña | RSI | ☐ | |
| R09 | Indexer sin TLS interno, si se elige retener | RSI | ☐ | |

---

## Check de aceptación

- [x] Activos críticos con amenazas identificadas.
- [x] Riesgos evaluados con probabilidad/impacto y nivel.
- [x] Plan de tratamiento con responsables y fechas.
- [ ] Riesgo residual aceptado formalmente por el RSI — pendiente (el rol de RSI está
  sin asignar, ver `excel/03` hoja Roles).
