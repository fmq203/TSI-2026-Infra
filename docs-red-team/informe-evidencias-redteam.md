# Informe de evidencias — Red Team (Tarea 3)

> Documento de trabajo: una sección por **objetivo** (RT-01 a RT-12 de la letra) y por
> **análisis** (AE-01 estático, AE-02 avisos y dependencias). La evidencia va en
> `docs-red-team/evidencias/RT-0X/` o `.../AE-0X/`. Los hallazgos usan numeración corrida
> **`H-01` a `H-27`** (salta `H-22`, unificado en `H-05`); la columna *Objetivo* del inventario (§4 del
> [informe técnico](informe-red-team.md)) liga cada uno a su RT/AE. Las credenciales que
> figuran acá son **de laboratorio** (entorno aislado en VirtualBox).

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

### Hallazgo de entorno (H-25): la cadena de detección no sobrevive a un redespliegue

Al levantar el entorno desde cero, los agentes Wazuh (`webapp`, `ssh-client`) quedaron
**desenrolados** (el manager se recrea sin persistir las claves) y el contenedor `webapp`
entró en bucle de reinicio: su `entrypoint.sh` usa `set -e` y aborta todo el arranque
—incluida la app DVWA— si el enrolamiento del agente falla. Impacto: tras un redespliegue,
**la detección (RT-02/RT-03) queda caída hasta reenrolar manualmente**, y un acoplamiento
frágil hace que un fallo del SIEM tire abajo el servicio productivo (DVWA).

> Nota operativa: para que el laboratorio en VirtualBox fuera alcanzable hubo que activar
> modo promiscuo en las NIC de VLAN de `docker-host` (VirtualBox `allow-all` + `PROMISC`
> a nivel Linux, persistido con un servicio systemd). Es un detalle del entorno de
> pruebas, no una vulnerabilidad del blanco.

---

## RT-01 — Reconocimiento / escaneo de puertos

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
- **H-01 (defensa efectiva):** la segmentación impide que un puesto de Usuarios haga
  reconocimiento contra Servidores y la DMZ. El NIDS queda ciego a este escaneo porque
  nunca lo alcanza.
- **H-02 (observación de evasión):** el firewall responde distinto a SYN (drop) que a
  NULL/FIN (reject con RST). No permite llegar a la DMZ, pero la diferencia de respuesta
  permite a un atacante **inferir que hay un filtro con estado** delante.

### Parte B — Reconocimiento desde "Internet" (VLAN WAN) (2026-10-28)

**Posición:** Kali en VLAN WAN (`203.0.113.100`, 3ª placa `eth2`), como atacante externo.
Objetivo: escanear los puertos publicados de la DMZ para disparar las firmas de Suricata.

#### Comandos ejecutados
```bash
# Ruta: forzar que el tráfico a la DMZ salga por la WAN (ingresa como atacante externo)
sudo ip route add 10.10.20.0/24 via 203.0.113.254 dev eth2

# -Pn obligatorio: el firewall filtra el ICMP WAN→DMZ, así que nmap cree "host down"
sudo nmap -Pn -sN -p 25,587,993 10.10.20.50    # NULL
sudo nmap -Pn -sF -p 25,587,993 10.10.20.50    # FIN
sudo nmap -Pn -sS -p 25,587,993 10.10.20.50    # SYN
sudo nmap -Pn -sS -p 2222,2223 10.10.20.30     # honeypot Cowrie
```

#### Resultado
- **Suricata (`10.10.20.50`):** NULL/FIN/SYN → todos *closed* (RST). A diferencia de la
  Parte A (desde Usuarios), desde la WAN el tráfico **sí alcanza el sensor**: la posición
  externa está permitida contra los puertos publicados de la DMZ.
- **Honeypot (`10.10.20.30`):** `2222/tcp open` (Cowrie), `2223/tcp closed`.
- Primer intento sin `-Pn`: nmap abortó ("host seems down") porque el firewall filtra el
  ICMP de descubrimiento desde internet.

#### Respuesta del Blue Team observada
- **Suricata:** 15 eventos / **6 alertas** desde `203.0.113.100` (el `msg` de la firma, en
  `local.rules` del Blue Team, todavía dice "CU-01"):
  - SID **1000002** — "CU-01 Escaneo NULL detectado (nmap -sN)" (puertos 25/587/993).
  - SID **1000003** — "CU-01 Escaneo FIN detectado (nmap -sF)" (puertos 25/587/993).
- **Wazuh:** las 6 correlacionaron en la regla **100100, nivel 10** (sin bloqueo
  automático, es detección). Cadena completa: nmap → Suricata → Wazuh.
