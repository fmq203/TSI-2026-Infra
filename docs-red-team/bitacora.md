# Bitácora — Red Team (Tarea 3)

> Registro de avances, incidencias y pendientes del equipo Red Team. La idea es que
> **cualquier integrante pueda retomar el trabajo** leyendo la última entrada: qué se hizo,
> qué quedó pendiente y dónde está la evidencia. Se agrega al final, no se reescribe el
> pasado. Documento vivo: el estado formal de cada ataque va en
> [`informe-evidencias-redteam.md`](informe-evidencias-redteam.md).

## Integrantes

| Nombre | Rol |
|---|---|
| Andres | Red Team |
| Horacio | Red Team |
| Pablo | Red Team |

## Convención de entradas

```
### AAAA-MM-DD — <Integrante>
- **Hecho:** ...
- **Incidencias:** ...
- **Pendiente / próximo paso:** ...
- **Evidencia:** ruta (docs-red-team/evidencias/CU-0X/...)
```

---

## Estado actual (resumen rápido)

- **Entorno:** levantado. Kali de Pablo con NAT + `vlan_wan` (`203.0.113.100`) +
  `vlan_usr` (`10.10.30.100`).
- **Ataques:** CU-01 Parte A hecha (Andres); CU-02 y CU-03 hechos (Pablo, 25/10);
  RT-08 y RT-09 cerrados (Pablo, 27/10).
  Pendientes: CU-01 Parte B (Andres), CU-04 (Events de Keycloak), CU-05.
- **Estático (CU-06):** Parte A, Trivy 0.76.1 sobre Dockerfiles y secretos.
  Parte B, Semgrep 1.182.1 sobre shell, Dockerfiles, compose y secretos (26/10).
  Evidencia en `docs-red-team/evidencias/CU-06/`.
- **Avisos (CU-07):** Wazuh 4.9.0 y Keycloak `26.0` caen en avisos públicos.
  DVWA es vulnerable a propósito. Los tags `:latest` no se marcaron.
- **Documento de evidencias:** `informe-evidencias-redteam.md`.

---

## Entradas

### 2026-10-25 — Andres

- **Hecho:**
  - Levantado el entorno completo en VirtualBox (`vagrant up` ya existía de días
    previos; se retomó). 11 contenedores operativos.
  - Verificado acceso por túnel SSH a las consolas: Wazuh (`5601`), Keycloak (`8080`),
    DVWA (`8081`).
  - Creada VM Kali y conectada a la VLAN de Usuarios (`eth1` = `10.10.30.100`), con
    alcance confirmado al host SSH víctima (`10.10.30.10`).
  - **CU-01 Parte A** (reconocimiento desde Usuarios) ejecutada y documentada:
    descubrimiento del segmento, escaneos a SSH víctima, app de préstamos y DMZ.
  - **CU-04 (preliminar):** confirmadas credenciales por defecto en Keycloak
    (`admin`/`changeme`, cuenta admin temporal) y Wazuh dashboard sin autenticación.
  - Creado el documento de evidencias y esta bitácora. Primer commit subido a la branch
    `RedTeam` (GitHub).

- **Incidencias (resueltas):**
  - El entorno había quedado suspendido 4 días → reloj corrido y red macvlan degradada.
    Se resolvió con reinicio en frío de las VMs.
  - Los contenedores no eran alcanzables entre VLANs: faltaba **modo promiscuo** en las
    NIC de VLAN de `docker-host`. Se activó en VirtualBox (`allow-all`) y a nivel Linux
    (`PROMISC` en `eth1..eth4`), y se dejó **persistente** con un servicio systemd en
    `docker-host`.
  - `target-webapp` (DVWA) entraba en bucle de reinicio porque su `entrypoint.sh` aborta
    (`set -e`) si no puede enrolar el agente Wazuh. Se resolvió al arreglar la red;
    agentes `webapp` (001) y `ssh-client` (002) quedaron **Active**.

- **Hallazgos registrados:** H-00 (detección caída tras redespliegue + acoplamiento
  DVWA↔agente), H-01.1 (segmentación bloquea recon Usuarios→DMZ/Servidores), H-01.2
  (firewall responde distinto a SYN vs NULL/FIN), H-04.1 (Keycloak cred. por defecto),
  H-04.2 (Wazuh sin login).

