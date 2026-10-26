# Informe de evidencias — Red Team (Tarea 3)

> Documento de trabajo: se completa **caso por caso** a medida que se ejecutan los
> ataques. La evidencia (capturas, salidas de comando) va en
> `docs-red-team/evidencias/CU-0X/`. Las credenciales y contraseñas que figuran acá son
> **de laboratorio** (entorno aislado en VirtualBox).

| Campo | Valor |
|---|---|
| Equipo | Red Team |
| Rama | `RedTeam` |
| Escenario atacado | FinSegura S.A. (infraestructura Blue Team, `docs/40-consigna-propia.md`) |
| Entorno | VirtualBox + Vagrant (copia local), ver `vagrant/README.md` |
| Punto de ataque | VM Kali en VLAN Usuarios (`10.10.30.100`) + navegador por túnel SSH |
| Fecha de inicio | 2026-10-25 |

---

## 0. Preparación y estado del entorno

Infraestructura levantada y verificada operativa el 2026-10-25. Objetivos accesibles:

| Objetivo | Dirección | VLAN |
|---|---|---|
| App préstamos (DVWA) | `10.10.10.10:80` | Servidores (10) |
| Base de datos (MySQL) | `10.10.10.11:3306` | Servidores (10) |
| Host SSH víctima | `10.10.30.10:2222` | Usuarios (30) |
| Honeypot (Cowrie) | `10.10.20.30:2222/2223` | DMZ (20) |
| NIDS (Suricata) | `10.10.20.50` | DMZ (20) |
| Mail (SMTP) | `10.10.20.20:25` | DMZ (20) |
| Wazuh dashboard | `10.10.90.12:5601` | Gestión (90) |
| Keycloak | `10.10.90.20:8080` | Gestión (90) |

### Hallazgo de entorno (H-00): la cadena de detección no sobrevive a un redespliegue

Al levantar el entorno desde cero, los agentes Wazuh (`webapp`, `ssh-client`) quedaron
**desenrolados** (el manager se recrea sin persistir las claves) y el contenedor `webapp`
entró en bucle de reinicio: su `entrypoint.sh` usa `set -e` y aborta todo el arranque
—incluida la app DVWA— si el enrolamiento del agente falla. Impacto: tras un redespliegue,
**la detección (CU-02/CU-03) queda caída hasta reenrolar manualmente**, y un acoplamiento
frágil hace que un fallo del SIEM tire abajo el servicio productivo (DVWA).

> Nota operativa: para que el laboratorio en VirtualBox fuera alcanzable hubo que activar
> modo promiscuo en las NIC de VLAN de `docker-host` (VirtualBox `allow-all` + `PROMISC`
> a nivel Linux, persistido con un servicio systemd). Es un detalle del entorno de
> pruebas, no una vulnerabilidad del blanco.

---

## CU-01 — Reconocimiento / escaneo de puertos

- **Objetivo:** red interna, app de préstamos (`10.10.10.10`) y NIDS/DMZ (`10.10.20.50`)
- **Detección esperada (Blue Team):** firma Suricata → Wazuh, sin bloqueo automático.

### Parte A — Reconocimiento desde la VLAN de Usuarios (2026-10-25)

**Posición:** Kali en VLAN Usuarios (`10.10.30.100`), como puesto de usuario comprometido.

#### Comandos ejecutados
```bash
sudo nmap -sn 10.10.30.0/24                    # descubrimiento del segmento Usuarios
sudo nmap -sS -sV -p 1-1000 10.10.30.10        # SSH víctima
sudo nmap -sS -sV -p 1-1000 10.10.10.10        # app de préstamos (Servidores)
sudo nmap -sS -p 25,587,993,2222 10.10.20.50   # NIDS/DMZ (SYN)
sudo nmap -sN -p 25,587,993 10.10.20.50        # NIDS/DMZ (NULL)
sudo nmap -sF -p 25,587,993 10.10.20.50        # NIDS/DMZ (FIN)
```

#### Resultado
- **Descubrimiento (Usuarios):** 4 hosts vivos — `10.10.30.5` (docker-host), `10.10.30.10`
  (SSH víctima), `10.10.30.254` (gateway), `10.10.30.100` (atacante).
- **SSH víctima (1-1000):** todos *closed* (el servicio SSH está en 2222, fuera del rango).
- **App de préstamos `10.10.10.10` (1-1000):** **todos *filtered* (no-response)** → la
  segmentación bloquea Usuarios→Servidores en ese rango.