- El SYN scan no gatilló firma propia (la de SYN exige 20 SYN en 10 s; se escanearon 3
  puertos). El escaneo al honeypot `.30` no lo ve Suricata (solo observa tráfico a su
  propia IP `.50`); queda del lado de Cowrie.

#### Evidencia
`evidencias/RT-01/script-5.png` (intento sin `-Pn`), `script-6.png` (escaneos con `-Pn`).

#### Hallazgo / conclusión
- **H-03 (detección efectiva desde el exterior):** el reconocimiento stateless
  (NULL/FIN) de un atacante de internet contra la DMZ es detectado por Suricata y
  correlacionado por Wazuh (nivel 10). La cadena de detección de RT-01 funciona para la
  posición que el diseño espera (atacante externo), al contrario de la Parte A (interno),
  donde la segmentación corta el tráfico antes de llegar al sensor.
- **Nota de entorno:** al reencender el laboratorio, el servicio `macvlan-promisc.service`
  había quedado en `failed` (el `ExecStart` perdía la variable del loop), dejando los
  contenedores inalcanzables entre VLANs. Se reescribió con líneas `ExecStart` explícitas
  por interfaz y quedó `active` y persistente. Es la misma piedra del modo promiscuo ya
  vista antes.

---

## RT-02 — Fuerza bruta SSH

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
- `evidencias/RT-02/script1-wazuh.png` — Threat Hunting con 5760, 5763 y 651.
- `evidencias/RT-02/script2-kali terminal.jpg` — SSH desde Kali a `10.10.30.10:2222`,
  *connection timed out*.
- `evidencias/RT-02/2026-10-25_RT-02_deteccion-respuesta.txt` — línea de tiempo e
  `iptables`.

### Respuesta del Blue Team observada
| Hito | Hora local (dashboard) | Delta |
|---|---|---|
| Primer fallo (5503 / 5760) | 23:11:45.717 | — |
| Alerta 5763, nivel 10 | 23:11:48.721 | MTTD ~3 s |
| `firewall-drop` (651) | 23:11:51.726 | MTTR ~3 s |
| Mail en `soc@lab.local` | 23:12:04 | +15 s desde la alerta |

### Hallazgo / conclusión
El control de RT-02 funcionó de punta a punta: detección, bloqueo de la IP
atacante y aviso por mail. No hubo evasión. La regla que cortó fue **5763**
(usuario existente), no la 5712 (usuario inexistente).

---

## RT-03 — Webshell / inyección en la app de préstamos

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
- `evidencias/RT-03/01_file upload.jpg` — DVWA confirma la subida de `cu03-pablo.php`.
- `evidencias/RT-03/02_Wazuh evidencia rule 100200.png` — Threat Hunting, regla 100200
  nivel 12, agente `webapp`.
- `evidencias/RT-03/03_kali terminal curl.jpg` — `curl` desde Kali sin encabezado HTTP.
- `evidencias/RT-03/2026-10-25_RT-03_deteccion-respuesta.txt` — línea de tiempo,
  rutas del contenedor y el mail.

### Respuesta del Blue Team observada
| Hito | Hora local | Delta |
|---|---|---|
| Alerta 100200, nivel 12 | 23:45:21.056 | MTTD en el mismo segundo |
| `isolate-webapp` | 23:45:21 | MTTR ~0 s |
| Mail en `soc@lab.local` | 23:45:35 | +14 s desde la alerta |

### Hallazgo / conclusión
El control de RT-03 funcionó de punta a punta: el archivo `.php` nuevo en el webroot
disparó el FIM, el contenedor quedó aislado con el canal a Wazuh intacto, y el SOC
recibió el mail. No hubo evasión.

---

## RT-04 — Honeypot Cowrie

- **Objetivo de la letra (7.2):** interactuar con el honeypot y ver si se detecta y si se alerta.
- **Posición del atacante:** Kali, por la placa WAN, contra `10.10.20.30:2222`.
- **Resultado:** Cowrie aceptó la sesión. Wazuh no generó alerta.

Pablo, 28/10/2026. Desde Kali:

```bash
ssh -p 2222 -o ConnectTimeout=8 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=1 nosoy@10.10.20.30
```

El puerto aceptó la clave, mostró el aviso de Debian y un prompt `nosoy@svr04`. Se salió con `exit`. No se ejecutó ningún comando adentro.

En Threat Hunting, filtro `rule.id: 100110`, desde el 27/10 23:54 hasta el momento de la captura: «No results match your search criteria».

La regla `100110` (nivel 8) solo coincide con `cowrie.login.failed`. Este intento fue un ingreso aceptado, así que no entra en esa regla. El mail al SOC está configurado para nivel 10 o más: aunque un fallo disparara la 100110, no saldría correo.

