# Tarea 3 — Infraestructura de Red de Defensa Completa

Este README es la **puerta de entrada** de la tarea: para personas y también el punto
que resume el estado y el razonamiento acumulado (el "brain") para no tener que
re-derivarlo cada vez.

## Contenido

- **`LETRA.md`** — La letra completa de la tarea: marco teórico, glosario, requerimientos funcionales/no funcionales, arquitectura sugerida, Partes Blue Team y Red Team, matriz de documentación, hitos, KPIs y criterios de evaluación. Fuente original, no se edita.
- **`docs/`** — Carpeta de trabajo del equipo para la documentación de la solución (ver `docs/README.md` para el checklist de entregables).
- **`infra/`** — Despliegue Docker-first de la infraestructura de defensa (ver `infra/README.md` para arquitectura, stacks y cómo levantarla).
- **`vagrant/`** — Reproducción portable de la misma infra en VirtualBox (ver `vagrant/README.md`), para que el Red Team la ataque en su propia máquina sin depender del Proxmox compartido.
- **`brain/`** — Base de conocimiento específica de esta tarea: decisiones de arquitectura, hechos estables y lecciones aprendidas que no viven en la letra ni en las plantillas. Ver "Brain de la Tarea 3" abajo.

## Brain de la Tarea 3

Es un brain **propio de esta tarea**: guarda el *por qué* de las decisiones, los
errores ya pisados y el estado actual, para no re-derivarlo cada vez (ni que lo tenga
que re-derivar una IA). Está pensado para leerse con o sin asistente de IA — el
`CLAUDE.md` de la raíz orienta a Claude Code automáticamente; con otra IA, pasarle este
README y `brain/MEMORY.md` primero.

```
TSI-2026-Infra/
├── CLAUDE.md        ← orientación para asistentes de IA (corto)
├── README.md        ← este archivo: entrada humana + base del brain
├── LETRA.md          ← fuente original, intocable desde el brain
├── brain/
│   ├── CLAUDE.md      ← mapa y reglas completas del brain
│   ├── MEMORY.md       ← hechos estables: fechas, equipo, RF/RNF, arquitectura decidida
│   ├── decisions.md     ← log de decisiones de arquitectura/alcance, con fecha y motivo
│   ├── LEARNINGS.md     ← lecciones aprendidas (se completa con el avance)
│   └── notes/            ← notas puntuales por tema (se crea bajo demanda)
├── docs/                ← entregables formales (plantillas ISACA + MCU completadas)
├── infra/                ← despliegue Docker-first (ver infra/README.md)
└── vagrant/               ← reproducción portable en VirtualBox para el Red Team
```

**Protocolo de lectura sugerido:**
1. Este README — visión general y estado.
2. `brain/MEMORY.md` — hechos estables, para no releer toda la letra cada sesión.
3. `docs/README.md` e `infra/README.md` — estado real de avance (son la fuente de verdad, el brain no los duplica).
4. `brain/notes/<tema>.md` — si hace falta profundizar en un tema puntual.
5. `brain/CLAUDE.md` — reglas completas, solo si vas a escribir/actualizar el brain.

## Estado actual (resumen al 2026-10-02 — detalle y fuentes en `brain/MEMORY.md`)

