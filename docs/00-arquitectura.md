# Arquitectura — Tarea 3 (Blue Team)

> **Estado: BORRADOR** — depende de `40-consigna-propia.md`. Usa la plantilla 4+1 del
> curso para la vista física, que es la **obligatoria y central** en esta tarea
> (LETRA.md §0.2), y C4 niveles 1-2 para el resto (LETRA.md tabla "Uso por tarea": T3 no
> requiere C4 nivel 3/4, salvo que se agregue código de seguridad propio).
>
> La arquitectura es la misma en los dos entornos soportados: **VirtualBox** (`vagrant/`,
> desde cero en cualquier máquina) o **Proxmox** (`infra/README.md` → "Alternativa").
> Solo cambia cómo el hipervisor implementa cada VLAN (columna "Red del hipervisor").
> Antes de la auditoría, confirmar que esta vista coincide con el entorno que se va a
> mostrar (lo exige la plantilla 4+1).

| Campo | Valor |
|---|---|
| Código | ARQ-T3-01 |
| Versión | 0.4 (borrador — falta aprobación docente) |
| Equipo | Blue Team — `[nombres]` |
| Fecha | `[DD/MM/2026]` |
| Aprobación | `[Docente]` — pendiente |

---

## 1. Vista Física (4+1) — obligatoria y central

### 1.1 Segmentos de red

| VLAN | Rol | Subred | Gateway (router) | Red del hipervisor (VirtualBox / Proxmox) |
|---|---|---|---|---|
| — | Internet / WAN | `203.0.113.0/24` en VirtualBox (simulada); red con salida real en Proxmox | `.254` | `vlan_wan` / bridge con salida a internet |
| 10 | Servidores | 10.10.10.0/24 | 10.10.10.254 | `vlan_srv` / bridge aislada |
| 20 | DMZ | 10.10.20.0/24 | 10.10.20.254 | `vlan_dmz` / bridge aislada |
| 30 | Usuarios | 10.10.30.0/24 | 10.10.30.254 | `vlan_usr` / bridge aislada |
| 90 | Gestión | 10.10.90.0/24 | 10.10.90.254 | `vlan_mgmt` / bridge aislada |

Cada VLAN es una red virtual aislada del hipervisor (no hay trunking 802.1Q dentro de
las VMs): el router y `docker-host` tienen una NIC dedicada por VLAN.

### 1.2 Nodos

| Nodo | Rol | Componentes | IP | Recursos | Estado |
|---|---|---|---|---|---|
| `router` (VM) | Firewall/router, NAT | OPNsense (o Linux + nftables en VirtualBox) | .254 en cada VLAN | 1-2 cores / 1-2 GB | ✅ |
| `docker-host` (VM en VirtualBox, LXC privilegiado en Proxmox) | Host de contenedores, 1 NIC por VLAN | Docker Engine + todos los stacks de abajo | .5 en cada VLAN | 2 cores / 9-10 GB | ✅ |
| `identity` (Docker, VLAN Gestión) | MFA administrativo | Keycloak 26.0 + Postgres 16 | 10.10.90.20 (DB .21) | ~1 GB | ✅ contenedor; MFA sin configurar |
| `siem-hids: manager` (Docker, VLAN Gestión) | SIEM, correlación, API | Wazuh manager 4.9.0 | 10.10.90.10 | — | ✅ |
| `siem-hids: indexer` (Docker, VLAN Gestión) | Almacenamiento/búsqueda | Wazuh indexer 4.9.0 (OpenSearch) | 10.10.90.11 | ~1 GB heap | ✅ |
| `siem-hids: dashboard` (Docker, VLAN Gestión) | Consola web | Wazuh dashboard 4.9.0 | 10.10.90.12 | — | ✅ puerto 5601 |
| `nids` (Docker, **VLAN DMZ**) | IDS de red | Suricata 8.0 | 10.10.20.50 | ~0.5 GB | ✅ (ver nota de mirroring) |
| `mail` (Docker, VLAN DMZ) | Correo corporativo | docker-mailserver | 10.10.20.20 | ~0.5 GB | ✅ |
| `honeypot` (Docker, VLAN DMZ) | Trampa de reconocimiento | Cowrie | 10.10.20.30 | ~0.25 GB | ✅ |
| `wazo` (Docker, VLAN DMZ) | Telefonía/atención al cliente | Wazo PBX | 10.10.20.40 (reservada) | ~1.5-2 GB | ❌ no construido |
| `alerting` (Docker, VLAN Gestión) | 2º canal de alertas | Relay webhook | 10.10.90.40 (reservada) | ~0.1 GB | ❌ no construido |
| `targets: webapp + db` (Docker, VLAN Servidores) | App de préstamos | DVWA + MySQL 8.0 | 10.10.10.10 (DB .11) | ~1 GB | ✅ |
| `targets: ssh-client` (Docker, VLAN Usuarios) | Host SSH víctima | `linuxserver/openssh-server` | 10.10.30.10 | — | ✅ |
| `soar-thehive-optional` | SOAR ampliado | TheHive + Cortex + Cassandra + ES | — | ~3-4 GB | ❌ no construido, no hace falta (RF-06 con Wazuh Active Response) |

