# Arquitectura — Tarea 3 (Blue Team)

> **Estado: BORRADOR** — depende de `40-consigna-propia.md`. Usa la plantilla 4+1
> (`../../plantilla/plantilla-arquitectura-4más1.md`) para la vista física, que es la
> **obligatoria y central** en esta tarea (LETRA.md §0.2), y C4 niveles 1-2 para el resto
> (LETRA.md tabla "Uso por tarea": T3 no requiere C4 nivel 3/4, salvo que se agregue
> código de seguridad propio).
>
> Actualizado 2026-10-02: la vista física ya no es un esquema teórico — refleja la
> infraestructura realmente desplegada y corriendo (`opnrouter` VMID 124, `docker-host`
> CT 108 con 9 de 9 contenedores planeados arriba). Ver `../brain/decisions.md` y
> `../brain/MEMORY.md` para el detalle de cada paso.

| Campo | Valor |
|---|---|
| Código | ARQ-T3-01 |
| Versión | 0.3 (borrador — infra desplegada, falta aprobación docente) |
| Equipo | Blue Team — `[nombres]` |
| Fecha | `[DD/MM/2026]` |
| Aprobación | `[Docente]` — pendiente |

---

## 1. Vista Física (4+1) — obligatoria y central

### 1.1 Segmentos de red (confirmados contra Proxmox real)

| VLAN | Rol | Subred | Gateway (opnrouter) | Bridge Proxmox |
|---|---|---|---|---|
| 10 | Servidores | 10.10.10.0/24 | 10.10.10.254 | `vmbr11` |
| 20 | DMZ | 10.10.20.0/24 | 10.10.20.254 | `vmbr12` |
| 30 | Usuarios | 10.10.30.0/24 | 10.10.30.254 | `vmbr1` |
| 90 | Gestión | 10.10.90.0/24 | 10.10.90.254 | `vmbr13` |

Las 4 bridges existen y las 4 VLANs están activas en `opnrouter` y `docker-host` (confirmado 2026-10-02).

### 1.2 Nodos

| Nodo | Rol | Componentes | IP | Recursos | Estado |
|---|---|---|---|---|---|
| `opnrouter` (VM 124) | Firewall/router, NAT, SPAN | OPNsense/pfSense | .254 en cada VLAN | 2 cores/2GB | ✅ corriendo, 4 VLANs activas |
| `docker-host` (CT 108, LXC **privilegiado**) | Host de contenedores, 1 NIC por VLAN | Docker Engine + todos los stacks de abajo | .5 en cada VLAN | 2 cores/9GB | ✅ corriendo (recreado privilegiado — ver [[decisions]], `docker-mailserver` lo necesita) |
| `lab-srv-datos` (CT 210) | Semilla de un intento anterior | Debian base | 10.10.10.20 (Servidores) | 1 core/1GB | corriendo, sin decidir si se da de baja |
| `lab-web-dmz` (CT 211) | Semilla de un intento anterior | Debian base | 10.10.20.10 (DMZ) | 1 core/1GB | ídem |
| `identity` (Docker, VLAN Gestión) | MFA administrativo | Keycloak 26.0 + Postgres 16 | sin IP fija (DHCP macvlan) | ~1 GB | ✅ corriendo |
| `siem-hids: manager` (Docker, VLAN Gestión) | SIEM, correlación, API | Wazuh manager 4.9.0 | 10.10.90.10 | — | ✅ corriendo |
| `siem-hids: indexer` (Docker, VLAN Gestión) | Almacenamiento/búsqueda | Wazuh indexer 4.9.0 (OpenSearch) | 10.10.90.11 | ~1GB heap | ✅ corriendo |
| `siem-hids: dashboard` (Docker, VLAN Gestión) | Consola web | Wazuh dashboard 4.9.0 | 10.10.90.12 | — | ✅ corriendo, puerto 5601 |
| `nids` (Docker, **VLAN DMZ**) | IDS de red | Suricata 8.0.7 | 10.10.20.50 | ~0.5 GB | ✅ corriendo (ver nota de mirroring abajo) |
| `mail` (Docker, VLAN DMZ) | Correo corporativo | docker-mailserver | 10.10.20.20 | ~0.5 GB | ✅ corriendo, healthy |
| `honeypot` (Docker, VLAN DMZ) | Trampa de reconocimiento | Cowrie | 10.10.20.30 | ~0.25 GB | ✅ corriendo |
| `wazo` (Docker, VLAN DMZ) | Telefonía/atención al cliente | Wazo PBX | 10.10.20.40 (planeado) | ~1.5-2 GB | ❌ no construido todavía |
| `alerting` (Docker, VLAN Gestión) | 2º canal de alertas | Relay webhook | 10.10.90.40 (planeado) | ~0.1 GB | ❌ no construido todavía |
| `targets: webapp+db` (Docker, VLAN Servidores) | App de préstamos | DVWA + MySQL 8.0 | 10.10.10.10 | ~1 GB | ✅ corriendo |
| `targets: ssh-client` (Docker, VLAN Usuarios) | Host SSH víctima | `linuxserver/openssh-server` | 10.10.30.10 | — | ✅ corriendo |
| `soar-thehive-optional` (apagado) | SOAR ampliado | TheHive+Cortex+Cassandra+ES | — | ~3-4 GB | apagado a propósito, ver [[decisions]] |

