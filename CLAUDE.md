# TSI-2026-Infra — orientación para asistentes de IA

Repo de la **Tarea 3 (Blue Team)** del curso Seguridad de la Información: una
infraestructura de red de defensa real (OPNsense + Docker con Wazuh, Suricata, Keycloak,
mail, honeypot y blancos vulnerables) desplegada en un Proxmox, más su documentación
formal. Equipo de 2 personas, escribir en español rioplatense.

## Leer en este orden

1. `README.md` — estado actual, cómo llegar a cada consola, pendientes de seguridad.
2. `brain/MEMORY.md` — foto del estado actual: IDs de Proxmox, VLANs, IP de cada
   contenedor, dónde están las credenciales.
3. `brain/notes/plan-recuperacion-atraso.md` — qué está hecho y qué falta antes del
   freeze del **07/10/2026**.
4. Según la tarea: `infra/README.md` (despliegue), `docs/` (entregables),
   `vagrant/README.md` (copia portable para el Red Team), `LETRA.md` (consigna oficial).
5. Antes de tocar infra: `brain/LEARNINGS.md` — errores ya pisados con su causa. Antes
   de cambiar una decisión: `brain/decisions.md` — por qué se hizo así.

## Reglas

- **Nunca commitear secretos.** El repo es público. `.env`, certs de mail y backups
  `config.xml` de OPNsense están en `.gitignore`; no forzarlos.
- **No tocar VMs/CTs de Proxmox que no sean de esta tarea** (ver tabla en
  `brain/MEMORY.md`). El nodo es compartido con proyectos personales y otras materias.
- No editar `LETRA.md` (fuente oficial). Los docs de `docs/` siguen las plantillas
  ISACA del curso, que no están en este repo.
- Si algo de la documentación contradice al código o a lo que está corriendo, manda lo
  real: corregir el doc (sobre todo `brain/MEMORY.md`) en el mismo cambio.
- Cambios de arquitectura → agregar entrada fechada en `brain/decisions.md` (no
  reescribir entradas viejas). Errores nuevos resueltos → `brain/LEARNINGS.md`.
- No inventar estado: si algo no se verificó, decirlo ("no verificado").

## Trampas conocidas (detalle en `brain/LEARNINGS.md`)

- VLAN **10 = Servidores, 20 = DMZ** (no al revés).
- Las redes Docker se crean con `infra/create-networks.sh`, no con
  `docker-compose.networks.yml` (ese archivo es solo referencia).
- `docker-host` tiene que ser LXC **privilegiado** (lo exige `docker-mailserver`), y eso
  solo se puede crear con `pct create` desde la shell del host — ningún token de API
  puede.
- Un contenedor Docker ve cada red como `eth0`, `eth1`... propio, no con el nombre del
  host: por eso Suricata está en una sola red.
- `cd X && docker compose up -d && cd ..` corta la cadena si falla el compose — usar
  rutas absolutas o `make up`.
