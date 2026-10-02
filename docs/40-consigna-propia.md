# Consigna propia — Tarea 3 (Blue Team)

> **Estado: BORRADOR** — pendiente de revisión por el equipo y aprobación del docente
> (RF-01). Ajustar nombre de la empresa y cualquier detalle que no cierre antes de
> presentarlo. Una vez aprobada, no se vuelve a reescribir: los cambios posteriores se
> documentan en `../brain/decisions.md`.

| Campo | Valor |
|---|---|
| Código | CP-T3-01 |
| Versión | 0.1 (borrador) |
| Equipo | Blue Team — `[nombres]` |
| Fecha | `[DD/MM/2026]` |
| Aprobación | `[Docente]` — pendiente |

---

## 1. Escenario empresarial

**Empresa:** FinSegura S.A. (nombre ficticio, ajustar si quieren otro).

**Sector:** financiero — fintech de préstamos y pagos online, supervisada en el
escenario por normativa tipo BCU (esto justifica mapear controles contra **BCU-GSI**
además de MCU 5.0, ver LETRA.md §1.5).

**Tamaño:** empresa pequeña, ~40 empleados. 3 áreas con acceso a sistemas: Desarrollo/IT
(8), Atención al cliente/cobranzas (15, usan telefonía), Administración/Operaciones (17).

**Procesos críticos del negocio:**
- Otorgamiento y gestión de préstamos online (app web + base de datos).
- Atención y cobranza telefónica a clientes (requiere canal de voz).
- Comunicación corporativa (correo).

**Datos críticos a proteger:**
- Datos personales y financieros de clientes (cédula, ingresos, historial de pagos) —
  en la base de datos de la app de préstamos.
- Credenciales administrativas de las consolas de seguridad (SIEM, identidad, FW).
- Comunicaciones de cobranza (contienen datos personales, se cursan por Wazo).

**Por qué este escenario encaja con la infraestructura ya definida:**

| Necesidad del negocio | Stack que la cubre |
|---|---|
| App de préstamos (web + DB) expuesta a clientes | `infra/targets/` |
| Correo corporativo | `infra/mail/` |
| Atención/cobranza telefónica | `infra/wazo/` |
| Acceso administrativo a consolas (MFA obligatorio) | `infra/identity/` (Keycloak) |
| Detectar reconocimiento antes de que llegue a producción | `infra/honeypot/` (Cowrie, simula panel admin legacy expuesto) |
| Visibilidad de todo lo anterior | `infra/siem-hids/` (Wazuh) + `infra/nids/` (Suricata) |

## 2. Red diseñada (resumen — detalle técnico en `00-arquitectura.md`)

4 dominios de seguridad, ya reflejados en `infra/docker-compose.networks.yml` y en la red
real ya armada en Proxmox (`opnrouter` + `lab-srv-datos`/`lab-web-dmz`, ver
`00-arquitectura.md` §1.1):

| Dominio | VLAN | Subred | Qué vive ahí |
|---|---|---|---|
| Servidores | 10 | 10.10.10.0/24 | App de préstamos + base de datos (`targets/`) |
| DMZ | 20 | 10.10.20.0/24 | Wazo, mail, honeypot, NIDS (Suricata) |
| Usuarios | 30 | 10.10.30.0/24 | Puestos de Atención al cliente/Administración |
| Gestión | 90 | 10.10.90.0/24 | Wazuh, Keycloak |

Flujos permitidos (resumen, detallar en el diagrama físico):
- Internet → DMZ: solo puertos de los servicios publicados (SMTP/submission, SIP/RTP de
  Wazo, el puerto trampa del honeypot).
- DMZ → Servidores: nada directo salvo lo estrictamente necesario (ninguno por defecto).
- Usuarios → Servidores: solo HTTPS a la app de préstamos.
- Cualquier VLAN → Gestión: bloqueado salvo admins autenticados con MFA (RF-12), y
  agentes Wazuh (1514/1515) desde Servidores/Usuarios hacia el manager.
- El NIDS (Suricata) corre en la DMZ y hoy ve tráfico local de ese segmento vía macvlan,
  no un espejo (SPAN) explícito del router — pendiente de resolver, ver
  `../brain/decisions.md`.

## 3. Casos de uso de seguridad (mínimo 5 — RF-01)

Los 3 primeros son los obligatorios por RF-17 (simulación documentada de ataques). Se
suman 2 más para cubrir el RF-01 (mínimo 5) sin agregar infraestructura nueva.

| # | Caso de uso | Activo objetivo | Detección esperada | Respuesta esperada |
|---|---|---|---|---|
| CU-01 | Reconocimiento/escaneo de puertos contra la DMZ | Toda la DMZ | Suricata (firma de scan, ej. Nmap) | Alerta SIEM; sin bloqueo automático (es detección) |
| CU-02 | Fuerza bruta SSH contra un puesto de usuario comprometible (VLAN Usuarios) | `targets/` (host SSH cliente, simula un puesto de Atención/Admin) | Wazuh (regla de intentos fallidos repetidos) | Wazuh Active Response bloquea la IP de origen (playbook 1) |
| CU-03 | Webshell / inyección en la app de préstamos | `targets/` (app web) | Wazuh FIM (archivo nuevo/modificado en webroot) | Playbook 2: aislar el contenedor/host afectado |
| CU-04 | Uso de credenciales robadas contra la consola de Keycloak o Wazuh | `identity/`, `siem-hids/` | MFA obligatorio bloquea el acceso igual; intento queda en logs de Keycloak | Alerta + notificación (RF-07); revisar necesidad de playbook 3 acá o en CU-05 |
| CU-05 | Exfiltración de datos simulada por DNS | Base de datos de `targets/` | Suricata/Wazuh correlacionan volumen/patrón anómalo de consultas DNS | Alerta SIEM + notificación por 2º canal |

> Nota: RF-06 pide **3 playbooks** de Active Response. CU-02 y CU-03 ya dan 2
> (bloqueo de IP, aislamiento de host). El 3ro se puede resolver en CU-04 o CU-05
> (ej. forzar reset de contraseña / deshabilitar cuenta ante uso de credenciales
> robadas) — a definir cuando se implemente Wazuh.

## 4. Siguiente paso

1. Revisar este borrador en equipo, ajustar lo que no cierre (nombre de empresa,
   subredes, qué playbook va en qué caso de uso).
2. Completar `00-arquitectura.md` (vista física con IPs reales) en base a este
   documento.
3. Presentar ambos al docente para aprobación (RF-01) — no bloqueante para seguir
   armando infra en paralelo, dado el atraso (ver `../brain/notes/plan-recuperacion-atraso.md`).
