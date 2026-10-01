# Arquitectura — Tarea 3 (Blue Team)

> **Estado: BORRADOR** — depende de `40-consigna-propia.md`. Usa la plantilla 4+1
> (`../../plantilla/plantilla-arquitectura-4más1.md`) para la vista física, que es la
> **obligatoria y central** en esta tarea (LETRA.md §0.2), y C4 niveles 1-2 para el resto
> (LETRA.md tabla "Uso por tarea": T3 no requiere C4 nivel 3/4, salvo que se agregue
> código de seguridad propio).
>
> Actualizado 2026-10-01: la vista física ya no es un esquema teórico — refleja la red
> real que el equipo ya tiene armada en Proxmox (`opnrouter` VMID 124 + CTs
> `lab-srv-datos`/`lab-web-dmz`, descubiertos de un intento anterior no documentado).
> Ver `../brain/decisions.md`.

| Campo | Valor |
|---|---|
| Código | ARQ-T3-01 |
| Versión | 0.2 (borrador) |
| Equipo | Blue Team — `[nombres]` |
| Fecha | `[DD/MM/2026]` |
| Aprobación | `[Docente]` — pendiente |

---

## 1. Vista Física (4+1) — obligatoria y central

### 1.1 Segmentos de red (confirmados contra Proxmox real)

| VLAN | Rol | Subred | Gateway (opnrouter) | Bridge Proxmox |
|---|---|---|---|---|
| 10 | Servidores | 10.10.10.0/24 | 10.10.10.254 | `vmbr11` (existe) |
| 20 | DMZ | 10.10.20.0/24 | 10.10.20.254 | `vmbr12` (existe) |
| 30 | Usuarios | 10.10.30.0/24 | 10.10.30.254 | `vmbr1` (existe, libre) |
| 90 | Gestión | 10.10.90.0/24 | 10.10.90.254 | `vmbr13` (**a crear**) |

### 1.2 Nodos

| Nodo | Rol | Componentes | IP | Recursos | Puertos relevantes |
|---|---|---|---|---|---|
| `opnrouter` (VM 124, **ya existe**) | Firewall/router, NAT, SPAN | OPNsense/pfSense | .254 en cada VLAN (faltan NICs de VLAN 30 y 90) | 1 core/1GB actual → subir a 2 cores/2GB | SPAN/mirror hacia `nids` |
| `docker-host` (LXC, **a crear**) | Host de contenedores, 1 NIC por VLAN | Docker Engine + todos los stacks de abajo | .5 en cada VLAN | privilegiado, nesting=1; ~9-10 GB para que entren los contenedores | — |
| `lab-srv-datos` (CT 210, **ya existe**) | Semilla de un intento anterior | Debian base | 10.10.10.20 (VLAN Servidores) | 1 core/1GB | — revisar si se reutiliza o se da de baja una vez que `targets/` esté en `docker-host` |
| `lab-web-dmz` (CT 211, **ya existe**) | Semilla de un intento anterior | Debian base | 10.10.20.10 (VLAN DMZ) | 1 core/1GB | ídem |
| `identity` (Docker, VLAN 90) | MFA administrativo | Keycloak 26.0 + Postgres 16 | 10.10.90.20 | ~1 GB | 8080/8443 |
| `siem-hids` (Docker, VLAN 90) | SIEM + HIDS/FIM | Wazuh manager+indexer+dashboard | 10.10.90.10 | ~3-4 GB | 1514/1515, 443 |
| `nids` (Docker, VLAN 90, sniff) | IDS de red | Suricata | 10.10.90.30 (gestión) + interfaz SPAN sin IP | ~0.5 GB | — |
| `mail` (Docker, VLAN 20) | Correo corporativo | docker-mailserver | 10.10.20.20 | ~0.5 GB | 25/587/993 |
| `honeypot` (Docker, VLAN 20) | Trampa de reconocimiento | Cowrie | 10.10.20.30 | ~0.25 GB | 2222/2223 |
| `wazo` (Docker, VLAN 20) | Telefonía/atención al cliente | Wazo PBX | 10.10.20.40 | ~1.5-2 GB | SIP 5060, RTP |
| `alerting` (Docker, VLAN 90) | 2º canal de alertas | Relay webhook | 10.10.90.40 | ~0.1 GB | — |
| `targets: webapp+db` (Docker, VLAN 10) | App de préstamos | DVWA + MySQL 8.0 | 10.10.10.10 | ~1 GB | 8081 |
| `targets: ssh-client` (Docker, VLAN 30) | Host SSH víctima | `linuxserver/openssh-server` | 10.10.30.10 | — | 2022→2222 |
| `soar-thehive-optional` (apagado) | SOAR ampliado | TheHive+Cortex+Cassandra+ES | — | ~3-4 GB | apagado, ver `../brain/decisions.md` |

> .20 en VLAN Servidores y .10 en VLAN DMZ están reservados — los ocupan `lab-srv-datos`
> y `lab-web-dmz`, que son hosts reales fuera de Docker.

### 1.3 Diagrama (texto — reemplazar por imagen en `docs/evidencias/` cuando esté armada)

```
                        Internet
                           │
                 ┌─────────▼─────────┐
                 │  opnrouter (VM124) │  VLANs 10/20/30/90, NAT, SPAN→nids
                 └───┬───┬───┬───┬────┘
      VLAN10 Srv .254│   │   │   │.254 VLAN90 Mgmt
   ┌─────────────────┘   │   │   └──────────────────┐
   │           VLAN20 DMZ.254│.254 VLAN30 Usr        │
   │                      │    │                     │
┌──▼─────────────────┐ ┌──▼─────────────┐ ┌──────────▼───┐ ┌─▼──────────────────────┐
│ lab-srv-datos .20   │ │ mail .20        │ │ ssh-client   │ │ siem-hids .10 (Wazuh)  │
│ targets webapp .10  │ │ honeypot .30    │ │ .10 (víctima)│ │ identity .20 (Keycloak)│
│ docker-host NIC .5  │ │ wazo .40        │ │ docker-host  │ │ nids .30 (sniff)       │
│                     │ │ lab-web-dmz .10 │ │ NIC .5       │ │ alerting .40           │
│                     │ │ docker-host .5  │ │              │ │ docker-host NIC .5     │
└─────────────────────┘ └─────────────────┘ └──────────────┘ └────────────────────────┘
```

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
| Suricata | Suricata | NIDS, firmas sobre tráfico espejado | Docker, VLAN Gestión (sniff) | — |
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

- [ ] Crear bridge `vmbr13` en Proxmox (VLAN 90, Gestión) — único bridge que falta.
- [ ] Agregar 2 NICs a `opnrouter` (vmbr1 y vmbr13) y configurar `.254` + reglas NAT/firewall en cada una.
- [ ] Crear `docker-host` como LXC privilegiado con 4 NICs.
- [ ] Decidir si `lab-srv-datos`/`lab-web-dmz` se dan de baja una vez que `targets`/`mail`/`honeypot` corran en `docker-host`, o si se reutilizan para otra cosa (evitar duplicar IPs: hoy ocupan `.20`/`.10` que ya están reservados).
- [ ] Reemplazar el diagrama en texto por imagen (draw.io/similar) en `docs/evidencias/`.
- [ ] Asignar el 3er playbook de Active Response (RF-06) a CU-04 o CU-05.
- [ ] Aprobación del docente (RF-01), junto con `40-consigna-propia.md`.
