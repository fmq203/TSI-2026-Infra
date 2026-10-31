# Índice de evidencias — Red Team

Este índice reúne las evidencias disponibles por caso y objetivo. El desarrollo,
los resultados y las conclusiones están en el
[informe de evidencias](../informe-evidencias-redteam.md) y el resumen de hallazgos
en el [informe de evaluación técnica](../informe-red-team.md).

## Casos de uso (CU)

| Caso | Tema | Evidencia |
|---|---|---|
| [CU-01 — Reconocimiento / escaneo de puertos](../informe-evidencias-redteam.md#cu-01--reconocimiento--escaneo-de-puertos) | Partes A y B: escaneos desde Usuarios y WAN. | [Capturas](./CU-01/) |
| [CU-02 — Fuerza bruta SSH](../informe-evidencias-redteam.md#cu-02--fuerza-bruta-ssh) | Prueba contra SSH y respuesta de detección. | [Detección y respuesta](./CU-02/2026-10-25_CU-02_deteccion-respuesta.txt), [captura Wazuh](./CU-02/script1-wazuh.png), [terminal Kali](<./CU-02/script2-kali terminal.jpg>) |
| [CU-03 — Webshell / inyección en la app de préstamos](../informe-evidencias-redteam.md#cu-03--webshell--inyección-en-la-app-de-préstamos) | Prueba en la aplicación y evidencia de respuesta. | [Detección y respuesta](./CU-03/2026-10-25_CU-03_deteccion-respuesta.txt), [subida de archivo](<./CU-03/01_file upload.jpg>), [alerta Wazuh](<./CU-03/02_Wazuh evidencia rule 100200.png>), [terminal Kali](<./CU-03/03_kali terminal curl.jpg>) |
| [CU-04 — Uso de credenciales por defecto / robadas](../informe-evidencias-redteam.md#cu-04--uso-de-credenciales-por-defecto--robadas-identidad) | Acceso a consolas e identidad; también se documenta aquí el objetivo RT-06. | [Eventos de Keycloak](./CU-04/events-keycloak.png) |
| [CU-05 — Exfiltración de datos por DNS](../informe-evidencias-redteam.md#cu-05--exfiltración-de-datos-por-dns) | Resultados y análisis en el informe. | No hay archivos de evidencia independientes en esta carpeta por el momento. |
| [CU-06 — Inspección estática del repositorio](../informe-evidencias-redteam.md#cu-06--inspección-estática-del-repositorio) | Resultados de Trivy y Semgrep. | [Trivy (TXT)](./CU-06/trivy-fs.txt), [Trivy (JSON)](./CU-06/trivy-fs.json), [Semgrep (TXT)](./CU-06/semgrep.txt), [Semgrep (JSON)](./CU-06/semgrep.json) |
| [CU-07 — Avisos públicos de las tecnologías](../informe-evidencias-redteam.md#cu-07--avisos-públicos-de-las-tecnologías-2026-10-26) | Contraste de versiones y avisos públicos. | [Registro de revisión](./CU-07/2026-10-26_CU-07_avisos-publicos.txt) |
| [CU-08 — Auditoría de dependencias y tecnologías](../informe-evidencias-redteam.md#cu-08--auditoría-de-dependencias-y-tecnologías-de-infraestructura) | Versiones fijadas, advisories conocidos y estado de soporte; análisis documental, sin escaneo de imágenes. | [Método, resultados y hallazgos](./CU-08/2026-10-31_CU-08_auditoria-dependencias.md) |

### Capturas adicionales de CU-01

- [script-1.png](./CU-01/script-1.png)
- [script-2.png](./CU-01/script-2.png)
- [script-3.png](./CU-01/script-3.png)
- [script-4-1.png](./CU-01/script-4-1.png)
- [script-4-2.png](./CU-01/script-4-2.png)
- [script-4-3.png](./CU-01/script-4-3.png)
- [script-5.png](./CU-01/script-5.png)
- [script-6.png](./CU-01/script-6.png)

## Objetivos Red Team (RT)

RT-01, RT-02 y RT-03 corresponden a las pruebas documentadas en CU-01, CU-02 y
CU-03, respectivamente. RT-06 quedó cerrado con la evidencia de CU-04; no tiene una
carpeta separada.

| Objetivo | Tema | Evidencia |
|---|---|---|
| [RT-04 — Honeypot Cowrie](../informe-evidencias-redteam.md#rt-04--honeypot-cowrie) | Sesión aceptada por Cowrie sin alerta. | [Registro](./RT-04/2026-10-28_RT-04_cowrie-sin-alerta.txt), [conexión SSH](<./RT-04/01_ssh connect.jpg>), [Threat Hunting](<./RT-04/02_Threat Hunting.png>) |
| [RT-05 — Exfiltración por DNS](../informe-evidencias-redteam.md#rt-05--exfiltración-por-dns) | Falta de correlación de DNS. | [Registro](./RT-05/2026-10-28_RT-05_sin-correlacion-dns.txt) |
| [RT-07 — Evasión del SIEM](../informe-evidencias-redteam.md#rt-07--evasión-del-siem) | Alcance y exposición de reglas locales. | [Registro](./RT-07/2026-10-28_RT-07_reglas-publicas.txt) |
| [RT-08 — Ataque a Wazo](../informe-evidencias-redteam.md#rt-08--ataque-a-wazo) | Wazo no está desplegado en el entorno evaluado. | [Registro](./RT-08/2026-10-27_RT-08_wazo-ausente.txt) |
| [RT-09 — MFA administrativo](../informe-evidencias-redteam.md#rt-09--mfa-administrativo) | Estado del MFA y los realms de Keycloak. | [Registro](./RT-09/2026-10-27_RT-09_mfa-ausente.txt), [cuenta de laboratorio](<./RT-09/01_lab account - not found.jpg>), [lista de realms](<./RT-09/02_lista de realms.jpg>), [Wazuh sin login](<./RT-09/03_Wazuh sin login.png>) |
| [RT-10 — Consola del SIEM](../informe-evidencias-redteam.md#rt-10--consola-del-siem) | Acceso a la consola Wazuh sin autenticación. | [Registro](./RT-10/2026-10-27_RT-10_consola-siem.txt), [inicio de Wazuh](<./RT-10/01_Wazuh home.png>), [agentes](<./RT-10/02_listado de agentes.png>), [Threat Hunting](<./RT-10/03_Threat Hunting.png>) |
| [RT-11 — DoS acotado](../informe-evidencias-redteam.md#rt-11--dos-acotado) | Evaluación sin enviar tráfico de denegación de servicio. | [Registro](./RT-11/2026-10-27_RT-11_sin-deteccion-dos.txt) |
| [RT-12 — OSINT del repositorio](../informe-evidencias-redteam.md#rt-12--osint-del-repositorio) | Exposición de información en el repositorio público. | [Registro](./RT-12/2026-10-28_RT-12_osint-repo.txt) |
