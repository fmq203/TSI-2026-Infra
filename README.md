# Tarea 3 — Infraestructura de Red de Defensa Completa

Repo del Blue Team: infraestructura de red de defensa (router/firewall + Wazuh, Suricata,
Keycloak, mail, honeypot y blancos vulnerables en Docker) y su documentación formal.
Este README es la **puerta de entrada**: qué hay, cómo levantarlo desde cero, en qué
estado está y qué falta.

## Estado del proyecto — 07/10/2026

**Escenario:** FinSegura S.A., fintech de préstamos online
([consigna propia](docs/40-consigna-propia.md)). **Arquitectura:** router/firewall +
4 VLANs (Servidores, DMZ, Usuarios, Gestión) y todos los servicios en Docker sobre un
`docker-host` ([arquitectura](docs/00-arquitectura.md)). Se despliega desde cero con
`vagrant up` ([vagrant/](vagrant/README.md)) o `make up` ([infra/](infra/README.md)).

### Infraestructura

| Componente | Herramienta | Estado |
|---|---|---|
| Router / firewall + segmentación | OPNsense (referencia) · nftables (`vagrant/`) | ✅ Funcionando |
| NIDS | Suricata, 5 firmas propias | ✅ Funcionando |
| SIEM + HIDS | Wazuh 4.9.0 (manager, indexer, dashboard) + agente en el puesto de usuario | ✅ Funcionando (agente `ssh-client` conectado 07/10, con FIM y SCA) |
| SOAR | Wazuh Active Response (`firewall-drop`) | 🔶 Construido, sin verificar |
| Honeypot | Cowrie → Wazuh | 🔶 Construido, sin verificar |
| Alertas por correo | docker-mailserver → `soc@lab.local` | 🔶 Configurado, sin evidencia |
| Identidad / MFA | Keycloak 26 | 🔶 Corre; MFA sin configurar |
| Activos a proteger | App de préstamos (DVWA) + MySQL + puesto de usuario | ✅ Funcionando |

### Casos de uso (detección → respuesta → notificación)

| Caso | Estado |
|---|---|
| CU-01 Reconocimiento / escaneo | ✅ Detectado de punta a punta (05/10): Suricata → Wazuh → dashboard. [INC-2026-001](docs/04-gestion-incidentes.md) |
| CU-02 Fuerza bruta SSH → bloqueo automático → mail | 🔶 Desplegado en el entorno de referencia el 07/10 (agente conectado, reglas del router creadas); **falta correr el ataque** |
| CU-03 Webshell (FIM + aislamiento) | ❌ Pendiente |
| CU-04 Credenciales robadas · CU-05 Exfiltración por DNS | ❌ Pendientes |

### Documentación (borradores, pendientes de revisión y aprobación)

| Documento | Contenido |
|---|---|
| [01 Política](docs/01-politica-seguridad.md) | Principios, alcance, roles, políticas específicas |
| [03 Riesgos](docs/03-analisis-riesgos.md) | 13 riesgos sacados de brechas reales del repo, matriz 5×5, plan de tratamiento |
| [04 Incidentes](docs/04-gestion-incidentes.md) | Severidades, procedimiento, playbooks por caso de uso, registro INC-2026-001..004 |
| [06 Continuidad](docs/06-plan-continuidad.md) | RTO/RPO, inventario de respaldo, prueba de restauración |
| [07 Monitoreo](docs/07-monitoreo-logs.md) | Fuentes de log, reglas, retención |
| [09 Accesos](docs/09-gestion-accesos.md) | MFA (TOTP/WebAuthn), Argon2, política por consola |
| [11 SoA](docs/11-soa-plan-tratamiento.md) | Anexo A ISO 27001:2022 completo (93 controles) y brecha MCU 5.0 por función |
| [12 Notificación](docs/12-notificacion-incidentes.md) | Criterios BCU/URCDP y ejercicio de escritorio |
| [99 Bitácora](docs/99-bitacora-trabajo.md) | Desde el 01/10 (ver aclaración abajo) |
| [Excel MCU 5.0](docs/excel/) | 01 controles (47: 5 implementados, 26 parciales, 15 pendientes, 1 N.A.), 02 activos (A01-A22), 03 RACI, 04 bitácora |

### Lo que falta (hacia la auditoría del 14/10)

