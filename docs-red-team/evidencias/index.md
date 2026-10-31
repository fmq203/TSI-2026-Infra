# Índice de evidencias — Red Team

Este índice reúne las evidencias por objetivo. El desarrollo, los resultados y las
conclusiones están en el [informe de evidencias](../informe-evidencias-redteam.md) y el
resumen de hallazgos en el [informe de evaluación técnica](../informe-red-team.md).

**Nomenclatura (31/10/2026):** las carpetas siguen dos ejes — **RT-01 a RT-12**, los
objetivos de ataque de la letra, y **AE-01 / AE-02**, análisis que no son objetivos de la
letra. Los hallazgos usan numeración corrida `H-01` a `H-25`; la columna *Objetivo* de la
§4 del informe técnico liga cada hallazgo a su RT o AE. Reemplaza los nombres previos
`CU-…`.

## Objetivos Red Team (RT)

| Objetivo | Tema | Evidencia |
|---|---|---|
| [RT-01 — Reconocimiento / escaneo](../informe-evidencias-redteam.md#rt-01--reconocimiento--escaneo-de-puertos) | Partes A y B: escaneos desde Usuarios y WAN. | [Capturas `script-1..6`](./RT-01/) |
| [RT-02 — Fuerza bruta SSH](../informe-evidencias-redteam.md#rt-02--fuerza-bruta-ssh) | Prueba contra SSH y respuesta de detección. | [Detección y respuesta](./RT-02/2026-10-25_RT-02_deteccion-respuesta.txt), [captura Wazuh](./RT-02/script1-wazuh.png), [terminal Kali](<./RT-02/script2-kali terminal.jpg>) |
| [RT-03 — Webshell / inyección en la app](../informe-evidencias-redteam.md#rt-03--webshell--inyección-en-la-app-de-préstamos) | Prueba en la aplicación y evidencia de respuesta. | [Detección y respuesta](./RT-03/2026-10-25_RT-03_deteccion-respuesta.txt), [subida de archivo](<./RT-03/01_file upload.jpg>), [alerta Wazuh](<./RT-03/02_Wazuh evidencia rule 100200.png>), [terminal Kali](<./RT-03/03_kali terminal curl.jpg>) |
| [RT-04 — Honeypot Cowrie](../informe-evidencias-redteam.md#rt-04--honeypot-cowrie) | Sesión aceptada por Cowrie sin alerta. | [Registro](./RT-04/2026-10-28_RT-04_cowrie-sin-alerta.txt), [conexión SSH](<./RT-04/01_ssh connect.jpg>), [Threat Hunting](<./RT-04/02_Threat Hunting.png>) |
| [RT-05 — Exfiltración por DNS](../informe-evidencias-redteam.md#rt-05--exfiltración-por-dns) | Falta de correlación de DNS. | [Registro](./RT-05/2026-10-28_RT-05_sin-correlacion-dns.txt) |
| [RT-06 — Credenciales robadas / identidad](../informe-evidencias-redteam.md#rt-06--uso-de-credenciales-por-defecto--robadas-identidad) | Acceso a consolas e identidad; auditoría de Keycloak. | [Eventos de Keycloak](./RT-06/events-keycloak.png) |
| [RT-07 — Evasión del SIEM](../informe-evidencias-redteam.md#rt-07--evasión-del-siem) | Alcance y exposición de reglas locales. | [Registro](./RT-07/2026-10-28_RT-07_reglas-publicas.txt) |
| [RT-08 — Ataque a Wazo](../informe-evidencias-redteam.md#rt-08--ataque-a-wazo) | Wazo no está desplegado en el entorno evaluado. | [Registro](./RT-08/2026-10-27_RT-08_wazo-ausente.txt) |
| [RT-09 — MFA administrativo](../informe-evidencias-redteam.md#rt-09--mfa-administrativo) | Estado del MFA y los realms de Keycloak. | [Registro](./RT-09/2026-10-27_RT-09_mfa-ausente.txt), [cuenta de laboratorio](<./RT-09/01_lab account - not found.jpg>), [lista de realms](<./RT-09/02_lista de realms.jpg>), [Wazuh sin login](<./RT-09/03_Wazuh sin login.png>) |
| [RT-10 — Consola del SIEM](../informe-evidencias-redteam.md#rt-10--consola-del-siem) | Acceso a la consola Wazuh sin autenticación. | [Registro](./RT-10/2026-10-27_RT-10_consola-siem.txt), [inicio de Wazuh](<./RT-10/01_Wazuh home.png>), [agentes](<./RT-10/02_listado de agentes.png>), [Threat Hunting](<./RT-10/03_Threat Hunting.png>) |
| [RT-11 — DoS acotado](../informe-evidencias-redteam.md#rt-11--dos-acotado) | Evaluación sin enviar tráfico de denegación de servicio. | [Registro](./RT-11/2026-10-27_RT-11_sin-deteccion-dos.txt) |
| [RT-12 — OSINT del repositorio](../informe-evidencias-redteam.md#rt-12--osint-del-repositorio) | Exposición de información en el repositorio público. | [Registro](./RT-12/2026-10-28_RT-12_osint-repo.txt) |

> RT-01, RT-02 y RT-03 reúnen las pruebas que antes se documentaron como casos de uso
> (CU-01 a CU-03). RT-06 reúne el acceso a identidad (antes CU-04). RT-05 unifica la
> exfiltración DNS (antes partida entre CU-05 y RT-05).

### Capturas de RT-01 (reconocimiento)

- [script-1.png](./RT-01/script-1.png) · [script-2.png](./RT-01/script-2.png) · [script-3.png](./RT-01/script-3.png)
- [script-4-1.png](./RT-01/script-4-1.png) · [script-4-2.png](./RT-01/script-4-2.png) · [script-4-3.png](./RT-01/script-4-3.png)
- [script-5.png](./RT-01/script-5.png) · [script-6.png](./RT-01/script-6.png)

## Análisis sin tráfico (AE)

| Análisis | Tema | Evidencia |
|---|---|---|
| [AE-01 — Inspección estática del repositorio](../informe-evidencias-redteam.md#ae-01--inspección-estática-del-repositorio) | Trivy y Semgrep sobre Dockerfiles, compose y scripts. | [Trivy (TXT)](./AE-01/trivy-fs.txt), [Trivy (JSON)](./AE-01/trivy-fs.json), [Semgrep (TXT)](./AE-01/semgrep.txt), [Semgrep (JSON)](./AE-01/semgrep.json) |
| [AE-02 — Avisos públicos y auditoría de dependencias](../informe-evidencias-redteam.md#ae-02--avisos-públicos-y-auditoría-de-dependencias) | Contraste de versiones con avisos y estado de soporte. | [Avisos públicos](./AE-02/2026-10-26_AE-02_avisos-publicos.txt), [Auditoría de dependencias](./AE-02/2026-10-31_AE-02_auditoria-dependencias.md) |

## Correspondencia hallazgo ↔ carpeta de evidencia

Cada hallazgo cuelga de un objetivo (columna *Objetivo* del inventario, §4 del informe
técnico), y ese objetivo es la carpeta donde está su evidencia.

| Carpeta | Hallazgos |
|---|---|
| `RT-01/` | H-01, H-02, H-03 |
| `RT-02/` | — (el control funcionó; sin hallazgo) |
| `RT-03/` | — (el control funcionó; sin hallazgo) |
| `RT-04/` | H-07 |
| `RT-05/` | H-08 |
| `RT-06/` | H-04, H-05, H-06 |
| `RT-07/` | H-09 |
| `RT-08/` | H-20 |
| `RT-09/` | H-21 |
| `RT-10/` | H-22 (mismo hueco que H-05) |
| `RT-11/` | H-23 |
| `RT-12/` | H-24 |
| `AE-01/` | H-10, H-11, H-12 |
| `AE-02/` | H-13 a H-19, H-26, H-27 |
| (sin carpeta: §0 del informe de evidencias) | H-25 (transversal, entorno) |
