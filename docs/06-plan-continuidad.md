# Plan de Continuidad y Recuperación (BCP / DRP) — FinSegura S.A.

> Plantilla base: `plantilla/isaca/06-plan-continuidad.md` (SI-BCP-06). Activos:
> `excel/02-registro-activos-mcu5.xlsx`. Riesgos relacionados: `03-analisis-riesgos.md`
> R08 y R12.

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Recuperar** (y respaldo en Proteger) | RC-01, RC-02, RC-03. |
| **MCU 5.0 (categorías)** | RC-01 Plan, RC-02 Comunicación, RC-03 Pruebas | Respaldo y restauración. |
| **COBIT 2019** | DSS04, APO13 | Continuidad y disponibilidad. |
| **ISO/IEC 27001:2022** | A.5.29, A.5.30, A.8.13, A.8.14 | Continuidad y backup. |
| **ISO 22301** | Todas | Gestión de continuidad. |
| **BCU — GSI** | Continuidad y backups | Backup diario, copia fuera del centro de procesamiento, restauración probada. |
| **URCDP — Ley 18.331, Art. 9; Dec. 414/009** | Datos personales | Backups de bases con datos personales y registro de restauraciones. |
| **NIST SP 800-34** | BCP/DRP | Referencia técnica. |

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-BCP-06 |
| Versión | 0.1 (borrador) |
| Responsable | Admin de infraestructura (ver `excel/03`, hoja Roles) |
| Fecha | 07/10/2026 |

**Estado al 07/10/2026:** la **configuración** de toda la infraestructura se reconstruye
desde el repositorio (`make up` / `vagrant up`). Los **datos** (alertas del SIEM, bases,
identidades) **no tienen respaldo** todavía y **no se hizo ninguna prueba de
restauración** (RF-13, RNF-08). Este plan define qué hay que implementar y probar.

---

## 0. Estrategia: dos capas de recuperación

| Capa | Qué recupera | Mecanismo | Estado |
|---|---|---|---|
| **Configuración** (infraestructura como código) | Redes, stacks, reglas de detección, Active Response, configuración del manager | Repositorio git (A16) + `make up` (en orden: `identity nids honeypot siem-hids mail targets`) o `vagrant up` desde cero | ✅ Existe. Sin prueba cronometrada |
| **Datos** | Alertas e índices del SIEM, base de clientes, base de Keycloak, claves de los agentes, secretos | Respaldos (§2) | ❌ No implementado |

La primera capa es la que hace viable un RTO corto: no se restauran servidores, se
recrean desde su definición. La segunda es la que falta para cumplir el BCU.

## 1. Objetivos de recuperación

| Métrica | Objetivo | Justificación |
|---|---|---|
| RTO — base de clientes (A04) y app de préstamos (A03) | 4 h | Proceso crítico: otorgamiento de préstamos |
| RTO — SIEM (A06-A08) | 2 h | Sin SIEM no hay detección ni evidencia; Wazuh tarda 30-60 s en levantar más la restauración de índices |
| RTO — router (A01) | 1 h | Sin router no hay ningún servicio (punto único de falla) |
| RTO — Keycloak (A12-A13) | 4 h | Sin él no hay acceso administrativo con MFA (existe cuenta de emergencia) |
| RPO — base de clientes | 24 h | Respaldo diario (requisito BCU) |
| RPO — alertas del SIEM | 24 h | Snapshot diario del indexer |
| RPO — configuración | 0 (último commit) | Todo cambio pasa por el repositorio |

Son objetivos de diseño: se validan en la prueba de §3.

## 2. Inventario de respaldo

| Activo | Datos | Herramienta | Frecuencia | Ubicación | Retención | Estado |
|---|---|---|---|---|---|---|
| A04 base de clientes | Dump lógico | `docker exec target-app-db mysqldump --all-databases` | Diario | Copia **fuera de `docker-host`** | 30 días | ❌ |
| A13 base de Keycloak | Dump lógico (usuarios, MFA) | `docker exec identity-db pg_dump -U keycloak keycloak` | Diario | Fuera de `docker-host` | 30 días | ❌ |
| A07 indexer (alertas) | Snapshot de índices `wazuh-alerts-*` | API de snapshots de OpenSearch (requiere `path.repo` en `opensearch.yml`, hoy no configurado) | Diario | Fuera de `docker-host` | 90 días (RF-15) | ❌ |
| A06 manager | Volúmenes `wazuh_etc` (incluye `client.keys`), `wazuh_logs` | `tar` del volumen con un contenedor temporal | Semanal y ante cambios | Fuera de `docker-host` | 30 días | ❌ |
| A17 secretos | `infra/*/.env` | Copia cifrada (ej. `gpg`) | Ante cambios | Fuera de `docker-host`, nunca en el repo | Vigente + anterior | ❌ |
| A18 router | `config.xml` de OPNsense | Exportación desde la consola / API | Ante cambios | Fuera del repo (canal privado) | Últimas 5 | 🔶 Existe una copia (02/10), sin procedimiento |
| A16 configuración | Repositorio | git + GitHub | Cada cambio | GitHub (fuera del sitio) | Indefinida | ✅ |