1. **Evidencia** en [`docs/evidencias/`](docs/evidencias/README.md): el procedimiento de
   captura está escrito; faltan las capturas de CU-01 y CU-02.
2. **Verificar CU-02** de punta a punta (es la demostración obligatoria de detección →
   respuesta → notificación).
3. **MFA** en Keycloak y en el dashboard de Wazuh.
4. CU-03, retención de logs de 90 días, respaldos con prueba de restauración.
5. Documentos `10` (vulnerabilidades) y `28` (informe Blue Team).

### Aclaraciones

- **Atraso y bitácora:** H1 y H2 vencieron sin entregables. La bitácora arranca el 01/10;
  las entradas del 01 al 06/10 se cargaron después a partir de los commits y lo dice
  explícitamente; los días sin registro **no se reconstruyeron**.
- **Recortes con justificación** (habilitados en clase el 05/10): Wazo, segundo canal de
  alertas y TheHive/Cortex; la respuesta automática la hace Wazuh Active Response. Detalle
  en [`brain/decisions.md`](brain/decisions.md).
- El estado de cada control y documento está tomado del repo: lo que no se verificó
  figura como "sin verificar".

## Empezar desde cero

**Si no tenés nada armado: ir a [`vagrant/README.md`](vagrant/README.md).** Con
VirtualBox + Vagrant en tu máquina, `vagrant up` levanta el router y todos los stacks
automáticamente (15-30 min, necesita 16 GB de RAM). Ahí está también cómo entrar a las
consolas, cómo sumar una VM atacante y cómo usar OPNsense como router.

Cada integrante levanta su propio entorno; no hace falta acceso a la máquina de nadie.

## Contenido

```
TSI-2026-Infra/
├── CLAUDE.md        ← orientación para asistentes de IA (corto)
├── README.md        ← este archivo
├── LETRA.md          ← consigna oficial de la tarea (no se edita)
├── vagrant/          ← despliegue desde cero en VirtualBox (empezar acá)
├── infra/            ← los stacks Docker (lo que corre adentro de docker-host)
├── docs/             ← entregables formales (plantillas ISACA + MCU completadas)
└── brain/            ← el "por qué": estado actual, decisiones, errores ya pisados
    ├── MEMORY.md       ← foto del estado actual (red, IPs, contenedores, pendientes)
    ├── decisions.md    ← historial de decisiones con fecha y motivo
    ├── LEARNINGS.md    ← errores ya vistos y su causa
    └── notes/          ← plan de recuperación del atraso, etc.
```

Pensado para leerse con o sin asistente de IA: el `CLAUDE.md` de la raíz orienta a
Claude Code solo; con otra IA, pasarle primero `CLAUDE.md`, este README y
`brain/MEMORY.md`.

## Pendientes

### Infra (para la demo de la auditoría)

1. **Logs → Wazuh.** Suricata conectado y **CU-01 verificado de punta a punta**
   (2026-10-05: ping y escaneo SYN desde la VLAN Servidores → alertas 1000005/1000001
   en Suricata → regla 86601 en Wazuh → visibles en el dashboard). Cowrie sumado
   2026-10-06 (regla 100110) — **falta verificar que se vea en el dashboard**.
2. **Verificar CU-02** (agente Wazuh embebido en `target-ssh-client` — restaurado
   2026-10-06, ver `infra/targets/docker-compose.yml`): fuerza bruta SSH → Active
   Response `firewall-drop` → mail a `soc@lab.local`. Cómo probarlo: `vagrant/README.md`
   → "Probar la respuesta automática". En OPNsense hacen falta las reglas Usuarios →
   Gestión 1514/1515 y Gestión → DMZ 25. Después: agente en `webapp` para CU-03 (FIM).
3. **MFA en Keycloak** (TOTP/WebAuthn, RF-12): el contenedor corre, falta configurar
   realm, usuarios y MFA.
4. **Active Response** para CU-03 (webshell): el de CU-02 ya está.
5. Decidir cómo le llega tráfico espejado a Suricata (hoy ve solo el tráfico de la DMZ).
6. `wazo` y `alerting`: candidatos a recorte con justificación (ver `brain/decisions.md`).

Detalle técnico de cada uno en `infra/README.md` → "Qué falta".

### Documentación

