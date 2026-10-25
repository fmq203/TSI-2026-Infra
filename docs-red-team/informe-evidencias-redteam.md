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

- **Objetivo:** Suricata / DMZ (`10.10.20.50`)
- **Posición del atacante:** _(a completar)_
- **Detección esperada (Blue Team):** firma Suricata → Wazuh, sin bloqueo automático.

### Comandos ejecutados
```bash
_(a completar)_
```

### Resultado
_(a completar)_

### Evidencia
_(capturas en `evidencias/CU-01/`)_

### Respuesta del Blue Team observada
_(a completar)_

### Hallazgo / conclusión
_(a completar)_

---

## CU-02 — Fuerza bruta SSH

- **Objetivo:** Host SSH víctima (`10.10.30.10:2222`, usuario `labuser`)
- **Posición del atacante:** VM Kali en VLAN Usuarios (`10.10.30.100`)
- **Detección esperada (Blue Team):** regla Wazuh 5712/5763 → Active Response
  `firewall-drop` → mail al SOC.

### Comandos ejecutados
```bash
_(a completar)_
```

### Resultado
_(a completar)_

### Evidencia
_(capturas en `evidencias/CU-02/`)_

### Respuesta del Blue Team observada
_(a completar — medir MTTD/MTTR)_

### Hallazgo / conclusión
_(a completar)_

---

## CU-03 — Webshell / inyección en la app de préstamos

- **Objetivo:** DVWA (`10.10.10.10`)
- **Posición del atacante:** _(a completar)_
- **Detección esperada (Blue Team):** FIM Wazuh sobre `/var/www/html` → Active Response
  `isolate-webapp` → mail al SOC.

### Comandos ejecutados
```bash
_(a completar)_
```

### Resultado
_(a completar)_

### Evidencia
_(capturas en `evidencias/CU-03/`)_

### Respuesta del Blue Team observada
_(a completar)_

### Hallazgo / conclusión
_(a completar)_

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
