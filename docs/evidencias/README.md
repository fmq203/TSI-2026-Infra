# Evidencias — kit de captura

> Esta carpeta guarda la **evidencia real** de la cadena detección → respuesta →
> notificación, que es lo que el auditor pide ver (LETRA.md §6.6) y lo que referencian
> `04-gestion-incidentes.md`, `07-monitoreo-logs.md` y el Excel de controles.
>
> Al 11/10/2026 ya se habían validado y documentado **CU-01**, **CU-02** y **CU-03** con
> evidencia real de detección y respuesta. El 14/10/2026 se cerró el eslabón que faltaba
> en los tres — la **notificación por mail** —, bloqueada por una combinación de causas
> de red/config: regla de firewall Gestión→DMZ puerto 25, filtro anti-spam del
> mailserver (`mynetworks`), y en CU-03 además el agente `webapp` había dejado de estar
> activo y la regla local 100200 nunca se había sincronizado al manager en vivo (detalle
> completo en `brain/LEARNINGS.md` 2026-10-14). Con las tres causas corregidas, **CU-02 y
> CU-03 quedan verificados de punta a punta** (detección → respuesta automática → mail
> en `soc@lab.local`), con MTTD/MTTR reales medidos en ambos. CU-01 (Nmap → Suricata →
> Wazuh) sigue verificado en detección (no tiene contención automática por diseño).
> Las capturas generadas se detallan en el índice de evidencias al final de este archivo.

## Convención de nombres

`AAAA-MM-DD_CU-0X_descripcion.ext` — fecha de la captura, caso de uso y qué muestra.
Capturas de pantalla en `.png`; volcados de consola en `.txt`; correos en `.eml` o `.png`.

## Antes de empezar: estado del entorno (una sola vez por sesión)

| # | Qué probar | Comando (en `docker-host`: `vagrant ssh docker-host`, luego `sudo -i`) | Archivo |
|---|---|---|---|
| E0 | Todos los contenedores arriba | `docker ps --format 'table {{.Names}}\t{{.Status}}'` | `AAAA-MM-DD_E0_docker-ps.txt` |
| E0 | Agente del host víctima enrolado | `docker exec wazuh.manager /var/ossec/bin/agent_control -l` | `AAAA-MM-DD_E0_agentes.txt` |
| E0 | Índice de alertas vivo | `docker exec wazuh.manager curl -s "http://wazuh.indexer:9200/_cat/indices/wazuh-alerts*?v"` | `AAAA-MM-DD_E0_indices.txt` |

> Ojo (macvlan): `docker-host` no habla con sus propios contenedores. Al dashboard de
> Wazuh (`http://10.10.90.12:5601`) se entra desde el router o desde otra VM; en
> VirtualBox, con un túnel SSH (`../../vagrant/README.md` → "Cómo entrar a las consolas").

---

## CU-01 — Reconocimiento contra la DMZ (INC-2026-001) ✅ VERIFICADO

**Cadena validada:** escaneo SYN → Suricata (SID 1000001) → Wazuh (regla 100100, nivel 10).

### 1. Prueba ejecutada

Desde la VM `router` se verificó primero la conectividad contra la DMZ:

```bash
ping -c 20 -i 0.2 10.10.20.50
```

Luego se ejecutó el reconocimiento:

```bash
sudo nmap -sS -p 1-1000 10.10.20.50
```

Resultado: el host `10.10.20.50` respondió como activo y se completó el barrido SYN sobre los primeros 1000 puertos TCP.

### 2. Detección en Suricata

Se verificó la generación de alertas en `eve.json` con las firmas propias de CU-01:

```bash
docker run --rm -v nids_suricata_logs:/logs:ro alpine \
  sh -c 'grep -E "\"signature_id\":100000[1-5]" /logs/eve.json | tail -10'
```

Se observó:

- `signature_id`: `1000001`
- Firma: `CU-01 Posible escaneo de puertos TCP (muchos SYN por origen)`
- `src_ip`: `10.10.20.254`
- `dest_ip`: `10.10.20.50`

### 3. Correlación en Wazuh

Se comprobó que Wazuh procesó las alertas de Suricata:

```bash
docker exec wazuh.manager grep '"id":"100100"' \
  /var/ossec/logs/alerts/alerts.json | tail -5
```

Resultado observado:

- Regla Wazuh: `100100`
- Nivel: `10`
- Grupo: `suricata`
- Descripción asociada a CU-01
- MITRE ATT&CK: reconocimiento / Network Service Discovery

### 4. Evidencia capturada

- `01_ping_conectividad_dmz.png`
- `02_reconocimiento_nmap_dmz.png`
- `03_suricata_sid_1000001.png`
- `04_wazuh_regla_100100.png`