### Evidencia
- `evidencias/RT-04/01_ssh connect.jpg` — sesión SSH aceptada y `exit`.
- `evidencias/RT-04/02_Threat Hunting.png` — regla 100110 sin resultados.
- `evidencias/RT-04/2026-10-28_RT-04_cowrie-sin-alerta.txt`

### Hallazgo / conclusión
**H-07 — El honeypot acepta la sesión y esa entrada no se alerta.** La trampa funciona: quien entra por el 2222 cae en Cowrie. La detección publicada solo mira el login fallido, y este ingreso fue aceptado. Severidad media. RT-04 queda cerrado con ese resultado.

---

## RT-05 — Exfiltración por DNS

- **Objetivo de la letra (7.2):** exfiltración simulada por DNS o TLS, y ver si el SIEM la correlaciona.
- **Caso de uso del Blue Team:** CU-05 de `docs/40-consigna-propia.md` (esta sección unifica lo que antes estaba partido entre CU-05 y RT-05).
- **Posición del atacante:** no aplica. No se generó tráfico y no se usó Kali.
- **Resultado:** no hay correlación implementada.

Pablo, 28/10/2026. En `docs/40-consigna-propia.md` el CU-05 del Blue Team espera que
Suricata o Wazuh marquen un volumen anómalo de DNS y avisen por un
segundo canal.

`infra/nids/rules/local.rules` no tiene firma de DNS ni de exfiltración.
Las reglas locales de Wazuh son la `100100` (escaneo), la `100110` (login
fallido en Cowrie) y la `100200` (PHP nuevo en el webroot). Suricata sigue
en `10.10.20.50` sin espejo del resto de la red (`docs/00-arquitectura.md`
§1.4): una consulta DNS hacia internet no pasa por el sensor. El segundo
canal de alerta fue recortado.

No se enviaron consultas. No habría alerta que medir.

### Evidencia
- `evidencias/RT-05/2026-10-28_RT-05_sin-correlacion-dns.txt`

### Hallazgo / conclusión
**H-08 — No hay correlación de exfiltración por DNS.** El control que el
caso de uso describe no está en las reglas ni en la visibilidad del sensor.
Severidad media. RT-05 queda cerrado sin ejecutar la prueba.

---

## RT-06 — Uso de credenciales por defecto / robadas (identidad)

- **Objetivo de la letra (7.2):** usar credenciales robadas o por defecto contra las consolas.
- **Objetivo (activos):** Keycloak (`10.10.90.20:8080`) y Wazuh dashboard (`10.10.90.12:5601`)
- **Posición del atacante:** navegador por túnel SSH / VLAN Gestión

### Hallazgos preliminares (2026-10-25)
- **H-04 — Keycloak con credencial de administrador por defecto:** acceso a la consola
  de administración del realm `master` con `admin` / `changeme`. Keycloak mismo advierte
  "You are logged in as a temporary admin user" (cuenta temporal sin endurecer).
  Evidencia: `evidencias/RT-06/`.
- **H-05 — Wazuh dashboard sin autenticación:** el dashboard abre sin login (plugin de
  seguridad de OpenSearch desactivado). Cualquiera con acceso de red a Gestión ve todas
  las alertas y la configuración del SIEM. Evidencia: `evidencias/RT-06/`. (El mismo hueco
  también es el objetivo de RT-10 y se cuenta una sola vez.)

### Respuesta del Blue Team observada (2026-10-28)
Consulta directa a la base de Keycloak (Postgres `identity-db`) y a la consola:

```sql
SELECT name, events_enabled, admin_events_enabled FROM realm;
-- master | f | f
SELECT count(*) FROM event_entity;        -- 0  (eventos de usuario/login)
SELECT count(*) FROM admin_event_entity;  -- 0  (eventos de administración)
```

- **Registro de eventos DESACTIVADO** en el realm `master` (`events_enabled = f`,
  `admin_events_enabled = f`) y **cero eventos** almacenados.
- En la consola, **Events → User events** muestra "No user events — There are no user
  events in this realm" (captura `evidencias/RT-06/events-keycloak.png`).
- El login con la credencial por defecto **no dejó rastro**: ni evento de login ni evento
  de administración. Keycloak tampoco reenvía logs a Wazuh, así que el SOC no lo ve.

### Hallazgo / conclusión
- **H-06 — Keycloak sin auditoría:** el IdP no registra eventos de login ni de
  administración (ambos deshabilitados, 0 filas). Un atacante con credenciales
  robadas/por defecto opera **sin dejar huella** y sin notificación al SOC.
- Contraste de MFA: el realm `lab` con TOTP que documentó el Blue Team **no existe** en
  este despliegue (RT-09, 27/10). La única consola que abre es `master`, con credencial
  por defecto y **sin segundo factor** (H-04).