- **NIDS `10.10.20.50`:** SYN → *filtered*; NULL y FIN → *closed* (RST). Es decir, los
  paquetes stateless (NULL/FIN) reciben RST mientras el SYN es descartado.

#### Respuesta del Blue Team observada
- **Suricata: 0 eventos** registrados desde `10.10.30.100` (`eve.json`). El RST de los
  scans NULL/FIN lo genera el firewall/router al rechazar; **el tráfico nunca llega a la
  DMZ**, así que Suricata no lo ve y **no se dispara ninguna alerta**.

#### Hallazgo / conclusión
- **H-01.1 (defensa efectiva):** la segmentación impide que un puesto de Usuarios haga
  reconocimiento contra Servidores y la DMZ. El NIDS queda ciego a este escaneo porque
  nunca lo alcanza.
- **H-01.2 (observación de evasión):** el firewall responde distinto a SYN (drop) que a
  NULL/FIN (reject con RST). No permite llegar a la DMZ, pero la diferencia de respuesta
  permite a un atacante **inferir que hay un filtro con estado** delante.

### Parte B — Reconocimiento desde "Internet" (VLAN WAN) — _pendiente_

**Posición:** Kali en VLAN WAN (`203.0.113.100`), como atacante externo.
Objetivo: escanear los puertos publicados de la DMZ para disparar las firmas de Suricata.

```bash
_(a completar)_
```
_(capturas en `evidencias/CU-01/`)_

---

## CU-02 — Fuerza bruta SSH

- **Objetivo:** Host SSH víctima (`10.10.30.10:2222`, usuario `labuser`)
- **Posición del atacante:** VM Kali en VLAN Usuarios (`10.10.30.100`)
- **Detección esperada (Blue Team):** regla Wazuh 5712/5763 → Active Response
  `firewall-drop` → mail al SOC.

### Comandos ejecutados
Pablo, 25/10/2026, desde Kali en VLAN Usuarios (`eth2` = `10.10.30.100`).
Intentos SSH fallidos contra `labuser@10.10.30.10` puerto 2222.

### Resultado
Wazuh registró los fallos en el agente `ssh-client` (002). A los ~3 s disparó la
regla **5763** (nivel 10, brute force). A los ~3 s siguientes, Active Response
`firewall-drop` (regla **651**) dejó un `DROP` de `10.10.30.100` en el `iptables`
del contenedor. Un SSH nuevo desde Kali quedó en *connection timed out*.

El mail al SOC salió: `soc@lab.local`, 26/10 02:12:04 UTC (23:12:04 hora local),
asunto "Wazuh notification - (ssh-client) any - Alert level 10". Unos 15 s
después de la alerta de nivel 10.

### Evidencia
- `evidencias/CU-02/script1-wazuh.png` — Threat Hunting con 5760, 5763 y 651.
- `evidencias/CU-02/script2-kali terminal.jpg` — SSH desde Kali a `10.10.30.10:2222`,
  *connection timed out*.
- `evidencias/CU-02/2026-10-25_CU-02_deteccion-respuesta.txt` — línea de tiempo e
  `iptables`.

### Respuesta del Blue Team observada
| Hito | Hora local (dashboard) | Delta |
|---|---|---|
| Primer fallo (5503 / 5760) | 23:11:45.717 | — |
| Alerta 5763, nivel 10 | 23:11:48.721 | MTTD ~3 s |
| `firewall-drop` (651) | 23:11:51.726 | MTTR ~3 s |
| Mail en `soc@lab.local` | 23:12:04 | +15 s desde la alerta |

### Hallazgo / conclusión
El control de CU-02 funcionó de punta a punta: detección, bloqueo de la IP
atacante y aviso por mail. No hubo evasión. La regla que cortó fue **5763**
(usuario existente), no la 5712 (usuario inexistente).

---

## CU-03 — Webshell / inyección en la app de préstamos

- **Objetivo:** DVWA (`10.10.10.10`)
- **Posición del atacante:** VM Kali en VLAN Usuarios (`eth2` = `10.10.30.100`), con ruta
  `10.10.10.0/24` vía `10.10.30.254`
- **Detección esperada (Blue Team):** FIM Wazuh sobre `/var/www/html` → Active Response
  `isolate-webapp` → mail al SOC.

