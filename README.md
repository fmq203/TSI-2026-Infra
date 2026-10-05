# Tarea 3 — Infraestructura de Red de Defensa Completa

Repo del Blue Team: infraestructura de red de defensa (router/firewall + Wazuh, Suricata,
Keycloak, mail, honeypot y blancos vulnerables en Docker) y su documentación formal.
Este README es la **puerta de entrada**: qué hay, cómo levantarlo desde cero, en qué
estado está y qué falta.

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

## Estado actual (2026-10-02)

- **Infra construida en el repo:** 6 de 9 stacks — `identity` (Keycloak), `siem-hids`
  (Wazuh manager + indexer + dashboard), `nids` (Suricata con reglas para CU-01),
  `mail`, `honeypot` (Cowrie), `targets` (DVWA + MySQL + host SSH víctima). Sin
  construir: `wazo`, `alerting` (y `soar-thehive-optional`, que no hace falta).
  Probados y funcionando en el despliegue de referencia de uno de los integrantes.
- **`vagrant/`:** escrito y revisado, **todavía no probado de punta a punta en una
  máquina física**. Quien lo corra primero: anotar en `brain/LEARNINGS.md` lo que falle.
- **docs/:** `00-arquitectura.md` y `40-consigna-propia.md` en borrador — **falta
  revisarlos entre los dos y aprobación docente**. El resto de la matriz en `☐`
  (`docs/README.md`). Bitácora sin empezar.
- Atraso: H1 (21/09) y H2 (28/09) vencidos; se sigue
  `brain/notes/plan-recuperacion-atraso.md`. **La infra va adelantada, la documentación
  atrasada.**

## Pendientes

### Infra (para la demo de la auditoría)

1. **Logs de Cowrie → Wazuh.** Suricata ya está conectado a Wazuh y **CU-01 se ve de
   punta a punta** (2026-10-05: ping y escaneo SYN desde la VLAN Servidores → alertas
   1000005/1000001 en Suricata → regla 86601 en Wazuh → visibles en el dashboard).
   Falta el honeypot. Suricata solo ve tráfico dirigido a su IP (`10.10.20.50`), y el
   router tiene que dejar pasar al atacante hasta ahí (ver `brain/LEARNINGS.md`).
2. **Verificar CU-02** (construido 2026-10-05, sin probar): agente Wazuh en
   `target-ssh-client` → fuerza bruta SSH → Active Response `firewall-drop` → mail a
   `soc@lab.local`. Cómo probarlo: `vagrant/README.md` → "Probar la respuesta
   automática". En OPNsense hacen falta las reglas Usuarios → Gestión 1514/1515 y
   Gestión → DMZ 25. Después: agente en `webapp` para CU-03 (FIM).
3. **MFA en Keycloak** (TOTP/WebAuthn, RF-12): el contenedor corre, falta configurar
   realm, usuarios y MFA.
4. **Active Response** para CU-03 (webshell): el de CU-02 ya está.
5. Decidir cómo le llega tráfico espejado a Suricata (hoy ve solo el tráfico de la DMZ).
6. `wazo` y `alerting`: candidatos a recorte con justificación (el docente lo habilitó,
   ver `brain/decisions.md` 2026-10-05).

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