- RT-06 queda **cerrado**: acceso con credencial por defecto (H-04) + consola SIEM sin
  login (H-05) + IdP sin MFA ni auditoría (H-06). No se hizo una prueba separada de
  credenciales robadas: el objetivo se cubre con el acceso por defecto observado y la
  exposición de ambas consolas. Severidad alta.

---

## RT-07 — Evasión del SIEM

- **Objetivo de la letra (7.2):** evasión del SIEM por inyección de logs o por abuso de las reglas.
- **Posición del atacante:** el repositorio público, más el intento ya hecho contra Cowrie. No se inyectó un log y no se usó Kali.
- **Resultado:** las reglas locales están publicadas y solo coinciden con una forma concreta. Lo que no tiene esa forma no alerta.

Pablo, 28/10/2026. `infra/siem-hids/config/wazuh_manager/local_rules.xml` está en el repo y `configure-manager.sh` lo copia al manager. Las tres reglas locales exigen un campo preciso:

| Regla | Nivel | Coincide solo si |
|---|---|---|
| `100100` | 10 | Suricata trae un `signature_id` `1000001`–`1000005` |
| `100110` | 8 | el JSON de Cowrie trae `eventid` = `cowrie.login.failed` |
| `100200` | 12 | el FIM ve un `.php` nuevo bajo `/var/www/html` |

El ruleset de serie sigue activo: el RT-02 alertó por las reglas estándar de SSH. Estas tres son el agregado del laboratorio, y la condición de cada una se puede leer sin entrar a la consola.

Eso ya se vio. En el RT-04 Cowrie aceptó la sesión y Threat Hunting con `rule.id: 100110` no devolvió nada, porque el evento no era un login fallido. En el RT-05 no existe una regla de DNS. No se armó un log falso: con el ingreso aceptado en el honeypot alcanza para mostrar el hueco.

### Evidencia
- `evidencias/RT-07/2026-10-28_RT-07_reglas-publicas.txt`
- `evidencias/RT-04/02_Threat Hunting.png` — la `100110` en cero después de una sesión aceptada.

### Hallazgo / conclusión
**H-09 — Las reglas locales son públicas y fáciles de no coincidir.** Quien lee el repo sabe qué evento entra en cada una. Una sesión aceptada por Cowrie ya pasó sin alerta. Severidad media. RT-07 queda cerrado sin inyectar logs.

---

## RT-08 — Ataque a Wazo

- **Objetivo de la letra (7.2):** extensiones falsas, exploit de IVR o enumeración de Wazo.
- **Posición del atacante:** no aplica. No se usó Kali.
- **Resultado:** el objetivo no es ejecutable. Wazo no está desplegado.

El 05/10/2026 el docente habilitó recortar alcance. El Blue Team dejó Wazo
afuera (`brain/decisions.md`, entrada de esa fecha; `README.md`). En
`docs/00-arquitectura.md` la IP `10.10.20.40` figura reservada y el
contenedor como no construido.

Pablo, 27/10/2026, con las VMs encendidas. `docker ps` en `docker-host` no
muestra un contenedor de Wazo. Desde el router, `ping -c 2 -W 2 10.10.20.40`
dio 2 paquetes enviados y 0 respuestas. No hay central, extensiones ni IVR.

El firewall publica UDP 5060 de la WAN hacia la DMZ, el puerto previsto para
Wazo. No hay proceso del otro lado.

### Evidencia
- `evidencias/RT-08/2026-10-27_RT-08_wazo-ausente.txt`

### Hallazgo / conclusión
**H-20 — Wazo ausente.** El canal de telefonía de la letra no está en el
laboratorio. RT-08 queda cerrado por ausencia del activo, no por un ataque
contenido. Severidad informativa: no hay servicio que comprometer.

---

## RT-09 — MFA administrativo

- **Objetivo de la letra (7.2):** saltear el MFA de la administración.
- **Posición del atacante:** navegador de Windows por túnel SSH. No se usó Kali.
- **Resultado:** no hay un segundo factor que saltear en este despliegue.

Pablo, 27/10/2026. El Blue Team documentó TOTP en el realm `lab`, usuario
`admin-lab`. En esta copia el realm no está importado: el `docker-compose`
de `infra/identity/` no lo carga, y la base de Keycloak tiene una sola fila
en `realm`, `master`.

`http://localhost:8080/realms/lab/account/` responde «We are sorry… Page not
found». La consola de administración, abierta con la sesión de `admin`,
muestra en el selector únicamente `master`. No pidió código de autenticador.
Los roles de esa pantalla son los de `master` (`admin`, `create-realm`,
`default-roles-master`, `offline_access`, `uma_authorization`).

