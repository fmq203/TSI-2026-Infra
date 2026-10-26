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

## CU-06 — Inspección estática del repositorio

Sin tráfico contra el laboratorio. La Parte A revisa Dockerfiles y secretos
con Trivy. La Parte B revisa shell, Dockerfiles, compose y secretos con Semgrep.

### Parte A — Trivy 0.76.1 (2026-10-26)

Herramienta de revisión de código e imágenes, sin tráfico contra el laboratorio.
Comando: `trivy fs --scanners misconfig,secret`, salteando las carpetas de
evidencias y los Excel. En esta versión los scanners de configuración son
Dockerfile, Helm, Kubernetes, Terraform, Ansible y CloudFormation. Los
`docker-compose.yml` no se evaluaron.

El scanner de secretos no devolvió coincidencias.

| Archivo | ID | Severidad | Qué marcó |
|---|---|---|---|
| `infra/targets/web-victim/Dockerfile` | DS-0001 | Media | Tag `:latest` en `vulnerables/web-dvwa` |
| `infra/targets/web-victim/Dockerfile` | DS-0002 | Alta | `USER root` |
| `infra/targets/ssh-victim/Dockerfile` | DS-0002 | Alta | Sin `USER`: la imagen corre como root |
| `infra/targets/wazuh-agent/Dockerfile` | DS-0002 | Alta | Sin `USER`: la imagen corre como root |
| `infra/targets/wazuh-agent/Dockerfile` | DS-0029 | Alta | `apt-get install` sin `--no-install-recommends` |
| Los tres Dockerfiles | DS-0026 | Baja | Sin `HEALTHCHECK` |

`infra/targets/wazuh-agent/` no lo usa el compose actual (el agente va dentro
de `ssh-victim` y `web-victim`). El hallazgo queda en el árbol igual.

### Hallazgo / conclusión
- **H-EST-01:** las imágenes de los blancos se construyen como root. Un proceso
  que salga del servicio dentro del contenedor hereda ese usuario.
- **H-EST-02:** la app de préstamos parte de `vulnerables/web-dvwa:latest`. El
  tag no queda fijo y la base es una aplicación vulnerable a propósito.
- El scanner de secretos no aporta un hallazgo nuevo respecto de las claves de
  laboratorio ya anotadas en CU-04.

Evidencia: `evidencias/CU-06/trivy-fs.txt` y `evidencias/CU-06/trivy-fs.json`.

### Parte B — Semgrep 1.182.1 (2026-10-26)

El scanner de secretos no devolvió coincidencias. Las reglas de compose
tampoco: cubren `privileged`, el socket de Docker, seccomp, SELinux,
`no-new-privileges` y filesystem escribible, y el patrón pide la clave
`version:`. Los compose de este repo arrancan en `services:` y declaran
`cap_add`. Esa capacidad no entra en el conjunto, así que este pase no la
evalúa.

| Archivo | Regla | Severidad | Qué marcó |
|---|---|---|---|
| `infra/targets/web-victim/Dockerfile` | `last-user-is-root` | Error | El último `USER` es root (línea 3) |
| `infra/targets/ssh-victim/Dockerfile` | `missing-user-entrypoint` | Error | `ENTRYPOINT` sin un `USER` distinto de root (línea 37) |
| `infra/targets/wazuh-agent/Dockerfile` | `missing-user` | Error | `CMD` sin un `USER` distinto de root (línea 11) |
| `infra/siem-hids/configure-manager.sh` | `unquoted-variable-expansion-in-command` | Info | 10 expansiones sin comillas (líneas 25, 35, 36, 82, 83, 95, 97, 98, 105, 106) |
| `infra/targets/web-victim/isolate-webapp.sh` | `unquoted-variable-expansion-in-command` | Info | Líneas 16, 27 y 30 |

Las expansiones sin comillas usan variables del mismo script con nombres e IP
fijos, sin espacios. Con esos valores el corte de la línea no se produce.

### Hallazgo / conclusión
- Los tres ERROR de Dockerfile son el mismo punto que **H-EST-01** (Parte A,
  Trivy DS-0002): las imágenes de los blancos quedan como root.
- **H-EST-03:** `configure-manager.sh` e `isolate-webapp.sh` expanden variables
  sin comillas. Severidad info de la regla; impacto bajo con los valores
  actuales.
- Secretos: nada nuevo respecto de las claves de laboratorio ya anotadas en
  CU-04.

Evidencia: `evidencias/CU-06/semgrep.txt` y `evidencias/CU-06/semgrep.json`.

---

## CU-07 — Avisos públicos de las tecnologías (2026-10-26)

Contraste de la versión que declara el repo con avisos públicos. No hubo
tráfico contra el laboratorio ni `docker pull`. Un tag móvil (`latest`,
`16-alpine`, `8.0`) no alcanza para afirmar un CVE: el parche que bajaría
hoy puede ser otro.

### Versiones fijas

