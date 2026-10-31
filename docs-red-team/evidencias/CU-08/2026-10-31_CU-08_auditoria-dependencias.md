# CU-08 — Auditoría de dependencias

**Fecha:** 2026-10-31
**Alcance:** manifiestos y Dockerfiles; revisión de avisos públicos asociados a las versiones declaradas.
**Modalidad:** análisis documental, sin tráfico de prueba contra el laboratorio y sin modificar imágenes.

## Tecnologías y herramientas usadas

- Lectura estática de los manifiestos y Dockerfiles del repositorio.
- API de NVD CVE 2.0 y avisos oficiales de GitHub/Wazuh para cotejar identificador,
  versiones afectadas, severidad y versión corregida.
- Página oficial de Debian para comprobar el estado de soporte de Stretch.
- Se consultaron como antecedente los resultados ya guardados de Trivy 0.76.1 y
  Semgrep 1.182.1 en [CU-06](../CU-06/).
- Docker CLI 29.7.2: se comprobó disponibilidad del motor para determinar si era
  posible inspeccionar imágenes locales. El cliente no pudo conectarse al daemon
  `dockerDesktopLinuxEngine`. No se encontró Trivy ni Grype instalados como CLI en
  este entorno.

## Pruebas y resultados

| Prueba | Método / tecnología | Resultado |
|---|---|---|
| Inventario de componentes | Lectura de `docker-compose.yml` y Dockerfiles | Encontradas versiones de Wazuh, agente Wazuh, Keycloak, Debian y etiquetas de imágenes. Las ubicaciones se detallan en los hallazgos. |
| Correlación con avisos | NVD CVE 2.0 + advisories oficiales de Wazuh/GitHub | Wazuh Manager 4.9.0 está afectado por CVE-2025-24016 y CVE-2026-41424. Wazuh Dashboard 4.9.0 está dentro del rango de CVE-2025-64483. |
| Estado de soporte del sistema base | Información oficial de Debian | Debian Stretch dejó de recibir actualizaciones de seguridad el 2020-07-06 y terminó su LTS el 2022-06-30. |
| Análisis de imágenes | Docker CLI; se requería daemon disponible | **No ejecutado:** el daemon no estaba disponible. No se descargaron imágenes ni se generó un SBOM. |
| Revisión de escaneos previos | Salidas existentes de Trivy y Semgrep de CU-06 | Trivy corrió con `misconfig,secret`, no con scanner de vulnerabilidades de paquetes/imágenes. Semgrep usó reglas estáticas locales; ninguno de esos resultados demuestra que las imágenes estén libres de CVE. |

## Hallazgos

### H-08.1 — Wazuh Manager 4.9.0: CVE-2025-24016