- **Pendiente / próximo paso:**
  1. **CU-01 Parte B:** sumar 3ª placa a Kali en `vlan_wan` (`203.0.113.100`), ruta a la
     DMZ por la WAN, y escanear los puertos publicados de `10.10.20.50` y del honeypot
     `10.10.20.30` para disparar Suricata → verificar detección en Wazuh.
  2. **CU-02:** fuerza bruta SSH con hydra contra `10.10.30.10:2222` → verificar
     `firewall-drop` y mail al SOC; medir MTTD/MTTR.
  3. **CU-03:** webshell / inyección en DVWA → verificar FIM e `isolate-webapp`.
     **Ojo:** desde Kali/Usuarios la app `10.10.10.10` dio todos los puertos *filtered*
     (verificar si 80/443 están realmente permitidos o si CU-03 se hace por el túnel).
  4. **CU-04:** ampliar (revisar logs/Events de Keycloak, contrastar con MFA del realm
     `lab`).
  5. **CU-05:** exfiltración por DNS (se presume no detectada — confirmar).

- **Evidencia:** `docs-red-team/evidencias/CU-01/` (capturas `script-1..4`).

### 2026-10-25 — Pablo

- **Hecho:**
  - Kali propia con tres placas: NAT (`10.0.2.15`), `vlan_wan` (`eth1` =
    `203.0.113.100`) y `vlan_usr` (`eth2` = `10.10.30.100`).
  - **CU-02** desde la VLAN Usuarios: intentos SSH fallidos contra
    `labuser@10.10.30.10:2222`.
  - Wazuh lo vio (regla 5763, nivel 10, MTTD ~3 s). Active Response
    `firewall-drop` (regla 651, MTTR ~3 s) dejó `DROP` de `10.10.30.100`.
    Un SSH posterior desde Kali dio *connection timed out*.
  - Mail al SOC entregado en `soc@lab.local` a las 23:12:04 hora local
    (02:12:04 UTC), ~15 s después de la alerta de nivel 10.

- **Incidencias (resueltas):**
  - El ping a `10.10.30.10` no respondía: `docker-host` no tenía la NIC de
    Usuarios en modo promiscuo, así que no llegaba el tráfico al contenedor.
    Se activó `promisc` en `eth1`–`eth4` y quedó un servicio systemd
    `vlan-promisc.service` para el próximo arranque.
  - La consola de `docker-host` no acepta `vagrant`/`vagrant` (la imagen entra
    solo por clave SSH).

- **Pendiente / próximo paso:**
  1. **Andres — CU-01 Parte B:** el escaneo desde `vlan_wan` hacia la DMZ.
  2. **CU-03**, **CU-04** (ampliar) y **CU-05**, como ya estaban.

- **Evidencia:** `docs-red-team/evidencias/CU-02/script1-wazuh.png`,
  `script2-kali terminal.jpg` y
  `docs-red-team/evidencias/CU-02/2026-10-25_CU-02_deteccion-respuesta.txt`.

### 2026-10-25 — Pablo

- **Hecho:**
  - **CU-03** desde Kali en VLAN Usuarios (`10.10.30.100`) contra DVWA
    (`10.10.10.10`), Security Level low, usuario `admin`.
  - File Upload aceptó `cu03-pablo.php` en
    `/var/www/html/hackable/uploads/`.
  - Wazuh, agente `webapp` (001), regla 100200 nivel 12 a las 23:45:21.
    `isolate-webapp` en el mismo segundo: sin ruta por defecto, conservada
    la ruta a `10.10.90.10`. El `curl` desde Kali quedó sin respuesta HTTP.
  - Mail al SOC en `soc@lab.local` a las 23:45:35 hora local (02:45:35 UTC),
    ~14 s después de la alerta de nivel 12.

- **Incidencias (resueltas):**
  - El primer `curl` a `10.10.10.10` no devolvía nada: Kali lo mandaba por la
    ruta `10.10.0.0/16` de la placa WAN, y el firewall descarta WAN → Servidores.
    Se agregó `10.10.10.0/24` vía `10.10.30.254` por `eth2`. La app escuchaba
    en el puerto 80; el agente `webapp` ya estaba Active.

