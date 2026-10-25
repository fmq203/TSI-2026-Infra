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

- **Entorno:** levantado y operativo en VirtualBox (VM atacante Kali en VLAN Usuarios
  `10.10.30.100`, con 3ª placa en VLAN WAN pendiente de sumar para CU-01 Parte B).
- **Ataques:** CU-01 Parte A hecha; CU-01 Parte B, CU-02, CU-03, CU-04 (ampliar), CU-05
  pendientes.
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