Requisito BCU de **copia fuera del centro de procesamiento**: hoy solo lo cumple el
repositorio. Para los datos, el destino fuera del sitio queda **a definir**.

## 3. Procedimiento de prueba de restauración

Se ejecuta antes de la auditoría (14/10) y después, una vez por trimestre.

| Paso | Descripción | Evidencia |
|---|---|---|
| 1 | Desplegar un entorno limpio con `vagrant up` y anotar el tiempo total | Log de `vagrant up` con hora de inicio y fin |
| 2 | Restaurar el dump de la base de clientes y contar registros | `SELECT COUNT(*)` antes y después |
| 3 | Restaurar el snapshot del indexer y buscar una alerta conocida (ej. CU-01 del 05/10) | Consulta en el dashboard |
| 4 | Restaurar `wazuh_etc` y verificar que el agente `ssh-client` reconecta sin re-enrolarse | `agent_control -l` |
| 5 | Comparar el tiempo total con el RTO de §1 | Firma del responsable |

Evidencias en `docs/evidencias/AAAA-MM-DD_DRP_*`. Estado: **no ejecutado**.

## 4. Escenarios y procedimientos de recuperación

| Escenario | Procedimiento | RTO | Responsable |
|---|---|---|---|
| Pérdida de `docker-host` | Nuevo host con 4 NICs (una por VLAN), clonar el repo, `make up`, restaurar datos (§2) | 2-4 h | Admin de infraestructura |
| Corrupción de la base de clientes | Detener `target-webapp`, restaurar el último dump, verificar conteo, reanudar | 4 h | Admin de infraestructura |
| Ransomware en un contenedor | Aislar (detener el contenedor y cortar su VLAN en el router), preservar evidencia (copia del volumen), **recrear desde la imagen**, nunca restaurar sobre el contenedor afectado; restaurar datos desde un respaldo anterior al incidente | 4 h | Analista SOC + Admin de infraestructura |
| Caída del SIEM | `cd infra/siem-hids && docker compose up -d`; si no levanta, recrear y restaurar snapshot; correr `configure-manager.sh` | 2 h | Admin de infraestructura |
| Caída del router | Restaurar `config.xml` en una OPNsense nueva (o router nftables de `vagrant/`) | 1 h | Admin de red |
| Cambio que rompe un control (ej. `ecf697c`, 06/10) | Revertir el commit en `main` y volver a correr `make up` | 1 h | RSI |

**Orden de reanudación** (dependencias reales del arranque): router → `identity` →
`nids` → `honeypot` → `siem-hids` → `mail` → `targets`. `nids` y `honeypot` van antes
que `siem-hids` porque el manager monta sus volúmenes de logs.

## 5. Comunicación de crisis

| Canal | Herramienta | Contacto |
|---|---|---|
| Correo de alerta | docker-mailserver (A11) | `soc@lab.local` |
| Si el correo también cayó | Teléfono / mensajería del equipo | RSI (rol sin asignar) |
| Estado de la plataforma | Dashboard de Wazuh (agentes y alertas) | `http://10.10.90.12:5601` |
| Comunicación a clientes y autoridades | Según `12-notificacion-incidentes.md` | RSI → Dirección |

El canal de voz previsto (Wazo) no está desplegado (recorte justificado, `brain/decisions.md`
2026-10-05).

---

## Check de aceptación

- [x] RTO/RPO definidos.
- [ ] Inventario de respaldo con ubicación off-site — definido; solo implementado para
  la configuración (repo).
- [ ] Prueba de restauración ejecutada y documentada — **no ejecutada**.
- [ ] Cumple requisito BCU de backups diarios y copia fuera del sitio — **no**.