✅ = construido y probado. Todos los contenedores llevan IP fija.

> **Por qué Suricata está en la DMZ y no en Gestión:** un contenedor Docker ve cada red
> a la que está conectado como `eth0`, `eth1`... en orden de conexión; con una sola red,
> su interfaz de captura es siempre `eth0`. Hoy ve el tráfico de la DMZ, no un espejo
> explícito del router — pendiente de decisión, ver `infra/README.md` → "Qué falta".

### 1.3 Diagrama (texto — reemplazar por imagen en `docs/evidencias/` cuando esté armada)

```
                Internet / WAN (en VirtualBox: vlan_wan, 203.0.113.0/24)
                           │
                 ┌─────────▼─────────┐
                 │      router        │  OPNsense (o nftables), NAT, reglas entre VLANs
                 └───┬───┬───┬───┬────┘
      VLAN10 Srv .254│   │   │   │.254 VLAN90 Mgmt
   ┌─────────────────┘   │   │   └──────────────────┐
   │           VLAN20 DMZ.254│.254 VLAN30 Usr        │
   │                      │    │                     │
┌──▼─────────────────┐ ┌──▼─────────────┐ ┌──────────▼───┐ ┌─▼────────────────────────┐
│ targets webapp .10  │ │ mail .20        │ │ ssh-client   │ │ siem-hids .10/.11/.12    │
│ targets db .11      │ │ honeypot .30    │ │ .10 (víctima)│ │  (manager/indexer/dash)  │
│                     │ │ nids .50        │ │              │ │ keycloak .20 / db .21    │
│                     │ │ wazo .40 ❌     │ │              │ │ alerting .40 ❌           │
│ docker-host .5      │ │ docker-host .5  │ │ docker-host .5│ │ docker-host .5           │
└─────────────────────┘ └─────────────────┘ └──────────────┘ └──────────────────────────┘
```

❌ = stack todavía no construido (no bloquea el freeze del 07/10, ver
`../brain/notes/plan-recuperacion-atraso.md`).

> Nota: el host SSH víctima (RT-02/CU-02) vive en VLAN Usuarios, no en VLAN Servidores
> — simula un puesto comprometido, no el servidor de la app. Ver `infra/targets/docker-compose.yml`.

### 1.4 Copias de seguridad y puntos de monitoreo

- Captura de tráfico: `nids` (Suricata) en la VLAN DMZ. Espejo del router hacia el NIDS:
  pendiente de decisión.
- Agente Wazuh en el host SSH víctima y en la app → `siem-hids` (puertos 1514/1515):
  pendiente.
- Logs de Suricata y Cowrie → Wazuh: pendiente (hoy el SIEM no los ve).
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
| Suricata | Suricata 8.0 | NIDS, firmas sobre tráfico de su red | Docker, VLAN DMZ | — |
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

- [x] ~~Router + 4 VLANs + docker-host~~ (automatizado en `vagrant/`).
- [x] ~~Stacks identity, mail, honeypot, targets, nids, siem-hids~~ — construidos y probados.
- [ ] Llevar logs de Suricata y Cowrie a Wazuh (sin esto ESC-01 no se ve en el SIEM).
- [ ] Instalar agente Wazuh en `targets` (webapp/ssh-client) para HIDS/FIM real (RF-04),
  con la regla del router Servidores/Usuarios → Gestión 1514/1515 (ya incluida en el
  router nftables; en OPNsense, crearla).
- [ ] Configurar MFA en Keycloak (RF-12).
- [ ] Resolver mirroring real de tráfico hacia `nids` (hoy ve solo tráfico de la DMZ).
- [ ] Construir `wazo` y `alerting` (no bloquean el freeze del 07/10).
- [ ] Reemplazar el diagrama en texto por imagen (draw.io/similar) en `docs/evidencias/`.
- [ ] Asignar el 3er playbook de Active Response (RF-06) a CU-04 o CU-05.
- [ ] Aprobación del docente (RF-01), junto con `40-consigna-propia.md`.