- **Severidad:** Crítica, CVSS 3.1 **9.9** (NVD).
- **Ubicación:** [`infra/siem-hids/docker-compose.yml`](../../../infra/siem-hids/docker-compose.yml), imagen `wazuh/wazuh-manager:4.9.0` (servicio Manager).
- **Rango afectado:** Wazuh `>= 4.4.0, < 4.9.1`; corregido en `4.9.1`.
- **Impacto descrito:** deserialización insegura que puede permitir ejecución remota de código en el Manager bajo las condiciones descritas por el aviso, incluido acceso a la API o ciertas configuraciones con un agente comprometido.
- **Validación:** el pin `4.9.0` cae dentro del rango afectado. NVD incluye el CVE en el catálogo KEV de CISA.
- **Fuentes:** [NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-24016), [aviso de Wazuh GHSA-hcrc-79hj-m3qh](https://github.com/wazuh/wazuh/security/advisories/GHSA-hcrc-79hj-m3qh).

### H-08.2 — Wazuh Manager 4.9.0: CVE-2026-41424

- **Severidad:** Alta, CVSS 3.1 **8.2** (NVD).
- **Ubicación:** [`infra/siem-hids/docker-compose.yml`](../../../infra/siem-hids/docker-compose.yml), imagen `wazuh/wazuh-manager:4.9.0`. El mismo compose declara el puerto de API `55000`.
- **Rango afectado:** `>= 4.9.0, < 4.10.4` y `>= 4.11.0, < 4.14.6`; para la versión usada, corregido en `4.10.4`.
- **Impacto descrito:** un usuario autenticado con rol `users_admin` puede cambiar la contraseña de cuentas de administrador protegidas. Requiere credenciales/rol y acceso a la API; el manifiesto por sí solo no demuestra que esas precondiciones estén disponibles desde una red atacante.
- **Validación:** la versión declarada coincide con el inicio del rango vulnerable. La accesibilidad efectiva de la API depende del enrutamiento y los controles de red del despliegue.
- **Fuentes:** [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-41424), [aviso de Wazuh GHSA-gj9h-8hmr-xjjr](https://github.com/wazuh/wazuh/security/advisories/GHSA-gj9h-8hmr-xjjr), [notas de Wazuh 4.10.4](https://github.com/wazuh/wazuh/releases/tag/v4.10.4).

### H-08.3 — Wazuh Dashboard 4.9.0: CVE-2025-64483

- **Severidad:** Media, CVSS 4.0 **5.3** (NVD).
- **Ubicación:** [`infra/siem-hids/docker-compose.yml`](../../../infra/siem-hids/docker-compose.yml), imagen `wazuh/wazuh-dashboard:4.9.0`.
- **Rango afectado:** `>= 4.9.0, < 4.13.0`; corregido en `4.13.0`.
- **Impacto descrito:** en ciertas configuraciones, usuarios autenticados con rol API de solo lectura pueden recuperar credenciales de enrolamiento desde `/utils/configuration` y usarlas para registrar agentes. El advisory aclara que el impacto práctico es limitado; no implica por sí mismo acceso a datos del sistema.
- **Validación:** el tag `4.9.0` está dentro del rango publicado. No se verificó la configuración efectiva del rol ni el comportamiento de una instancia en ejecución.
- **Fuentes:** [NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-64483), [aviso de Wazuh Dashboard Plugins GHSA-gwf3-8gm3-qrmj](https://github.com/wazuh/wazuh-dashboard-plugins/security/advisories/GHSA-gwf3-8gm3-qrmj).

### H-08.4 — Debian Stretch fuera de soporte y repositorios APT sin autenticación

- **Severidad:** Riesgo alto de mantenimiento/cadena de suministro; **no se atribuye un CVE concreto**.
- **Ubicación:** [`infra/targets/web-victim/Dockerfile`](../../../infra/targets/web-victim/Dockerfile), base `vulnerables/web-dvwa:latest`; el Dockerfile configura repositorios Debian Stretch en HTTP con `trusted=yes` y usa `--allow-unauthenticated`.
- **Resultado:** Debian informa que las actualizaciones de seguridad de Stretch terminaron el 2020-07-06 y su LTS el 2022-06-30. El uso de repositorios HTTP junto con la omisión de validación de paquetes debilita la integridad de la construcción de la imagen.
- **Limitación:** `vulnerables/web-dvwa:latest` es un tag mutable. Sin digest ni imagen inspeccionada no se confirma qué versión de Debian/paquetes está efectivamente desplegada ni se asignan CVE a paquetes no identificados.
- **Fuentes:** [Debian Stretch](https://www.debian.org/releases/stretch/), [calendario LTS de Debian](https://wiki.debian.org/LTS).

## Componentes sin versión exacta verificable

El inventario también contiene `quay.io/keycloak/keycloak:26.0`, `postgres:16-alpine`,
`mysql:8.0` y varios tags `latest` (Suricata, Cowrie, mailserver y DVWA). El tag no es un
digest inmutable; para varios de ellos tampoco fija un parche. No se atribuye un CVE
nuevo basándose solamente en esos tags. Los avisos de Keycloak consignados anteriormente
en CU-07 no fueron revalidados contra una imagen/digest en esta prueba.

Los agentes Wazuh `4.9.0-1` aparecen en los Dockerfiles de los blancos, pero los tres
CVE de Wazuh enumerados en este registro se atribuyen al Manager o al Dashboard, no al
paquete de agente por el solo hecho de compartir el número de versión.

## Conclusión

La revisión documental confirma tres avisos aplicables a las versiones fijadas de Wazuh
(dos en Manager y uno en Dashboard) y una base Debian fuera de soporte con validación de
repositorios debilitada. La prueba **no** determina el contenido exacto de las imágenes
en ejecución ni equivale a un escaneo de paquetes. Para cerrar esa incertidumbre se
requieren imágenes/digests identificables, motor de contenedores disponible y un scanner
de vulnerabilidades/SBOM.