`http://localhost:5601` abre la home de OpenSearch Dashboards sin formulario
de login. Es el mismo hueco que H-05. La cuenta `admin` de `master` es H-04.

### Evidencia
- `evidencias/RT-09/01_lab account - not found.jpg` — cuenta del realm `lab`, página inexistente.
- `evidencias/RT-09/02_lista de realms.jpg` — selector con solo `master`, sesión `admin`.
- `evidencias/RT-09/03_Wazuh sin login.png` — home del dashboard sin login.
- `evidencias/RT-09/2026-10-27_RT-09_mfa-ausente.txt`

### Hallazgo / conclusión
**H-21 — MFA administrativo ausente en este despliegue.** El único lugar
donde estaba documentado el TOTP no existe acá. La consola de identidades
entra solo con contraseña y la consola del SIEM no pide usuario. RT-09 queda
cerrado: el control no se saltea porque no está aplicado. Severidad alta,
junto con H-04 y H-05.

---

## RT-10 — Consola del SIEM

- **Objetivo de la letra (7.2):** compromiso del servidor SIEM/SOAR, si se llega, y su impacto.
- **Posición del atacante:** navegador de Windows por túnel SSH a `10.10.90.12:5601`.
  El firewall no publica ese puerto hacia la WAN. No se usó Kali.
- **Resultado:** la consola abre sin usuario y deja leer agentes y alertas.

Pablo, 27/10/2026. `http://localhost:5601/app/wazuh` respondió «Application
Not Found». La home que carga es `http://localhost:5601/app/home`, OpenSearch
Dashboards, sin formulario de login. Desde el menú de la W se abre la
aplicación.

En **Endpoints**, con filtro de activos, hay dos agentes en `active`:

| ID | Nombre | IP | Sistema | Versión |
|---|---|---|---|---|
| 002 | `ssh-client` | `10.10.30.10` | Debian 12 | 4.9.0 |
| 003 | `0d6d5a812295` | `10.10.10.10` | Debian 9 | 4.9.0 |

El gráfico suma un tercero desconectado, que queda fuera de ese filtro.
La pantalla muestra **Deploy new agent**. No se enroló ninguno.

**Threat Hunting**, del 24/10 23:54 al 27/10 23:54: 234 eventos, 1 de nivel
12 o más, 16 fallos de autenticación y ninguna autenticación exitosa. El
resumen MITRE incluye Brute Force y Web Shell. La primera página de la
tabla son arranques de agente, anomalías de host y benchmarks CIS.

TheHive no está en el laboratorio. El SOAR es el Active Response de Wazuh
y se maneja desde esta consola. No se cambió ninguna regla y no hubo shell
en el manager.

### Evidencia
- `evidencias/RT-10/01_Wazuh home.png` — `/app/home` sin login.
- `evidencias/RT-10/02_listado de agentes.png` — dos agentes activos, con IP.
- `evidencias/RT-10/03_Threat Hunting.png` — 234 eventos, incluido nivel 12.
- `evidencias/RT-10/2026-10-27_RT-10_consola-siem.txt`

### Hallazgo / conclusión
**La consola del SIEM se lee sin autenticación — es el mismo hallazgo que H-05, no se cuenta aparte.** Quien llega a la
VLAN de Gestión ve el inventario de la detección y el historial de alertas,
incluidos los casos de fuerza bruta y de webshell. Es el mismo hueco que H-05.
Severidad alta. RT-10 queda cerrado en ese alcance: se llegó a la consola,
no al sistema operativo del manager.

---

## RT-11 — DoS acotado

- **Objetivo de la letra (7.2):** DoS acotado contra un servicio no crítico, para probar la respuesta del monitoreo.
- **Posición del atacante:** no aplica. No se generó tráfico y no se usó Kali.
- **Resultado:** no hay un control que pueda registrar esa prueba.

Pablo, 27/10/2026, revisión de las reglas del laboratorio.
`infra/nids/rules/local.rules` no define una firma de denegación de
servicio. Lo único por volumen es RT-01: el SID `1000001` alerta 20 SYN en
10 segundos desde el mismo origen, y el SID `1000005` alerta 10 ICMP
echo-request en 5 segundos. Las dos apuntan a `$HOME_NET`.

Suricata escucha en `10.10.20.50`. En `docs/00-arquitectura.md` §1.4 el
espejo del router hacia el NIDS, más allá de la IP del propio sensor, sigue
pendiente. Un DoS contra Cowrie, el mail o la app no pasa por ese punto.
Wazuh no agrega una regla de DoS encima de eso.

No se envió tráfico de carga. No habría alerta que medir, y el manager, el
router y la app quedan fuera de cualquier prueba de este tipo.

