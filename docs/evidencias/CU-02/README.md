# Evidencia CU-02 – Fuerza bruta SSH + bloqueo automático

## Objetivo
Demostrar que Wazuh detecta múltiples intentos fallidos de autenticación SSH sobre el `ssh-client` y ejecuta una respuesta activa para bloquear temporalmente la IP atacante.

## Escenario
- Objetivo: `ssh-client`
- IP objetivo: `10.10.30.10`
- Puerto SSH: `2222`
- IP atacante: `10.10.30.50`
- Agente Wazuh: `ID 002 - ssh-client`
- Regla disparada: `5712`
- Active Response: `firewall-drop`
- Tiempo de bloqueo configurado: `600` segundos

## Evidencias

### 1. Detección de fuerza bruta
Wazuh genera una alerta de nivel 10 con la regla `5712`:

`sshd: brute force trying to get access to the system. Non existent user.`

La alerta identifica como origen la IP `10.10.30.50` y el usuario de prueba `usuariofalso`.

Archivo:
`01_alerta_wazuh_regla_5712.png`

### 2. Ejecución de Active Response
En `/var/ossec/logs/active-responses.log` del target se observa la ejecución de:

`active-response/bin/firewall-drop`

La respuesta activa se ejecuta sobre la IP atacante `10.10.30.50`.

Archivo:
`02_active_response_firewall_drop.png`

### 3. Verificación del bloqueo
Luego de la detección y respuesta activa se intenta nuevamente una conexión SSH desde el atacante:

`ssh -o ConnectTimeout=3 -p 2222 usuariofalso@10.10.30.10`

Resultado:

`ssh: connect to host 10.10.30.10 port 2222: Connection timed out`

Esto confirma que la IP atacante quedó bloqueada temporalmente.

Archivo:
`03_bloqueo_ssh_timeout.png`

## Resultado
CU-02 validado correctamente:

`Fuerza bruta SSH → Regla 5712 → Active Response → firewall-drop → IP atacante bloqueada`

Estado: **COMPLETADO**

---

## Actualización 14/10/2026 — notificación por mail

Lo de arriba (11/10) dejó verificada la detección y la respuesta, pero no se había
podido confirmar la **notificación** (el mail a `soc@lab.local` nunca llegaba). Repitiendo
el mismo ataque el 14/10 se encontraron y corrigieron dos problemas de red/config
(detalle en `brain/LEARNINGS.md`, entrada 2026-10-14):

1. Faltaba la regla de firewall Gestión → DMZ TCP 25 en OPNsense.
2. Postfix rechazaba el mail del manager (`550 5.5.1 Protocol error`, filtro anti-spam
   `postscreen`) porque `net_mgmt` no estaba en `mynetworks`. Corregido de forma
   persistente en `infra/mail/config/postfix-main.cf`.

### Línea de tiempo real (UTC)

| Evento | Hora | Delta |
|---|---|---|
| Primer intento fallido | 00:45:31 | — |
| Alerta Wazuh (regla 5712, nivel 10) | 00:45:44 | MTTD ≈ 13 s |
| Active Response `firewall-drop` | 00:45:44 | MTTR ≈ 0 s |
| Mail entregado en `soc@lab.local` | 00:45:55 | +11 s |

### Evidencia nueva

- `2026-10-14_CU-02_deteccion-respuesta.txt` — alerta 5712 completa y `iptables` tras el
  bloqueo.
- `2026-10-14_CU-02_mail.txt` — mail completo recibido en `soc@lab.local`.

**Estado CU-02 (actualizado):** **COMPLETADO Y VERIFICADO de punta a punta, incluida la
notificación por mail.**