**Estado CU-01:** COMPLETADO Y VERIFICADO.

---|---|---|---|
| 1 | Suricata generó la alerta | `docker exec suricata grep '"event_type":"alert"' /var/log/suricata/eve.json \| tail -5` | `AAAA-MM-DD_CU-01_suricata-eve.txt` |
| 2 | Wazuh la procesó (regla 100100) | `docker exec wazuh.manager grep '100100' /var/ossec/logs/alerts/alerts.json \| tail -3` | `AAAA-MM-DD_CU-01_wazuh-alertjson.txt` |
| 3 | **Alerta en el dashboard** | Threat Hunting, filtro `rule.id:100100` (o `data.alert.signature_id:1000*`). Mostrar fecha, `src_ip`, descripción y MITRE T1046 | `AAAA-MM-DD_CU-01_dashboard.png` |
| 4 | Notificación | Mail recibido en `soc@lab.local` (si CU-01 llega a nivel 10) | `AAAA-MM-DD_CU-01_mail.png` |

### 3. Completar en los documentos

- `04-gestion-incidentes.md` INC-2026-001: hora exacta, `src_ip` y rutas de estos archivos.
- `07-monitoreo-logs.md` §6: MTTD = hora de la alerta − hora del ataque.

---

## CU-02 — Fuerza bruta SSH + respuesta automática (INC-2026-002) ✅ VERIFICADO

**Cadena validada:** intentos SSH fallidos → agente Wazuh → regla 5712 → Active Response `firewall-drop` → bloqueo de la IP atacante.

### 1. Agente Wazuh

Se desplegó el `ssh-client` con la imagen propia:

```text
tsi/ssh-victim:4.9.0
```

El contenedor incluye OpenSSH y el agente Wazuh embebido.

Se verificó el enrolamiento:

```bash
docker exec wazuh.manager /var/ossec/bin/agent_control -l
```

Resultado:

```text
ID: 002, Name: ssh-client, IP: any, Active
```

También quedaron activos FIM, SCA y rootcheck.

### 2. Active Response configurado

Se confirmó en `/var/ossec/etc/ossec.conf`:

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5712,5763</rules_id>
  <timeout>600</timeout>
</active-response>
```

### 3. Prueba de fuerza bruta controlada

Para no bloquear el gateway del laboratorio se utilizó un contenedor atacante temporal con IP `10.10.30.50`.

Desde ese contenedor se realizaron múltiples intentos fallidos contra:

```text
10.10.30.10:2222
```

La detección se verificó con:

```bash
docker exec wazuh.manager grep -E '"id":"(5712|5763)"' \
  /var/ossec/logs/alerts/alerts.json | tail -10