### Evidencia
- `evidencias/RT-11/2026-10-27_RT-11_sin-deteccion-dos.txt`

### Hallazgo / conclusión
**H-23 — No hay detección de DoS.** El monitoreo que el objetivo pide
ejercitar no está. La regla por volumen más cercana es un detector de
escaneo y solo cubre el tráfico que llega al sensor. Severidad media.
RT-11 queda cerrado sin ejecutar la prueba.

---

## RT-12 — OSINT del repositorio

- **Objetivo de la letra (7.2):** buscar secretos y credenciales en el repositorio.
- **Posición del atacante:** clon local y el historial de git. No se usó Kali.
- **Resultado:** no hay claves privadas ni `.env` en el historial. Las contraseñas de arranque están en el árbol público.

Pablo, 28/10/2026. `git log --all` sobre `*.env`, `*.key`, `*.pem`, `*id_rsa*` y `*.p12` no devuelve commits. En `infra/identity/certs/` solo entraron, en `40364c8`, el certificado `auth.lab.local.crt`, su `.ext` y `lab-ca.crt`. `.gitignore` deja afuera `.env`, `infra/*/ssl/` y los `config.xml` de OPNsense.

El `Makefile` de `infra/` copia cada `.env.example` a `.env` cuando ese archivo no existe. Esos ejemplos están versionados:

- `infra/identity/.env.example`: admin y base de Keycloak en `changeme` (el mismo valor de H-04).
- `infra/mail/.env.example`: clave del buzón `soc@lab.local` en `changeme`.
- `infra/targets/.env.example`: root de la base y la clave débil de `labuser`.
- `infra/siem-hids/.env.example`: `WAZUH_API_PASSWORD` con un valor fijo. En un despliegue nuevo esa es la clave de la API.

`README.md` publica `admin` / `changeme`, la clave de `labuser` y `admin-lab` / `Prueba123`. `vagrant/README.md` repite la de Keycloak. Los scanners de AE-01 no marcaron estas cadenas: están escritas como valores de ejemplo.

### Evidencia
- `evidencias/RT-12/2026-10-28_RT-12_osint-repo.txt`

### Hallazgo / conclusión
**H-24 — El repo público trae las contraseñas con las que arranca el laboratorio.** No se filtró material criptográfico privado. Quien lee el repositorio obtiene las cuentas de Keycloak, del SSH de prueba, del mail del SOC y de la API de Wazuh, y `make up` las deja operativas. Severidad alta. RT-12 queda cerrado.

---

## AE-01 — Inspección estática del repositorio

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
- **H-10:** las imágenes de los blancos se construyen como root. Un proceso
  que salga del servicio dentro del contenedor hereda ese usuario.
- **H-11:** la app de préstamos parte de `vulnerables/web-dvwa:latest`. El
  tag no queda fijo y la base es una aplicación vulnerable a propósito.
- El scanner de secretos no aporta un hallazgo nuevo respecto de las claves de
  laboratorio ya anotadas en RT-06.

Evidencia: `evidencias/AE-01/trivy-fs.txt` y `evidencias/AE-01/trivy-fs.json`.

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
- Los tres ERROR de Dockerfile son el mismo punto que **H-10** (Parte A,
  Trivy DS-0002): las imágenes de los blancos quedan como root.
- **H-12:** `configure-manager.sh` e `isolate-webapp.sh` expanden variables
  sin comillas. Severidad info de la regla; impacto bajo con los valores
  actuales.
- Secretos: nada nuevo respecto de las claves de laboratorio ya anotadas en
  RT-06.

Evidencia: `evidencias/AE-01/semgrep.txt` y `evidencias/AE-01/semgrep.json`.

---

## AE-02 — Avisos públicos y auditoría de dependencias

Contraste de la versión que declara el repo con avisos públicos. No hubo
tráfico contra el laboratorio ni `docker pull`. Un tag móvil (`latest`,
`16-alpine`, `8.0`) no alcanza para afirmar un CVE: el parche que bajaría
hoy puede ser otro.

### Versiones fijas (2026-10-26)