> .20 en VLAN Servidores y .10 en VLAN DMZ están reservados — los ocupan `lab-srv-datos`
> y `lab-web-dmz`, que son hosts reales fuera de Docker.
>
> **Nids cambió de VLAN Gestión a VLAN DMZ** (2026-10-02): un contenedor Docker solo ve
> la interfaz de la red a la que está conectado, nombrada `eth0` puertas adentro sin
> importar el host — conectarlo a dos redes (gestión + alguna otra) hacía el nombre de
> interfaz ambiguo. Por ahora ve tráfico local de la DMZ vía macvlan, no un mirror
> explícito del router — pendiente de decisión, ver [[decisions]] y `infra/nids/docker-compose.yml`.
>
> Falta conectar un agente Wazuh a `targets` (HIDS/FIM, RF-04) y una regla de firewall en
> OPNsense para que las VLANs Servidores/Usuarios lleguen al manager (1514/1515) en
> VLAN Gestión.

### 1.3 Diagrama (texto — reemplazar por imagen en `docs/evidencias/` cuando esté armada)

```
                        Internet
                           │
                 ┌─────────▼─────────┐
                 │  opnrouter (VM124) │  VLANs 10/20/30/90, NAT
                 └───┬───┬───┬───┬────┘
      VLAN10 Srv .254│   │   │   │.254 VLAN90 Mgmt
   ┌─────────────────┘   │   │   └──────────────────┐
   │           VLAN20 DMZ.254│.254 VLAN30 Usr        │
   │                      │    │                     │
┌──▼─────────────────┐ ┌──▼─────────────┐ ┌──────────▼───┐ ┌─▼────────────────────────┐
│ lab-srv-datos .20   │ │ mail .20 ✅     │ │ ssh-client   │ │ identity (Keycloak) ✅    │
│ targets webapp .10 ✅│ │ honeypot .30 ✅ │ │ .10 (víctima)│ │ siem-hids .10/.11/.12 ✅  │
│ docker-host NIC .5  │ │ nids .50 ✅     │ │ ✅            │ │  (manager/indexer/dash)  │
│                     │ │ wazo .40 ❌     │ │ docker-host  │ │ alerting .40 ❌           │
│                     │ │ lab-web-dmz .10 │ │ NIC .5       │ │ docker-host NIC .5       │
│                     │ │ docker-host .5  │ │              │ │                          │
└─────────────────────┘ └─────────────────┘ └──────────────┘ └──────────────────────────┘
```

✅ = corriendo (2026-10-02). ❌ = stack todavía no construido (no bloquea el freeze del
07/10, ver `../brain/notes/plan-recuperacion-atraso.md`).

> Nota: el host SSH víctima (RT-02/CU-02) vive en VLAN Usuarios, no en VLAN Servidores
> — simula un puesto comprometido, no el servidor de la app. Ver `infra/targets/docker-compose.yml`.

### 1.4 Copias de seguridad y puntos de monitoreo

- SPAN/mirror de `opnrouter` → `nids` (Suricata), único punto de captura de tráfico.
- Agente Wazuh en el host SSH víctima → `siem-hids` (puerto 1514/1515).
- Backup de configuración de `siem-hids` e `identity` → pendiente de definir mecanismo
  (RF-13/RNF-08), anotar en `../brain/decisions.md` cuando se resuelva.

## 2. C4 — Nivel 1: Contexto

