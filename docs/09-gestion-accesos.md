# Gestión de Accesos e Identidades — FinSegura S.A.

> Plantilla base: `plantilla/isaca/09-gestion-accesos.md` (SI-IAM-09). Componente:
> Keycloak (`infra/identity/`, A12) y su base (A13).

## Encabezado de mapeo normativo

| Marco | Ítem | Detalle / aporte |
|---|---|---|
| **MCU 5.0 (función)** | **Proteger** | Protección del acceso y de las identidades. |
| **MCU 5.0 (categorías)** | PR-01, PR-02, PR-06, PR-07 | Identidad, credenciales, autenticación. |
| **COBIT 2019** | DSS05, APO13 | Gestión de accesos y usuarios. |
| **ISO/IEC 27001:2022** | A.5.15-A.5.18, A.8.2-A.8.5 | Control de accesos, privilegios, revisión. |
| **ISO/IEC 27002** | 5.15-5.19, 8.1-8.9 | Guía de implementación. |
| **BCU — GSI** | Autenticación y accesos | **Doble factor obligatorio** en operaciones críticas. |
| **URCDP — Ley 18.331** | Art. 9 y 12 | Seguridad de los datos personales. |

Requisito de la letra (RF-12, RNF-04): TOTP + WebAuthn/U2F configurables, Windows Hello
opcional, algoritmo de hash seleccionable (Argon2), MFA obligatorio para
administradores.

## Control del documento

| Campo | Valor |
|---|---|
| Código | SI-IAM-09 |
| Versión | 0.1 (borrador) |
| Responsable | Admin IAM (**rol sin asignar**, ver `excel/03` hoja Roles) |
| Fecha | 07/10/2026 |

**Estado al 07/10/2026:** Keycloak 26.0 corre (`10.10.90.20:8080`) con su base
PostgreSQL, pero **no hay realm, usuarios ni MFA configurados**. Este documento define
la política a implementar antes de la auditoría (14/10).

---

## 1. Modelo de autenticación

| Factor | Mecanismo | Cuándo |
|---|---|---|
| Algo que sé | Contraseña, almacenada con **Argon2** (política de contraseñas del realm: `hashAlgorithm`) | Todo inicio de sesión |
| Algo que tengo | **TOTP** (RFC 6238, app autenticadora) o llave **WebAuthn/FIDO2** | Todo inicio de sesión administrativo |
| Algo que soy | Windows Hello | **N.A. justificado**: no hay endpoints Windows con TPM en el laboratorio; WebAuthn ya cubre la clase de autenticador FIDO2 |

Keycloak trae nativos TOTP (*OTP Policy*) y WebAuthn (*WebAuthn Policy*); se exigen
como *Required Action* al primer login. El algoritmo de hash se elige en *Realm settings
→ Authentication → Policies → Password policy → Hashing algorithm* (opciones
`argon2`, `pbkdf2-sha512`, `pbkdf2-sha256`). **A verificar en la consola:** cuál viene
por defecto en Keycloak 26 y dejarlo fijado en `argon2` de forma explícita.

### Política de factores según operación

| Operación | Factor mínimo | Mecanismo |
|---|---|---|
| Consola de Keycloak (administración de identidades) | 2 factores | Contraseña + WebAuthn (TOTP como respaldo) |
| Dashboard de Wazuh (SIEM) | 2 factores | Contraseña + TOTP vía Keycloak (ver §1.1) |
| Administración del router | 2 factores | Contraseña + TOTP (OPNsense lo soporta nativo) |
| Acceso a `docker-host` | Llave SSH + origen restringido | Solo desde la VLAN de Gestión / el router |
| App de préstamos (usuarios internos) | 1 factor en el laboratorio | Fuera del alcance de RF-12 (administrativo) |

### 1.1 MFA en el dashboard de Wazuh: decisión pendiente

El dashboard corre **sin plugin de seguridad** (simplificación del 05/10,
`brain/LEARNINGS.md`): hoy no pide login y no puede autenticar contra Keycloak por sí
mismo. Opciones:

| Opción | Cómo | A favor | En contra |
|---|---|---|---|
| A. Reactivar el plugin de seguridad + OIDC contra Keycloak | Certificados internos + `opensearch_security.auth.type: openid` | Solución oficial de Wazuh; también da TLS al indexer (resuelve R09) | Más trabajo: certificados para indexer/manager/dashboard; se rompió una vez el 05/10 |
| B. Proxy de autenticación (`oauth2-proxy`) delante del dashboard | Contenedor nuevo en Gestión con IP fija; autentica contra Keycloak | Rápido; no toca el stack de Wazuh | El dashboard sigue alcanzable directo desde dentro de Gestión si no se restringe |

Recomendación para el 14/10: **B**, más una regla para que el dashboard solo acepte
conexiones del proxy. **A** queda como mejora posterior. Registrar la elección en
`brain/decisions.md`.

## 2. Gestión de identidades (provisión / desprovisión)

| Proceso | Procedimiento | Plazo |
|---|---|---|
| Alta de administrador | Lo pide el RSI; el Admin IAM crea el usuario en el realm `finsegura` con el rol mínimo y MFA obligatorio | Al asignarse el rol |
| Modificación de roles | Pedido al RSI, que lo aprueba; queda en el registro §3 | Bajo pedido |
| Baja | Deshabilitar en Keycloak y revocar llaves SSH | ≤ 24 h |
| Revisión de accesos | El RSI revisa §3 contra la RACI | Mensual, y antes de cada auditoría |

## 3. Registro de accesos

Usuarios administrativos **a crear** (ninguno existe al 07/10):

| Usuario | Rol | Recursos accesibles | Fecha alta | Fecha baja | Revisión |
|---|---|---|---|---|---|
| `admin-iam` | Admin IAM | Consola de Keycloak | — | — | — |
| `soc-analista` | Analista SOC | Dashboard de Wazuh (lectura y gestión de alertas) | — | — | — |
| `admin-red` | Admin de red | Router | — | — | — |
| `admin-infra` | Admin de infraestructura | `docker-host` (SSH) | — | — | — |

Se usan cuentas nominales por persona: los nombres de arriba son de rol, a reemplazar al
asignar los roles del equipo. Hoy se usan cuentas compartidas de laboratorio (`admin` de
Keycloak, API `wazuh-wui`), lo que va contra §4: dejarlas solo como cuentas de
emergencia.

## 4. Gestión de secretos y credenciales

- Credenciales de usuarios en Keycloak: hash **Argon2** (§1).
- Secretos de servicios en `infra/*/.env` dentro de `docker-host`; nunca en el repo
  (`.gitignore`). Los valores de `.env.example` (`changeme`) son **solo para levantar el
  laboratorio** y se cambian antes de cualquier uso (`03-analisis-riesgos.md` R02).
- Backup del router (`config.xml`): contiene hash de admin y API keys; fuera del repo, se
  comparte por canal privado.
- Prohibido: compartir cuentas personales, credenciales en texto plano en documentos o
  commits.

## 5. Política de contraseñas (por sistema)

| Sistema | Regla (password policy de Keycloak / equivalente) | Longitud | Complejidad | Ciclo de cambio |
|---|---|---|---|---|
| Administradores (realm `finsegura`) | `length(14) and upperCase(1) and lowerCase(1) and digits(1) and specialChars(1) and notUsername and passwordHistory(5) and hashAlgorithm(argon2)` | 14+ | Alta | 180 d, o ante sospecha de compromiso |
| Cuentas de servicio (`.env`) | Generadas al azar (`openssl rand -base64 24`) | 24+ | Aleatoria | Al desplegar un entorno nuevo |
| Puesto `target-ssh-client` | **Débil a propósito** (blanco de CU-02) | — | — | Riesgo aceptado: `03-analisis-riesgos.md` R03 |

## 6. Registro de autenticaciones (auditoría)

- Activar *Events → Save events* (login, login error, update TOTP) y *Admin events* en el
  realm.
- Llevarlos a Wazuh para CU-04: hoy Keycloak **no** envía logs al SIEM
  (`07-monitoreo-logs.md` §2).
- Alerta ante 5 fallos de login o de MFA consecutivos por usuario.

---

## Check de aceptación

- [ ] MFA obligatorio en al menos 2 operaciones críticas — definido (§1), **no
  implementado**.
- [ ] TOTP operativo con RFC 6238 — pendiente.
- [ ] Argon2/bcrypt para el hash de credenciales — definido, **a verificar** en Keycloak.
- [ ] Revisión de accesos con acta — pendiente.
- [ ] Registro de autenticaciones en el SIEM — pendiente.