- **Pendiente / próximo paso:**
  1. **Andres — CU-01 Parte B:** el escaneo desde `vlan_wan` hacia la DMZ.
  2. **CU-04** (ampliar) y **CU-05**.

- **Evidencia:** `docs-red-team/evidencias/CU-03/01_file upload.jpg`,
  `02_Wazuh evidencia rule 100200.png`, `03_kali terminal curl.jpg` y
  `2026-10-25_CU-03_deteccion-respuesta.txt`.

### 2026-10-26 — revisión estática

- **Hecho:**
  - Herramienta: **Trivy 0.76.1** (análisis estático, sin tráfico contra el laboratorio).
    Se bajó el binario y se corrió `trivy fs --scanners misconfig,secret` sobre el repo,
    salteando `docs/evidencias`, `docs-red-team/evidencias` y `docs/excel`.
  - El scanner de secretos no marcó coincidencias.
  - Misconfiguraciones solo en los tres Dockerfiles de `infra/targets/`:
    las tres imágenes corren como root (DS-0002, alta); `web-victim` usa
    `vulnerables/web-dvwa:latest` (DS-0001, media); `wazuh-agent` instala paquetes
    sin `--no-install-recommends` (DS-0029, alta); ninguna define HEALTHCHECK
    (DS-0026, baja). `wazuh-agent/` no lo referencia el compose vigente.

- **Incidencias:**
  - Esta versión de Trivy no tiene scanner de Docker Compose. Los
    `docker-compose.yml` quedaron fuera. Un pase posterior puede usar Checkov
    o una Trivy que sí parsee compose.

- **Pendiente / próximo paso:**
  1. Los mismos de antes: CU-01 Parte B, CU-04 y CU-05.
  2. Cubrir los compose quedó para la entrada siguiente (CU-06 Parte B, Semgrep).

- **Evidencia:** `docs-red-team/evidencias/CU-06/trivy-fs.txt` y
  `trivy-fs.json`. El detalle formal está en
  `informe-evidencias-redteam.md`, CU-06 Parte A. La carpeta se llamaba
  `estatico` y pasó a `CU-06` al sumar la Parte B.

### 2026-10-26 — revisión estática (CU-06 Parte B)

- **Hecho:**
  - La evidencia de Trivy quedó en `docs-red-team/evidencias/CU-06/` como
    Parte A de este caso.
  - **Parte B:** Semgrep 1.182.1 sobre `infra/` y `vagrant/` (38 archivos),
    sin tráfico contra el laboratorio. Reglas locales de bash, Dockerfile,
    Docker Compose y secretos: el cliente de Semgrep no pudo verificar el
    certificado de semgrep.dev, y el pack `p/bash` del registro respondió 404.
  - Secretos: sin coincidencias. Compose: sin coincidencias. Ese conjunto no
    mira `cap_add` y sus patrones piden la clave `version:`, que estos
    compose no tienen.
  - Seguridad: `web-victim/Dockerfile` queda como root (`last-user-is-root`,
    error). Confirma H-EST-01 de la Parte A en ese archivo.
  - Info: expansiones sin comillas en `configure-manager.sh` (10) y
    `isolate-webapp.sh` (3). Los valores de esas variables son nombres e IP
    fijos.

- **Incidencias:**
  - Con el fin de línea CRLF del repo, Semgrep cortó el parseo de los RUN
    continuados en los tres Dockerfiles. Una relectura de copias con fin de
    línea LF (el fuente no se tocó) sumó `missing-user-entrypoint` en
    `ssh-victim/Dockerfile` y `missing-user` en `wazuh-agent/Dockerfile`.
    Mismo hallazgo de root que H-EST-01.

- **Pendiente / próximo paso:**
  1. Los de antes: CU-01 Parte B, CU-04 y CU-05.

- **Evidencia:** `docs-red-team/evidencias/CU-06/semgrep.txt` y
  `semgrep.json`. El detalle formal está en
  `informe-evidencias-redteam.md`, CU-06 Parte B.

### 2026-10-26 — avisos públicos (CU-07)

