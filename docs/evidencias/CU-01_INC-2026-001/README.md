# Evidencia CU-01 – Reconocimiento contra la DMZ (INC-2026-001)

## Objetivo
Demostrar la detección de una actividad de reconocimiento/escaneo de puertos contra la DMZ y su correlación en Wazuh a partir de alertas generadas por Suricata.

## Escenario
- Origen del reconocimiento: router / 10.10.20.254
- Objetivo DMZ: Suricata / 10.10.20.50
- Técnica: escaneo SYN con Nmap
- Firma Suricata: SID 1000001
- Regla Wazuh: 100100
- Incidente asociado: INC-2026-001

## Evidencias

### 1. Conectividad hacia la DMZ
Se verifica conectividad con `10.10.20.50` mediante ping.

### 2. Ejecución del reconocimiento
Se ejecuta:

`sudo nmap -sS -p 1-1000 10.10.20.50`

Nmap detecta el host activo y realiza el barrido de los primeros 1000 puertos TCP.

### 3. Detección en Suricata
Suricata genera alertas con:

- `signature_id: 1000001`
- `signature: CU-01 Posible escaneo de puertos TCP (muchos SYN por origen)`
- `src_ip: 10.10.20.254`
- `dest_ip: 10.10.20.50`

### 4. Correlación en Wazuh
Wazuh procesa la alerta de Suricata y genera:

- `id: 100100`
- `level: 10`
- descripción correspondiente a CU-01
- grupo `suricata`

## Resultado
`Nmap → Suricata SID 1000001 → Wazuh regla 100100 → INC-2026-001`

Estado: **COMPLETADO**