```

Wazuh generó la regla:

- `5712`
- Nivel `10`
- Descripción: `sshd: brute force trying to get access to the system. Non existent user.`
- IP origen: `10.10.30.50`

### 4. Respuesta automática

En el agente víctima se verificó:

```bash
docker exec target-ssh-client tail -30 /var/ossec/logs/active-responses.log
```

Se observó la ejecución de:

```text
active-response/bin/firewall-drop
```

sobre la IP atacante `10.10.30.50`.

Luego se repitió una conexión SSH desde el atacante:

```bash
ssh -o ConnectTimeout=3 -p 2222 usuariofalso@10.10.30.10
```

Resultado:

```text
ssh: connect to host 10.10.30.10 port 2222: Connection timed out
```

Esto confirmó que el bloqueo fue aplicado correctamente durante el período configurado de 600 segundos.

### 5. Evidencia capturada

- `01_alerta_wazuh_regla_5712.png`
- `02_active_response_firewall_drop.png`
- `03_bloqueo_ssh_timeout.png`

**Estado CU-02:** COMPLETADO Y VERIFICADO.

---|---|---|---|
| 1 | Detección (regla 5763/5712) | `docker exec wazuh.manager grep -E '"id":"(5763\|5712)"' /var/ossec/logs/alerts/alerts.json \| tail -2` | `AAAA-MM-DD_CU-02_deteccion.txt` |
| 2 | **Respuesta** — IP bloqueada | `docker exec target-ssh-client iptables -L INPUT -n` (muestra el DROP) | `AAAA-MM-DD_CU-02_iptables.txt` |
| 3 | Log del Active Response | `docker exec target-ssh-client tail /var/ossec/logs/active-responses.log` | `AAAA-MM-DD_CU-02_active-response.txt` |
| 4 | **Dashboard** | Threat Hunting: `rule.id:5763` y `rule.id:651` ("Host Blocked by firewall-drop") | `AAAA-MM-DD_CU-02_dashboard.png` |
| 5 | Notificación | Mail en `soc@lab.local` | `AAAA-MM-DD_CU-02_mail.png` |

### 3. Completar en los documentos

- `04-gestion-incidentes.md` INC-2026-002: pasar a estado **Cerrado**, con hora, `src_ip`
  y las rutas; es la detección→respuesta→notificación de extremo a extremo obligatoria
  de la auditoría (LETRA.md §6.6).
- `07-monitoreo-logs.md` §6 y Excel de controles: marcar CU-02 como verificado; MTTR.

---

## CU-03 — Webshell + FIM + aislamiento automático (INC-2026-003) ✅ VERIFICADO

**Cadena validada:** archivo PHP agregado al webroot → FIM (`syscheck`) → regla base 554 → regla local CU-03 `100200` (nivel 12) → Active Response `isolate-webapp` → aislamiento del servidor web manteniendo comunicación con Wazuh por TCP 1514.

### 1. Agente Wazuh y FIM sobre el webroot

Se agregó un agente Wazuh al contenedor `target-webapp` y se verificó su enrolamiento:

```bash
docker exec wazuh.manager /var/ossec/bin/agent_control -l
```

Resultado:

```text
ID: 003, Name: webapp, IP: any, Active
```

El agente quedó configurado para monitorear en tiempo real el webroot:

```xml
<directories realtime="yes" check_all="yes">/var/www/html</directories>
```

Esto permitió detectar altas y modificaciones de archivos dentro de la aplicación.

### 2. Prueba de detección FIM

Se creó un archivo PHP de prueba dentro del webroot:

```bash
docker exec target-webapp bash -c 'echo "<?php echo \"CU03 AISLAMIENTO\"; ?>" > /var/www/html/cu03-isolation-test.php'
```

La detección inicial de FIM se realizó mediante la regla estándar:

- Regla base: `554`
- Descripción: `File added to the system.`
- Agente: `webapp`
- Ruta: `/var/www/html/cu03-isolation-test.php`

### 3. Regla local específica CU-03

Se agregó una regla local para elevar los archivos PHP agregados al webroot:

```xml
<group name="local,syscheck,cu03,">
  <rule id="100200" level="12">
    <if_sid>554</if_sid>
    <field name="file" type="pcre2">^/var/www/html/.*\.php$</field>
    <description>CU-03 Webshell: archivo PHP agregado al webroot: $(file)</description>
    <mitre>
      <id>T1505.003</id>
    </mitre>
  </rule>
</group>
```

La alerta resultante mostró:

- Regla Wazuh: `100200`
- Nivel: `12`
- Agente: `webapp`
- IP: `10.10.10.10`
- Archivo detectado: `/var/www/html/cu03-isolation-test.php`
- MITRE ATT&CK: `T1505.003` Web Shell

### 4. Active Response de aislamiento

Se creó el script:

```text
/var/ossec/active-response/bin/isolate-webapp
```

y se configuró en el manager:

```xml
<command>
  <name>isolate-webapp</name>
  <executable>isolate-webapp</executable>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <command>isolate-webapp</command>
  <location>local</location>
  <rules_id>100200</rules_id>
  <timeout>600</timeout>