Toda la matriz ISACA salvo los dos borradores, Excel MCU 5.0, bitácora diaria y los 3
ataques simulados documentados con evidencia (CU-01 recon, CU-02 fuerza bruta SSH,
CU-03 webshell). Ver `docs/README.md` y el plan de recuperación.

### Seguridad (antes de la auditoría del 14/10)

1. Cambiar las contraseñas de laboratorio de los `.env` (Keycloak, MySQL, Wazuh API). La
   del host SSH víctima es débil **a propósito** (CU-02): dejarla, pero documentarlo.
2. El indexer de Wazuh corre **sin plugin de seguridad** (simplificación de
   laboratorio): justificarlo como N/A en el Excel MCU o activarlo.

## Direcciones de los servicios

Iguales en cualquier despliegue (son parte del diseño, `docs/00-arquitectura.md`).
Cómo llegar a ellas desde tu máquina: `vagrant/README.md` → "Cómo entrar a las consolas".

| Servicio | Dirección | Credenciales por defecto (`.env.example`) |
|---|---|---|
| Router (gateway de cada VLAN) | `10.10.X.254` | OPNsense: las que elijas al instalar |
| Wazuh dashboard | `http://10.10.90.12:5601` | sin login (plugin de seguridad desactivado, ver `infra/siem-hids/docker-compose.yml`). API: `wazuh-wui` / `WAZUH_API_PASSWORD` |
| Keycloak | `http://10.10.90.20:8080` | `admin` / `changeme` |
| App de préstamos (DVWA) | `http://10.10.10.10` | `admin` / `password` |
| Host SSH víctima | `ssh -p 2222 labuser@10.10.30.10` | `labuser` / `changeme_intentionally_weak` |
| Honeypot Cowrie | `10.10.20.30` puertos 2222 / 2223 | cualquiera (es una trampa) |
| Mail | `10.10.20.20` (25, 587, 993) | casilla del SOC `soc@lab.local` (la crea `make up`, contraseña en `infra/mail/.env`): recibe las alertas de Wazuh nivel ≥ 10 |

## Reglas del repo

- **Es público: nada de secretos.** `.gitignore` ya excluye `.env`, certs de mail y
  backups `config.xml` de OPNsense. Los `.env` reales viven solo dentro de cada
  `docker-host`.
- Las **plantillas** ISACA, Excel MCU 5.0, arquitectura 4+1/C4 e informe Red Team son
  material del curso y **no están en este repo** (`LETRA.md` las nombra con rutas
  `plantilla/...` que acá no existen).

## Cómo empezar (según la letra)

1. Lea `LETRA.md` completo.
2. En la **Semana 1** el equipo genera su **consigna propia** (escenario empresarial ficticio + diagrama de red + casos de uso). Se aprueba con el docente antes de avanzar.
3. Revise la matriz de documentación (sección 8) para saber qué plantilla llenar en cada semana.
4. Copie las plantillas ISACA indicadas (material del curso) a la carpeta `docs/`.
5. Trabaje en su repositorio GIT y congele la entrega con `git tag v1.0` en el hito H4.

## Documentación que debe entregar (resumen)

| Fecha | Documento |
|---|---|
| Semana 1 (14-18/09) | Consigna propia + diagrama de red (vistas física/C4) + política, inventario |
| Semana 2 (21-25/09) | Análisis de riesgos, Excel controles MCU (Avanzado) |
| Semana 3-4 (28/09-02/10) | Gestión de accesos, monitoreo/logs/SIEM, bitácora |
| Semana 5 (05-07/10) | Vulnerabilidades, continuidad, incidentes, SoA + brecha MCU, notificaciones |
| **Miércoles 07/10/2026** | **Pre-entrega congelada** (`git tag v1.0`) + Excel/bitácora completos |
| **Miércoles 14/10/2026** | **Auditoría formal por función MCU 5.0 (defensa)** + demo de detección→respuesta |
| **Miércoles 28/10/2026** | **Pre-entrega Red Team** (informe preliminar ≥ 70%) |
| **Lunes 09/11/2026** | **Entrega final Red Team** (informe `plantilla/informe-red-team.md` + presentación) |

- **Equipo A (Blue Team):** construye la infraestructura de defensa y rinde la auditoría (semana del 14/09 al 14/10).
- **Equipo B (Red Team):** ataca la infraestructura entregada (28/10 → 09/11) y emite informe.