| Producto | Versión en el repo | Aviso | Severidad | Qué implica |
|---|---|---|---|---|
| Wazuh manager | 4.9.0 | CVE-2025-24016 | Crítica (9.9) | Deserialización insegura. Quien tenga acceso a la API, o en ciertas configuraciones un agente comprometido, puede ejecutar código en el manager. Corregido en 4.9.1. El 9.0 que figuraba antes no es el base del aviso: el vector del CNA es 9.9. |
| Wazuh manager | 4.9.0 | GHSA-gj9h-8hmr-xjjr | Alta | Un usuario autenticado con el rol `users_admin` puede cambiar la contraseña de las cuentas de administrador reservadas. El aviso incluye 4.9.0; el arreglo de esa línea es 4.10.4 |
| Wazuh dashboard | 4.9.0 | GHSA-648q-8m78-5cwv | Media (4.6) | Un usuario con pocos privilegios puede ver el listado de agentes. Corregido en 4.9.1. En este laboratorio el dashboard ya abre sin login (H-05) |
| Keycloak | tag `26.0` | CVE-2026-18963 | Crítica (9.1) | Toma de cuenta sin autenticación por el flujo de recuperación de contraseña. La línea 26.0 no tiene parche (el arreglo está en 26.4.15, 26.6.6 o 26.7.2) |
| Keycloak | tag `26.0` | CVE-2026-7507 | Alta (7.5) | Fijación de sesión en el login OIDC. Pide que la víctima abra un enlace y puede terminar en toma de cuenta. Corregido en 26.6.2 |
| Keycloak | tag `26.0` | CVE-2026-4634 | Alta (7.5) | Denegación de servicio no autenticada en el endpoint OIDC de tokens. Corregido en 26.5.7 |

El tag `quay.io/keycloak/keycloak:26.0` no fija el parche. Un índice público
del 23/10/2026 lo resolvió a 26.0.8, que sigue dentro de esos tres rangos.
26.0 ya no recibe parches.

El aviso del manager pide acceso a la API. En este laboratorio esa clave está
en el ejemplo y el dashboard no autentica (H-05).

### Producto vulnerable a propósito

**H-19 — DVWA.** `vulnerables/web-dvwa:latest` es la app de préstamos. El
proyecto publica a propósito inyección SQL, XSS, subida de archivos, inyección
de comandos y CSRF, según el nivel de seguridad. No es un CVE sobre una
versión atrasada: es el blanco del ejercicio. RT-03 ya mostró la subida de un
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

### Hallazgo / conclusión (avisos)

- **H-13:** el manager Wazuh 4.9.0 está dentro de CVE-2025-24016.
- **H-14:** la API de ese mismo manager está dentro de GHSA-gj9h-8hmr-xjjr.
- **H-15:** el dashboard 4.9.0 está dentro de GHSA-648q-8m78-5cwv. El efecto
  práctico ya lo cubre H-05.
- **H-16:** Keycloak `26.0` está dentro de CVE-2026-18963.
- **H-17:** el mismo tag está dentro de CVE-2026-7507.
- **H-18:** el mismo tag está dentro de CVE-2026-4634.
- **H-19:** la app de préstamos es DVWA, vulnerable por diseño.

Evidencia: `evidencias/AE-02/2026-10-26_AE-02_avisos-publicos.txt`.

### Auditoría de dependencias (2026-10-31)

Análisis documental de versiones declaradas en `infra/`, cotejadas con NVD, avisos
oficiales de Wazuh/GitHub e información de soporte de Debian. Complementa el contraste de
avisos de arriba; donde los identificadores difieren, el inventario de hallazgos (§4 del
informe técnico) usa los avisos listados en la tabla de "Versiones fijas".

- Wazuh Manager `4.9.0` queda dentro de los rangos de CVE-2025-24016 (crítica, 9.9 = H-13)
  y de CVE-2026-41424 (alta, 8.2), que corresponde a GHSA-gj9h-8hmr-xjjr = **H-14**. Wazuh
  Dashboard `4.9.0` queda dentro de CVE-2025-64483 (media) = **H-26**.
- El Dockerfile de `web-victim` configura repositorios Debian Stretch en HTTP con
  `trusted=yes` (líneas 6-7) y `--allow-unauthenticated` (líneas 10 y 15). Stretch
  terminó su soporte LTS en 2022; se registra como riesgo de mantenimiento e integridad
  de la construcción (**H-27**), sin atribuir un CVE a paquetes cuya versión no se pudo
  resolver.
- Las imágenes no se escanearon: el daemon Docker no estaba disponible y no se obtuvo
  un SBOM. Los tags mutables (entre ellos `latest`) no permiten determinar qué build está
  desplegado. El detalle, las ubicaciones, las condiciones de explotación y las fuentes
  están en [la evidencia](evidencias/AE-02/2026-10-31_AE-02_auditoria-dependencias.md).

---

## Resumen de hallazgos

Numeración corrida. La columna *Objetivo* liga cada hallazgo a su objetivo RT (letra) o
análisis AE. El inventario con CVSS y MITRE está en la §4 del
[informe técnico](informe-red-team.md).