</active-response>
```

Al dispararse la regla `100200`, el Active Response ejecutó:

```text
CU03 isolate-webapp: Starting isolation
CU03 isolate-webapp: Webapp isolated, Wazuh access preserved
```

### 5. Verificación del aislamiento

Después de la respuesta automática se verificó la tabla de rutas del `target-webapp`:

```bash
docker exec target-webapp ip route
```

La ruta por defecto fue eliminada y se mantuvo únicamente:

```text
10.10.10.0/24 dev eth0 ...
10.10.90.10 via 10.10.10.254 dev eth0
```

Esto dejó al servidor web aislado del resto de las redes pero conservando una ruta específica hacia el Wazuh Manager.

También se comprobó el aislamiento intentando llegar a la DMZ:

```bash
docker exec target-webapp ping -c 2 -W 2 10.10.20.50
```

Resultado:

```text
ping: sendto: Network is unreachable
```

### 6. Comunicación con Wazuh preservada

Se verificó directamente el puerto TCP 1514 hacia el manager:

```bash
docker exec target-webapp bash -c 'echo > /dev/tcp/10.10.90.10/1514 && echo "WAZUH 1514 OK" || echo "WAZUH 1514 NO"'
```

Resultado:

```text
WAZUH 1514 OK
```

Además, el agente continuó figurando como:

```text
ID: 003, Name: webapp, IP: any, Active
```

Por lo tanto, el aislamiento no impidió que el servidor siguiera reportando al SIEM.

### 7. Evidencia capturada

- `01_fim_configurado_webroot.png`
- `02_fim_detecta_archivo_php.png`
- `03_regla_cu03_100200_nivel12.png`
- `04_agente_webapp_y_script_aislamiento.png`
- `05_active_response_cu03_configurado.png`
- `06_alerta_final_cu03.png`
- `07_active_response_aislamiento.png`
- `08_rutas_webapp_aislado.png`
- `09_agente_webapp_activo_durante_aislamiento.png`
- `10_wazuh_1514_preservado.png`

**Estado CU-03:** COMPLETADO Y VERIFICADO.

---

## Índice de evidencias

| Archivo | Caso | Qué prueba | Fecha captura |
|---|---|---|---|
| `01_ping_conectividad_dmz.png` | CU-01 | Conectividad desde router hacia `10.10.20.50` | 11/10/2026 |
| `02_reconocimiento_nmap_dmz.png` | CU-01 | Escaneo SYN con Nmap contra la DMZ | 11/10/2026 |
| `03_suricata_sid_1000001.png` | CU-01 | Suricata detecta el escaneo con SID `1000001` | 11/10/2026 |
| `04_wazuh_regla_100100.png` | CU-01 | Wazuh correlaciona la alerta con regla `100100` nivel 10 | 11/10/2026 |
| `01_alerta_wazuh_regla_5712.png` | CU-02 | Wazuh detecta fuerza bruta SSH con regla `5712` | 11/10/2026 |
| `02_active_response_firewall_drop.png` | CU-02 | Ejecución de Active Response `firewall-drop` sobre `10.10.30.50` | 11/10/2026 |
| `03_bloqueo_ssh_timeout.png` | CU-02 | Verificación del bloqueo mediante timeout SSH | 11/10/2026 |
| `01_fim_configurado_webroot.png` | CU-03 | FIM configurado en tiempo real sobre `/var/www/html` | 11/10/2026 |
| `02_fim_detecta_archivo_php.png` | CU-03 | FIM detecta la creación de un archivo PHP en el webroot | 11/10/2026 |
| `03_regla_cu03_100200_nivel12.png` | CU-03 | Regla local `100200` nivel 12 detecta posible webshell | 11/10/2026 |
| `04_agente_webapp_y_script_aislamiento.png` | CU-03 | Agente `webapp` activo y script `isolate-webapp` disponible | 11/10/2026 |
| `05_active_response_cu03_configurado.png` | CU-03 | Configuración del comando y Active Response para regla `100200` | 11/10/2026 |
| `06_alerta_final_cu03.png` | CU-03 | Alerta final por `cu03-isolation-test.php` | 11/10/2026 |
| `07_active_response_aislamiento.png` | CU-03 | Ejecución de `isolate-webapp` y aislamiento automático | 11/10/2026 |
| `08_rutas_webapp_aislado.png` | CU-03 | Ruta por defecto eliminada y DMZ inaccesible | 11/10/2026 |
| `09_agente_webapp_activo_durante_aislamiento.png` | CU-03 | Agente ID 003 permanece `Active` durante el aislamiento | 11/10/2026 |
| `10_wazuh_1514_preservado.png` | CU-03 | Comunicación TCP 1514 con Wazuh preservada | 11/10/2026 |
| `CU-02/2026-10-14_CU-02_deteccion-respuesta.txt` | CU-02 | Repetición con timestamps reales (MTTD/MTTR) tras corregir el acceso a mail | 14/10/2026 |
| `CU-02/2026-10-14_CU-02_mail.txt` | CU-02 | Mail de alerta recibido en `soc@lab.local` — eslabón de notificación, antes pendiente | 14/10/2026 |
| `CU-03_INC-2026-003/2026-10-14_CU-03_reenrolamiento-y-cierre.txt` | CU-03 | Reenrolamiento del agente `webapp` + repetición con timestamps reales | 14/10/2026 |
| `CU-03_INC-2026-003/2026-10-14_CU-03_mail.txt` | CU-03 | Mail de alerta recibido en `soc@lab.local` — eslabón de notificación, antes pendiente | 14/10/2026 |

### Estado resumido

| Caso | Estado |
|---|---|
| CU-01 — Reconocimiento contra la DMZ | ✅ Completado y verificado |
| CU-02 — Fuerza bruta SSH + respuesta automática + **mail** | ✅ Completado y verificado de punta a punta (14/10) |
| CU-03 — Webshell + FIM + aislamiento automático + **mail** | ✅ Completado y verificado de punta a punta (14/10, tras reenrolar el agente `webapp`) |