- **infra/**: red de 4 VLANs completa (`opnrouter` + `docker-host`) y **6 de 9 stacks
  corriendo (11 contenedores)**: `identity` (Keycloak), `siem-hids` (Wazuh ×3), `nids`
  (Suricata), `mail`, `honeypot` (Cowrie), `targets` (DVWA + DB + SSH víctima). Sin
  construir: `wazo`, `alerting`.
- Pendiente de infra: agente Wazuh en `targets` (HIDS/FIM real), regla de firewall en
  OPNsense para que los agentes lleguen al manager, **llevar los logs de Suricata y
  Cowrie a Wazuh** (hoy el SIEM no los ve — sin esto no hay correlación ni demo de
  CU-01), MFA configurado dentro de Keycloak, playbooks de Active Response (RF-06), y
  resolver cómo llega tráfico real espejado a `nids`.
- **docs/**: `40-consigna-propia.md` y `00-arquitectura.md` tienen borrador actualizado
  contra la infra real — **falta revisarlos entre los dos y aprobación docente**. El
  resto de la matriz sigue en `☐` en `docs/README.md`. Bitácora sin empezar.
- **vagrant/**: copia portable para el Red Team, escrita pero **sin probar** en una
  máquina física (se intentó anidada en Proxmox y no funciona por limitación de
  hardware, ver `brain/LEARNINGS.md`).
- Los hitos H1 (21/09) y H2 (28/09) estaban vencidos al 01/10 — se sigue un plan de
  recuperación con el estado al día en `brain/notes/plan-recuperacion-atraso.md`.
  **La infra va adelantada, la documentación atrasada.**

## Para retomar (compañero / asistente de IA)

### Cómo llegar a las consolas

Las 4 VLANs (`10.10.x.0/24`) **no se ven desde la red de casa/laboratorio
(`192.168.0.0/24`)** — solo desde adentro. Dos formas verificadas o razonables:

1. **Desde la VM `kali` (ID 120)** — está conectada a la VLAN Servidores. Abrir su
   consola en Proxmox y usar el navegador/curl desde ahí. Llegar a las otras VLANs
   depende de las reglas de OPNsense (la LAN de OPNsense permite salir a todo por
   defecto, así que probablemente funciona — *no verificado*).
2. **Desde el host Proxmox, a través de `docker-host`** (verificado): `docker-host` está
   en las 4 VLANs, así que `pct exec 108 -- curl ...` desde la shell del nodo llega a
   cualquier servicio.

| Servicio | Dirección | Credenciales (hoy) |
|---|---|---|
| OPNsense (router) | `https://10.10.10.254` | las que configuró el equipo — pedirlas, no están en el repo |
| Wazuh dashboard | `http://10.10.90.12:5601` (HTTP, no HTTPS) | *sin verificar si pide login* (el indexer tiene el plugin de seguridad apagado). API Wazuh: `wazuh-wui` / `WAZUH_API_PASSWORD` de `infra/siem-hids/.env` |
| Keycloak (admin) | `http://10.10.90.1:8080` (IP dinámica, ver `brain/MEMORY.md`) | `admin` / `KEYCLOAK_ADMIN_PASSWORD` de `infra/identity/.env` (hoy `changeme`). *No verificado* si redirige al hostname `auth.lab.local` |
| App de préstamos (DVWA) | `http://10.10.10.10` | DVWA por defecto: `admin` / `password` |
| Host SSH víctima | `ssh -p 2222 labuser@10.10.30.10` | `labuser` / `SSH_TEST_PASSWORD` de `infra/targets/.env` |
| Honeypot Cowrie | `10.10.20.30` puertos `2222` (SSH) / `2223` (Telnet) | cualquier credencial (es una trampa) |
| Mail | `10.10.20.20`, SMTP `25`/`587`, IMAPS `993` | cuenta `alertas@lab.local`, password elegida al crearla |
| Proxmox | `https://192.168.0.102:8006` | cuenta propia de cada uno |

Los `.env` reales viven **solo dentro de `docker-host`** (`/opt/TSI-2026-Infra/infra/*/.env`,
gitignored). Hoy tienen los valores de laboratorio de los `.env.example`.

### Credenciales y accesos — reglas

- **Nada de secretos en el repo** (`.gitignore` ya excluye `.env`, certs de mail y
  backups `config.xml` de OPNsense). El repo es **público**.
- Los tokens/keys que se crearon para que Claude trabajara (token Proxmox, API key
  OPNsense, key SSH) están solo en la máquina de quien los creó. **No se pasan**: si el
  compañero o su IA necesitan acceso, que cada uno cree los suyos.

### Pendientes de seguridad (hacer antes de la auditoría del 14/10)

1. Sacar la key SSH `claude-code-tarea3` de `/root/.ssh/authorized_keys` en `proxmox01`
   (y en la VM 109 si no se borra).
2. Token de Proxmox `root@pam!claude-fq-tsi`: hoy tiene rol **`Administrator`** en `/`
   (necesario para crear bridges) — revocarlo o bajarle permisos cuando no se use.
3. API key de OPNsense creada para Claude (empieza con `iCFF/`): borrarla en
   System → Access → Users → root → API keys.
4. Cambiar las contraseñas por defecto de los `.env` en uso (Keycloak, MySQL, Wazuh API,
   SSH víctima — esta última es débil **a propósito** para CU-02, dejarla así pero
   documentarlo).
5. Indexer de Wazuh corre **sin plugin de seguridad** (simplificación de laboratorio):
   justificarlo como N/A en el Excel MCU o activarlo.
6. VM 109 `vbox-test-host` (apagada, 80 GB de disco): borrarla si nadie va a seguir con
   la prueba de VirtualBox anidado.

### Material que NO está en este repo

- **Plantillas** ISACA (`plantilla/isaca/`), Excel MCU 5.0 (`plantilla/mcu5/excel/`),
  arquitectura 4+1/C4 e informe Red Team: son material del curso, viven fuera de este
  repo (en la carpeta del curso de cada uno). `LETRA.md` y algunos docs las referencian
  con rutas `../plantilla/...` que acá no existen.
- **`config.xml` de OPNsense** (backup real para la copia del Red Team): lo tiene quien lo
  bajó, se pasa por canal privado.

## Cómo empezar

1. Lea `LETRA.md` completo.
2. En la **Semana 1** el equipo genera su **consigna propia** (escenario empresarial ficticio + diagrama de red + casos de uso). Se aprueba con el docente antes de avanzar.
3. Revise la matriz de documentación (sección 8) para saber qué plantilla llenar en cada semana.
4. Copie de `../plantilla/isaca/` las plantillas indicadas a su carpeta `docs/`.
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