---
title: Plan de recuperación por atraso (H1/H2 vencidos)
tags: [tarea3, plan, atraso, hitos]
updated: 2026-10-06
---

# Plan de recuperación — atraso en H1/H2

## Estado al 06/10/2026 (noche, víspera del freeze)

- Cowrie → Wazuh integrado (Renzo). Se corrigió el orden de `make up` (honeypot antes
  que siem-hids) — sin eso un despliegue desde cero fallaba.
- Un commit (`ecf697c`) había reemplazado el `ssh-client` de CU-02 por un agente aislado
  que no veía sus logs; restaurado (ver [[decisions]] 2026-10-06).
- Sigue **sin verificar**: CU-02 de punta a punta y Cowrie en el dashboard.
- Documentación: igual que al 02/10 — solo los borradores `00` y `40`. Sin bitácora, sin
  Excel, sin evidencias. Es el bloque crítico para el 07/10.

## ▶ Siguiente paso (al 05/10/2026): verificar CU-02

Construido y subido (commit `fd562cf`), **sin probar**. En el entorno de cada uno:

1. Router: permitir Usuarios → `10.10.90.10` TCP 1514/1515 y Gestión → `10.10.20.20`
   TCP 25 (el router nftables de `vagrant/` ya lo hace; en OPNsense, crear las 2 reglas).
2. En `docker-host`: `git pull` y `make up` dentro de `infra/` (construye la imagen
   `ssh-victim`, reconfigura el manager y crea `soc@lab.local`).
3. `docker exec wazuh.manager /var/ossec/bin/agent_control -l` → `ssh-client` Active.
4. Fuerza bruta (12 contraseñas incorrectas) contra `labuser@10.10.30.10:2222` →
   `docker exec target-ssh-client iptables -L INPUT -n` muestra el DROP; en el dashboard
   `rule.id: 5763` y `rule.id: 651`; mail en `soc@lab.local`.

Detalle y comandos: `vagrant/README.md` → "Probar la respuesta automática". Puntos con
riesgo de falla: formato de `auth.log` (rsyslog en contenedor) y que el mailserver
acepte el mail del manager por el 25. Si funciona: capturas a `docs/evidencias/`,
marcar ✅ abajo y en `README.md`. Lo que falle → `brain/LEARNINGS.md`.

## Estado al 02/10/2026 (fin del día 2)

"✅" = construido y probado en el despliegue de referencia de uno de los integrantes. En
VirtualBox se reproduce todo con `vagrant up` (ver `vagrant/README.md`), que todavía no
se probó de punta a punta en una máquina física.

| Ítem del plan | Estado |
|---|---|
| Consigna propia + diagrama (`docs/40`, `docs/00`) | 🔶 borradores escritos — **falta revisarlos entre los dos y aprobación docente** |
| Router + 4 VLANs | ✅ (en VirtualBox: router nftables automático, u OPNsense manual) |
| `docker-host` + Docker | ✅ |
| Keycloak (identity) | ✅ contenedor — **falta configurar MFA (TOTP/WebAuthn) adentro** |
| Suricata (nids) | ✅ con reglas CU-01 — mirror de tráfico sin decidir |
| Wazuh (siem-hids) | ✅ manager + indexer + dashboard |
| Logs de Suricata → Wazuh | ✅ 2026-10-05 — CU-01 (ping + escaneo SYN) visible en el dashboard |
| Logs de Cowrie → Wazuh | 🔶 2026-10-06 (Renzo, `be2e6b7`) — regla 100110; orden de arranque corregido el mismo día; sin verificar en el dashboard |
| Agente Wazuh en `targets` | 🔶 2026-10-05 en `ssh-client` (imagen `targets/ssh-victim/`), sin verificar; falta `webapp` (CU-03) |
| Ataque 1 (recon) documentado | 🔶 detección funcionando end-to-end; falta escribirlo con evidencia (capturas) en `docs/evidencias/` |
| Playbook Active Response + ataque 2 (SSH) | 🔶 2026-10-05 construido (5712/5763 → firewall-drop + mail a soc@lab.local), sin verificar |
| Ataque 3 (webshell) | ❌ pendiente |
| `alerting` (2º canal) | ✂️ candidato a recorte (docente habilitó recortar, ver [[decisions]] 2026-10-05): mail + dashboard |
| Docs ISACA (02, 03, 04, 06, 07, 09...) y Excel MCU | ❌ pendientes |
| Bitácora | ❌ sin empezar — ver "Regla no negociable" abajo |

Extra no planificado que se hizo: despliegue desde cero en VirtualBox en `vagrant/`
(sirve para el compañero y para el Red Team; escrito, **sin probar todavía** en una
máquina física).

En resumen: la infra está adelantada respecto al plan, **la documentación está atrasada**.
Lo que más pesa del 07/10 en adelante es docs + bitácora + los 3 ataques documentados.

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
