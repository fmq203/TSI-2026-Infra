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