### Comandos ejecutados
Pablo, 25/10/2026, desde Kali. DVWA con usuario `admin` y Security Level **low**.
Se subió `cu03-pablo.php` por File Upload. DVWA lo dejó en
`/var/www/html/hackable/uploads/cu03-pablo.php`.

### Resultado
Wazuh lo registró en el agente `webapp` (001) con la regla **100200**, nivel 12,
a las 23:45:21. En el mismo segundo corrió `isolate-webapp`: el contenedor perdió
la ruta por defecto y conservó solo la red `10.10.10.0/24` y la ruta a
`10.10.90.10`. Un `curl` desde Kali a `http://10.10.10.10/` quedó sin respuesta HTTP.

El mail al SOC salió: `soc@lab.local`, 26/10 02:45:35 UTC (23:45:35 hora local),
asunto "Wazuh notification - (webapp) any - Alert level 12". Unos 14 s después
de la alerta.

### Evidencia
- `evidencias/CU-03/01_file upload.jpg` — DVWA confirma la subida de `cu03-pablo.php`.
- `evidencias/CU-03/02_Wazuh evidencia rule 100200.png` — Threat Hunting, regla 100200
  nivel 12, agente `webapp`.
- `evidencias/CU-03/03_kali terminal curl.jpg` — `curl` desde Kali sin encabezado HTTP.
- `evidencias/CU-03/2026-10-25_CU-03_deteccion-respuesta.txt` — línea de tiempo,
  rutas del contenedor y el mail.

### Respuesta del Blue Team observada
| Hito | Hora local | Delta |
|---|---|---|
| Alerta 100200, nivel 12 | 23:45:21.056 | MTTD en el mismo segundo |
| `isolate-webapp` | 23:45:21 | MTTR ~0 s |
| Mail en `soc@lab.local` | 23:45:35 | +14 s desde la alerta |

### Hallazgo / conclusión
El control de CU-03 funcionó de punta a punta: el archivo `.php` nuevo en el webroot
disparó el FIM, el contenedor quedó aislado con el canal a Wazuh intacto, y el SOC
recibió el mail. No hubo evasión.

---

## CU-04 — Uso de credenciales por defecto / robadas (identidad)

- **Objetivo:** Keycloak (`10.10.90.20:8080`) y Wazuh dashboard (`10.10.90.12:5601`)
- **Posición del atacante:** navegador por túnel SSH / VLAN Gestión

### Hallazgos preliminares (2026-10-25)
- **H-04.1 — Keycloak con credencial de administrador por defecto:** acceso a la consola
  de administración del realm `master` con `admin` / `changeme`. Keycloak mismo advierte
  "You are logged in as a temporary admin user" (cuenta temporal sin endurecer).
  Evidencia: `evidencias/CU-04/`.
- **H-04.2 — Wazuh dashboard sin autenticación:** el dashboard abre sin login (plugin de
  seguridad de OpenSearch desactivado). Cualquiera con acceso de red a Gestión ve todas
  las alertas y la configuración del SIEM. Evidencia: `evidencias/CU-04/`.

### Respuesta del Blue Team observada
_(a completar — revisar si quedó registro en Events de Keycloak)_

### Hallazgo / conclusión
_(a completar — contrastar con el MFA/TOTP del realm `lab`, que sí bloquea)_

---

## CU-05 — Exfiltración de datos por DNS

- **Objetivo:** Base de datos de préstamos / salida DNS
- **Posición del atacante:** host comprometido (DVWA vía webshell, o Kali)
- **Detección esperada (Blue Team):** **no implementada** (CU-05 quedó pendiente en el
  Blue Team) — hipótesis a confirmar.

### Comandos ejecutados
```bash
_(a completar)_
```

### Resultado
_(a completar)_

### Evidencia
_(capturas en `evidencias/CU-05/`)_

### Hallazgo / conclusión
_(a completar)_

---

## Resumen de hallazgos

| ID | Hallazgo | Severidad | Estado |
|---|---|---|---|
| H-00 | Detección caída tras redespliegue + acoplamiento DVWA↔agente (`set -e`) | Media | Documentado |
| H-04.1 | Keycloak con credencial admin por defecto (`admin`/`changeme`) | Alta | Confirmado |
| H-04.2 | Wazuh dashboard sin autenticación | Alta | Confirmado |
| ... | _(se agregan a medida que avanzan los casos)_ | | |
