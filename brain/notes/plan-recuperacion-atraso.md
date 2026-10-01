---
title: Plan de recuperación por atraso (H1/H2 vencidos)
tags: [tarea3, plan, atraso, hitos]
updated: 2026-10-01
---

# Plan de recuperación — atraso en H1/H2

## Contexto (conversación 01/10/2026)

- Equipo de **2 personas**.
- Consigna propia: escenario empresarial **decidido**, pero diagrama técnico y casos de
  uso concretos **sin cerrar** a esta fecha.
- H1 (21/09) y H2 (28/09) de LETRA.md §6.3 vencidos sin evidencia de avance en
  `infra/` ni `docs/` (ver [[MEMORY]] — "Estado de avance observado").
- Próximo hito duro real: **pre-entrega Blue Team, miércoles 07/10/2026** (`git tag
  v1.0` + Excel/bitácora completos). Quedan 6 días desde hoy.

## Plan día a día acordado

| Día | Fecha | Persona A | Persona B |
|---|---|---|---|
| 1 | jue 01/10 | Juntos: cerrar diagrama + 5 casos de uso + escribir `docs/40-consigna-propia.md` y `docs/00-arquitectura.md`. Luego: provisioning VMs Proxmox (router-fw + docker-host) + `docker-compose.networks.yml` | (junto arriba) → levanta `infra/identity` (Keycloak MFA, RF-12) |
| 2 | vie 02/10 | Segmentación VLAN en router + `infra/nids` (Suricata) básico, SPAN al NIDS | `infra/siem-hids` (Wazuh manager+indexer+dashboard) + agente en `targets/` |
| 3 | sáb 03/10 | (continúa NIDS/segmentación) | (continúa Wazuh/agente) |
| 4 | dom 04/10 | Juntos: ataque 1 (reconocimiento/escaneo) end-to-end, documentar con evidencia real → alimenta `docs/02-registro-activos` y `docs/03-analisis-riesgos` | |
| 5 | lun 05/10 | Playbook Wazuh Active Response (bloqueo IP) → ataque 2 (fuerza bruta SSH) completo: detección→respuesta→notificación | `infra/alerting` (webhook 2º canal) + `docs/07-monitoreo-logs`, `docs/09-gestion-accesos` |
| 6 | mar 06/10 | Ataque 3 (webshell/exfiltración) contra `targets/`/honeypot, evidencia a `docs/evidencias/` | Cierra `docs/04-gestion-incidentes`, `docs/06-plan-continuidad` (básico), Excel MCU 01/02/03 |
| 7 | mié 07/10 | Revisión conjunta, Excel 04-bitácora al día, demo ≤8min, commit final, `git tag v1.0`, push | |

## Qué se corta o se pospone (decisión, no omisión)

- `mail/` completo (Postfix+Dovecot+DKIM real) y `wazo/` a fondo: mínimamente operativos
  para el 07/10, se pulen 08-13/10 antes de la auditoría (14/10). No son parte de lo que
  exige explícitamente H4.
- `soar-thehive-optional/`: sigue apagado, ver [[decisions]].
- `docs/11-soa-plan-tratamiento` y `docs/12-notificacion-incidentes`: versión mínima
  para el 07/10, se completan la semana de la auditoría si hace falta.

## Regla no negociable: bitácora

No se reconstruyen retroactivamente entradas de bitácora de los días sin registro
(21/09-30/09). La entrada del 01/10 debe decir explícitamente que no hubo registro
previo y por qué se retoma ahora — la letra exige "no se omiten fallos" (LETRA.md §6.5).

## Riesgo abierto

Con 2 personas y todo lo que falta (2 VMs sin provisionar, 6 de 9 stacks Docker sin
contenido, reglas Suricata/Wazuh, 3 playbooks, 11 plantillas + 4 Excel), este plan es
ajustado. Si para el día 3 (sáb 03/10) no está la infra base (NIDS+SIEM) operativa,
conviene avisar al docente proactivamente y negociar alcance reducido en vez de
intentar llegar a los 17 RF completos — la letra premia la justificación honesta de
N/A sobre una implementación apurada y rota.