- **Hecho:**
  - Se contrastaron las versiones declaradas en los compose y Dockerfiles
    con avisos públicos. Sin tráfico contra el laboratorio y sin bajar
    imágenes.
  - **Wazuh 4.9.0** (indexer, manager y dashboard) cae en CVE-2025-24016
    (crítica, ejecución en el manager; corregido en 4.9.1), en
    GHSA-gj9h-8hmr-xjjr (alta, un `users_admin` puede cambiar claves de
    administradores) y en GHSA-648q-8m78-5cwv (media, listado de agentes).
  - **Keycloak `26.0`** cae en CVE-2026-18963 (crítica, toma de cuenta por
    el flujo de recuperación), CVE-2026-7507 (alta, fijación de sesión) y
    CVE-2026-4634 (alta, denegación de servicio). El tag no fija el parche;
    un índice del 23/10/2026 lo resolvió a 26.0.8, que sigue adentro. La
    línea 26.0 ya no recibe parches.
  - **DVWA** es la app de préstamos y es vulnerable a propósito.
  - Quedaron afuera CVE-2026-74041 (Wazuh desde 4.14.3), el agente Windows
    ya corregido en 4.9.0, y CVE-2026-2603 (pide un IdP SAML que este
    compose no declara). Cowrie, Suricata, MySQL, Postgres y el mail usan
    tag móvil: no se les atribuyó un CVE.

- **Incidencias:** ninguna. No se levantó el laboratorio para este caso.

- **Pendiente / próximo paso:**
  1. Los de antes: CU-01 Parte B, CU-04 y CU-05.

- **Evidencia:** `docs-red-team/evidencias/CU-07/2026-10-26_CU-07_avisos-publicos.txt`.
  El detalle formal está en `informe-evidencias-redteam.md`, CU-07.

### 2026-10-27 — Pablo

- **Hecho:**
  - **RT-08** cerrado sin ataque. Wazo no está construido: recorte habilitado
    por el docente el 05/10 (`brain/decisions.md`, `README.md`). La IP
    `10.10.20.40` está reservada en `docs/00-arquitectura.md`.
  - Con las VMs encendidas, `docker ps` no muestra contenedor de Wazo. Desde
    el router, `ping -c 2 -W 2 10.10.20.40` dio 100 % de pérdida.
  - El firewall sigue publicando UDP 5060 WAN → DMZ. No hay servicio detrás.

- **Incidencias:** ninguna.

- **Pendiente / próximo paso:**
  1. **Andres — CU-01 Parte B.**
  2. **CU-04** (ampliar), **CU-05**, y el resto de objetivos 7.2 que siguen
     abiertos (RT-09 a RT-12, RT-04 a RT-07, RT-01 Parte B).

- **Evidencia:** `docs-red-team/evidencias/RT-08/2026-10-27_RT-08_wazo-ausente.txt`.
  El detalle formal está en `informe-evidencias-redteam.md`, RT-08.

### 2026-10-27 — Pablo

- **Hecho:**
  - **RT-09** desde el navegador de Windows, por el túnel a Keycloak
    (`localhost:8080`) y al dashboard (`localhost:5601`). Sin Kali.
  - `http://localhost:8080/realms/lab/account/` respondió «Page not found».
    El realm `lab`, donde el Blue Team documentó el TOTP de `admin-lab`,
    no está en esta copia. La base de Keycloak solo tiene el realm `master`.
  - La consola de administración quedó abierta como `admin`, con el selector
    de realms mostrando únicamente `master`, sin pedido de código.
  - `localhost:5601` abrió la home de OpenSearch Dashboards sin login
    (el mismo hueco que H-04.2).

- **Incidencias:** ninguna. El `docker-compose` de `infra/identity/` no
  importa el realm `lab`; por eso un `vagrant up` nuevo no lo trae.

- **Pendiente / próximo paso:**
  1. **Andres — CU-01 Parte B.**
  2. **CU-04:** queda ver si Keycloak registró el login en Events.
  3. **CU-05** y el resto de la 7.2 (RT-10 a RT-12, RT-04 a RT-07).

- **Evidencia:** `docs-red-team/evidencias/RT-09/01_lab account - not found.jpg`,
  `02_lista de realms.jpg`, `03_Wazuh sin login.png` y
  `2026-10-27_RT-09_mfa-ausente.txt`.
  El detalle formal está en `informe-evidencias-redteam.md`, RT-09.
