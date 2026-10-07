# Evidencias — kit de captura

> Esta carpeta guarda la **evidencia real** de la cadena detección → respuesta →
> notificación, que es lo que el auditor pide ver (LETRA.md §6.6) y lo que referencian
> `04-gestion-incidentes.md`, `07-monitoreo-logs.md` y el Excel de controles.
>
> Al 07/10/2026 está **vacía de artefactos**: este README es el procedimiento para
> llenarla. Cada integrante lo corre en su propio despliegue (`vagrant up`, ver
> `../../vagrant/README.md`), captura lo que se indica y lo guarda con el nombre exacto
> de la columna "Archivo".

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

## CU-01 — Reconocimiento contra la DMZ (INC-2026-001)

**Cadena a evidenciar:** escaneo → Suricata (SIDs 1000001/1000005) → Wazuh (86601 →
100100, nivel 10) → dashboard + mail al SOC.

### 1. Lanzar el ataque (desde el router, su tráfico no pasa por el filtro)

```bash
vagrant ssh router -- "sudo apt-get install -y -qq nmap && ping -c 20 -i 0.2 10.10.20.50 && sudo nmap -sS -p 1-1000 10.10.20.50"
```

**Anotar la hora UTC exacta del ataque** (`date -u`) — hace falta para el MTTD (KPI).

### 2. Capturar

| # | Qué muestra | Cómo | Archivo |
|---|---|---|---|
| 1 | Suricata generó la alerta | `docker exec suricata grep '"event_type":"alert"' /var/log/suricata/eve.json \| tail -5` | `AAAA-MM-DD_CU-01_suricata-eve.txt` |
| 2 | Wazuh la procesó (regla 100100) | `docker exec wazuh.manager grep '100100' /var/ossec/logs/alerts/alerts.json \| tail -3` | `AAAA-MM-DD_CU-01_wazuh-alertjson.txt` |
| 3 | **Alerta en el dashboard** | Threat Hunting, filtro `rule.id:100100` (o `data.alert.signature_id:1000*`). Mostrar fecha, `src_ip`, descripción y MITRE T1046 | `AAAA-MM-DD_CU-01_dashboard.png` |
| 4 | Notificación | Mail recibido en `soc@lab.local` (si CU-01 llega a nivel 10) | `AAAA-MM-DD_CU-01_mail.png` |

### 3. Completar en los documentos

- `04-gestion-incidentes.md` INC-2026-001: hora exacta, `src_ip` y rutas de estos archivos.
- `07-monitoreo-logs.md` §6: MTTD = hora de la alerta − hora del ataque.

---

## CU-02 — Fuerza bruta SSH + respuesta automática (INC-2026-002)

**Cadena:** 12 logins fallidos → agente Wazuh → reglas sshd 5712/5763 (nivel 10) →
Active Response `firewall-drop` (regla 651, DROP 10 min) → mail al SOC.

### 1. Verificar enrolamiento y lanzar

```bash
docker exec wazuh.manager /var/ossec/bin/agent_control -l         # "ssh-client" Active
vagrant ssh router -- "sudo apt-get install -y -qq sshpass && for i in \$(seq 1 12); do sshpass -p incorrecta\$i ssh -p 2222 -o StrictHostKeyChecking=no labuser@10.10.30.10 true; done"
```

Anotar hora UTC del ataque y del DROP (para el MTTR).

### 2. Capturar

| # | Qué muestra | Cómo | Archivo |
|---|---|---|---|
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

## CU-03 — Webshell (INC-2026-003)

**No implementado** (falta agente Wazuh con FIM sobre el webroot de `target-webapp`).
Cuando esté, el esquema es el mismo: crear un archivo en `/var/www/html` dentro del
contenedor de la app → alerta de FIM (`syscheck`) → playbook de aislamiento → mail.
Dejar la evidencia como `AAAA-MM-DD_CU-03_*`.

---

## Índice de evidencias (completar a medida que se agregan)

| Archivo | Caso | Qué prueba | Fecha captura |
|---|---|---|---|
| _(vacío al 07/10/2026)_ | | | |