| Actor/Sistema externo | Relación con el sistema | Datos intercambiados |
|---|---|---|
| Cliente de FinSegura (internet) | Usa la app de préstamos | Credenciales, datos financieros (TLS) |
| Administrador/IT | Gestiona consolas vía MFA | Credenciales + TOTP/WebAuthn |
| Atacante (Red Team) | Intenta comprometer DMZ/servidores | Tráfico de reconocimiento/explotación |
| Operador de cobranza | Usa Wazo para llamadas | Audio SIP/RTP, datos de contacto |
| Canal de alerta externo (Telegram/Discord, SMTP) | Recibe notificaciones del SIEM/SOAR | Alertas de seguridad |

## 3. C4 — Nivel 2: Contenedores

| Contenedor | Tecnología | Responsabilidad | Despliegue | Protocolo |
|---|---|---|---|---|
| App de préstamos + DB | DVWA + MySQL 8.0 (placeholder vulnerable, se mantiene por el atraso) | Servicio de negocio expuesto a clientes | Docker, VLAN Servidores | HTTP / SQL |
| Host SSH cliente víctima | `linuxserver/openssh-server`, password débil intencional | Simula puesto de usuario comprometible (RT-02/CU-02) | Docker, VLAN Usuarios | SSH |
| Wazuh manager+indexer+dashboard | Wazuh | SIEM + HIDS/FIM, correlación | Docker, VLAN Gestión | Syslog/Beats, HTTPS |
| Suricata | Suricata 8.0.7 | NIDS, firmas sobre tráfico de su red | Docker, VLAN DMZ | — |
| Keycloak | Keycloak | MFA administrativo (TOTP/WebAuthn) | Docker, VLAN Gestión | HTTPS/OIDC |
| Cowrie | Cowrie | Honeypot SSH/Telnet | Docker, VLAN DMZ | SSH/Telnet (falsos) |
| docker-mailserver | Postfix+Dovecot | Correo corporativo, canal de alerta 1 | Docker, VLAN DMZ | SMTP/IMAP |
| Wazo PBX | Wazo/Asterisk | Telefonía, canal de verificación humana | Docker, VLAN DMZ | SIP/RTP |
| Alerting relay | `[webhook script]` | Canal de alerta 2 (Telegram/Discord) | Docker, VLAN Gestión | HTTPS webhook |

## 4. Escenarios (el "+1" de 4+1)

Los 5 casos de uso de `40-consigna-propia.md` §3, mapeados a vistas:

| ID escenario | Descripción | Vistas que toca | Cómo se valida |
|---|---|---|---|
| ESC-01 (CU-01) | Reconocimiento/escaneo DMZ | Física, Procesos | Alerta Suricata visible en Wazuh |
| ESC-02 (CU-02) | Fuerza bruta SSH | Física, Procesos | Playbook bloquea IP; verificar en FW |
| ESC-03 (CU-03) | Webshell en la app | Física, Lógica, Procesos | FIM detecta archivo; host aislado |
| ESC-04 (CU-04) | Credenciales robadas | Lógica (Keycloak), Procesos | MFA bloquea acceso; log de intento |
| ESC-05 (CU-05) | Exfiltración por DNS | Física, Procesos | Correlación SIEM + alerta 2º canal |

## 5. Pendiente

- [x] ~~Crear bridge `vmbr13`, agregar NICs, crear `docker-host`~~ — hecho 2026-10-02.
- [x] ~~Desplegar identity, mail, honeypot, targets, nids, siem-hids~~ — hecho 2026-10-02,
  9/9 contenedores corriendo.
- [ ] Instalar agente Wazuh en `targets` (webapp/ssh-client) para HIDS/FIM real (RF-04).
- [ ] Regla de firewall en OPNsense: VLAN Servidores/Usuarios → VLAN Gestión, puertos
  1514/1515 (si no, el agente Wazuh nunca va a poder conectar al manager).
- [ ] Resolver mirroring real de tráfico hacia `nids` (hoy ve solo tráfico local de su
  VLAN DMZ vía macvlan) — ver [[decisions]].
- [ ] Construir `wazo` y `alerting` (no bloquean el freeze del 07/10).
- [ ] Decidir si `lab-srv-datos`/`lab-web-dmz` se dan de baja, dado que `targets`/
  `mail`/`honeypot` ya corren en `docker-host`.
- [ ] Reemplazar el diagrama en texto por imagen (draw.io/similar) en `docs/evidencias/`.
- [ ] Asignar el 3er playbook de Active Response (RF-06) a CU-04 o CU-05.
- [ ] Aprobación del docente (RF-01), junto con `40-consigna-propia.md`.