**26 IDs en total** (H-01 a H-27, sin H-22, que se unificó en H-05): **23 contados** por
severidad (2 críticos, 11 altos, 8 medios, 1 bajo, 1 informativo) y **3 observaciones**
(H-01, H-02, H-03). De los 26, **25 tienen carpeta de evidencia**; H-25 (transversal) va en
la §0 de arriba.

> **Nota:** varios hallazgos tocan el **mismo componente** pero son distintos. El dashboard
> de Wazuh: H-05 (sin autenticación, demostrado) + H-15 y H-26 (dos avisos por versión cuyo
> efecto ya cubre H-05 en la práctica). Keycloak 26.0: H-16, H-17, H-18 (tres CVE distintos).
> No son repetidos: cada ID es un aviso o una debilidad diferente.

| ID | Hallazgo | Objetivo | Severidad | Estado |
|---|---|---|---|---|
| H-01 | Segmentación bloquea el recon Usuarios→DMZ/Servidores (Suricata ciego a ese escaneo) | RT-01 | Informativa (control) | Confirmado 25/10 |
| H-02 | El firewall responde distinto a SYN (drop) vs NULL/FIN (reject) → revela filtro con estado | RT-01 | Baja (obs.) | Confirmado 25/10 |
| H-03 | Recon externo (NULL/FIN) a la DMZ detectado por Suricata (SID 1000002/1000003) → Wazuh regla 100100 nivel 10 | RT-01 | Informativa (control) | Confirmado 28/10 |
| H-04 | Keycloak con credencial admin por defecto (`admin`/`changeme`) | RT-06 | Alta | Confirmado |
| H-05 | Wazuh dashboard sin autenticación | RT-06 / RT-10 | Alta | Confirmado |
| H-06 | Keycloak sin auditoría: eventos de login y admin deshabilitados (0 registros) | RT-06 | Alta | Cerrado 28/10 |
| H-07 | Cowrie acepta el SSH y la regla 100110 (solo login fallido) no alerta | RT-04 | Media | Cerrado 28/10 |
| H-08 | No hay correlación de exfiltración por DNS | RT-05 | Media | Cerrado 28/10 |
| H-09 | Reglas locales públicas y de coincidencia estrecha: un login aceptado en Cowrie no alerta | RT-07 | Media | Cerrado 28/10 |
| H-10 | Dockerfiles de los blancos corren como root (Trivy DS-0002; Semgrep `last-user-is-root`, `missing-user`, `missing-user-entrypoint`) | AE-01 | Alta | Confirmado, estático |
| H-11 | Base de la app fijada en `vulnerables/web-dvwa:latest` (Trivy DS-0001) | AE-01 | Media | Confirmado, estático |
| H-12 | Expansiones sin comillas en `configure-manager.sh` e `isolate-webapp.sh` (Semgrep) | AE-01 | Baja | Confirmado, estático |
| H-13 | Wazuh manager 4.9.0 dentro de CVE-2025-24016 | AE-02 | Crítica | Confirmado por versión |
| H-14 | API del manager 4.9.0 dentro de GHSA-gj9h-8hmr-xjjr | AE-02 | Alta | Confirmado por versión |
| H-15 | Dashboard 4.9.0 dentro de GHSA-648q-8m78-5cwv | AE-02 | Media | Confirmado por versión |
| H-16 | Keycloak `26.0` dentro de CVE-2026-18963 | AE-02 | Crítica | Confirmado por versión |
| H-17 | Keycloak `26.0` dentro de CVE-2026-7507 | AE-02 | Alta | Confirmado por versión |
| H-18 | Keycloak `26.0` dentro de CVE-2026-4634 | AE-02 | Alta | Confirmado por versión |
| H-19 | App de préstamos = DVWA, vulnerable a propósito | AE-02 | Alta | Por diseño |
| H-26 | Wazuh dashboard 4.9.0 dentro de CVE-2025-64483 (credenciales de enrolamiento) | AE-02 | Media | Confirmado por versión |
| H-27 | web-victim sobre Debian Stretch (EOL) con repos APT sin autenticar | AE-02 | Alta | Confirmado, estático |
| H-20 | Wazo no desplegado; RT-08 no ejecutable | RT-08 | Informativa | Cerrado 27/10 |
| H-21 | MFA administrativo ausente: no existe el realm `lab` y las consolas no piden segundo factor | RT-09 | Alta | Cerrado 27/10 |
| H-23 | No hay regla de DoS; Suricata solo alerta volumen de escaneo hacia su propio alcance | RT-11 | Media | Cerrado 27/10 |
| H-24 | El repo público trae las contraseñas de arranque (Keycloak, SSH, mail, API de Wazuh) | RT-12 | Alta | Cerrado 28/10 |
| H-25 | Detección caída tras redespliegue + acoplamiento DVWA↔agente (`set -e`) | Transversal | Media | Documentado |