| Producto | Versión en el repo | Aviso | Severidad | Qué implica |
|---|---|---|---|---|
| Wazuh manager | 4.9.0 | CVE-2025-24016 | Crítica (9.0) | Deserialización insegura. Quien tenga acceso a la API, o en ciertas configuraciones un agente comprometido, puede ejecutar código en el manager. Corregido en 4.9.1 |
| Wazuh manager | 4.9.0 | GHSA-gj9h-8hmr-xjjr | Alta | Un usuario autenticado con el rol `users_admin` puede cambiar la contraseña de las cuentas de administrador reservadas. El aviso incluye 4.9.0; el arreglo de esa línea es 4.10.4 |
| Wazuh dashboard | 4.9.0 | GHSA-648q-8m78-5cwv | Media (4.6) | Un usuario con pocos privilegios puede ver el listado de agentes. Corregido en 4.9.1. En este laboratorio el dashboard ya abre sin login (H-04.2) |
| Keycloak | tag `26.0` | CVE-2026-18963 | Crítica (9.1) | Toma de cuenta sin autenticación por el flujo de recuperación de contraseña. La línea 26.0 no tiene parche (el arreglo está en 26.4.15, 26.6.6 o 26.7.2) |
| Keycloak | tag `26.0` | CVE-2026-7507 | Alta (7.5) | Fijación de sesión en el login OIDC. Pide que la víctima abra un enlace y puede terminar en toma de cuenta. Corregido en 26.6.2 |
| Keycloak | tag `26.0` | CVE-2026-4634 | Alta (7.5) | Denegación de servicio no autenticada en el endpoint OIDC de tokens. Corregido en 26.5.7 |

El tag `quay.io/keycloak/keycloak:26.0` no fija el parche. Un índice público
del 23/10/2026 lo resolvió a 26.0.8, que sigue dentro de esos tres rangos.
26.0 ya no recibe parches.

El aviso del manager pide acceso a la API. En este laboratorio esa clave está
en el ejemplo y el dashboard no autentica (H-04.2).

### Producto vulnerable a propósito

**H-07.7 — DVWA.** `vulnerables/web-dvwa:latest` es la app de préstamos. El
proyecto publica a propósito inyección SQL, XSS, subida de archivos, inyección
de comandos y CSRF, según el nivel de seguridad. No es un CVE sobre una
versión atrasada: es el blanco del ejercicio. CU-03 ya mostró la subida de un
`.php` con el nivel low.

### Revisado y no atribuible a este pin

- CVE-2026-74041 (Wazuh, crítica) empieza en 4.14.3. 4.9.0 queda afuera.
- GHSA-pmr2-2r83-h3cv es el agente de Windows y está corregido en 4.9.0. Los
  agentes de este laboratorio son Linux.
- CVE-2026-2603 (Keycloak) pide un proveedor SAML. Este compose no lo declara.
- CVE-2025-34469 afecta a Cowrie anterior a 2.9.0. Al 26/10/2026 el tag
  `latest` de Docker Hub coincide con 3.1. El compose no fija versión, así
  que una imagen vieja en caché sí podría tenerlo. No se afirma sobre un pull
  actual.
- `jasonish/suricata:latest`, `mysql:8.0`, `postgres:16-alpine` y
  `docker-mailserver:latest` no fijan el parche. Sin resolver la imagen no
  se les asigna un CVE.

### Hallazgo / conclusión

- **H-07.1:** el manager Wazuh 4.9.0 está dentro de CVE-2025-24016.
- **H-07.2:** la API de ese mismo manager está dentro de GHSA-gj9h-8hmr-xjjr.
- **H-07.3:** el dashboard 4.9.0 está dentro de GHSA-648q-8m78-5cwv. El efecto
  práctico ya lo cubre H-04.2.
- **H-07.4:** Keycloak `26.0` está dentro de CVE-2026-18963.
- **H-07.5:** el mismo tag está dentro de CVE-2026-7507.
- **H-07.6:** el mismo tag está dentro de CVE-2026-4634.
- **H-07.7:** la app de préstamos es DVWA, vulnerable por diseño.

Evidencia: `evidencias/CU-07/2026-10-26_CU-07_avisos-publicos.txt`.

---

## Resumen de hallazgos

| ID | Hallazgo | Severidad | Estado |
|---|---|---|---|
| H-00 | Detección caída tras redespliegue + acoplamiento DVWA↔agente (`set -e`) | Media | Documentado |
| H-04.1 | Keycloak con credencial admin por defecto (`admin`/`changeme`) | Alta | Confirmado |
| H-04.2 | Wazuh dashboard sin autenticación | Alta | Confirmado |
| H-EST-01 | Dockerfiles de los blancos corren como root (Trivy DS-0002; Semgrep `last-user-is-root`, `missing-user`, `missing-user-entrypoint`) | Alta | Confirmado, estático |
| H-EST-02 | Base de la app fijada en `vulnerables/web-dvwa:latest` (Trivy DS-0001) | Media | Confirmado, estático |
| H-EST-03 | Expansiones sin comillas en `configure-manager.sh` e `isolate-webapp.sh` (Semgrep) | Baja | Confirmado, estático |
| H-07.1 | Wazuh manager 4.9.0 dentro de CVE-2025-24016 | Crítica | Confirmado por versión |
| H-07.2 | API del manager 4.9.0 dentro de GHSA-gj9h-8hmr-xjjr | Alta | Confirmado por versión |
| H-07.3 | Dashboard 4.9.0 dentro de GHSA-648q-8m78-5cwv | Media | Confirmado por versión |
| H-07.4 | Keycloak `26.0` dentro de CVE-2026-18963 | Crítica | Confirmado por versión |
| H-07.5 | Keycloak `26.0` dentro de CVE-2026-7507 | Alta | Confirmado por versión |
| H-07.6 | Keycloak `26.0` dentro de CVE-2026-4634 | Alta | Confirmado por versión |
| H-07.7 | App de préstamos = DVWA, vulnerable a propósito | Alta | Por diseño |
| ... | _(se agregan a medida que avanzan los casos)_ | | |
