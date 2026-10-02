# TSI-2026-Infra — orientación para asistentes de IA

Repo de la **Tarea 3 (Blue Team)** del curso Seguridad de la Información: una
infraestructura de red de defensa (router/firewall + Docker con Wazuh, Suricata, Keycloak,
mail, honeypot y blancos vulnerables) y su documentación formal. Equipo de 2 personas,
escribir en español rioplatense. Cada integrante despliega su propio entorno; el camino
estándar es **VirtualBox + Vagrant** (`vagrant/`).

## Leer en este orden

1. `README.md` — estado actual, pendientes, direcciones de los servicios.
2. `brain/MEMORY.md` — foto del estado actual: red, IP de cada contenedor, credenciales.
3. `brain/notes/plan-recuperacion-atraso.md` — qué está hecho y qué falta antes del
   freeze del **07/10/2026**.
4. Según la tarea: `vagrant/README.md` (levantar todo desde cero), `infra/README.md`
   (qué corre adentro de docker-host), `docs/` (entregables), `LETRA.md` (consigna).
5. Antes de tocar infra: `brain/LEARNINGS.md` — errores ya pisados con su causa. Antes
   de cambiar una decisión: `brain/decisions.md` — por qué se hizo así.

## Reglas

- **Nunca commitear secretos.** El repo es público. `.env`, certs de mail y backups
  `config.xml` de OPNsense están en `.gitignore`; no forzarlos.
- No editar `LETRA.md` (fuente oficial). Los docs de `docs/` siguen las plantillas
  ISACA del curso, que no están en este repo.
- Si la documentación contradice al código, manda el código: corregir el doc (sobre todo
  `brain/MEMORY.md`) en el mismo cambio.
- Cambios de arquitectura → entrada fechada en `brain/decisions.md` (no reescribir
  entradas viejas). Errores nuevos resueltos → `brain/LEARNINGS.md`.
- Todo contenedor nuevo con IP fija (ver `brain/MEMORY.md`).
- No inventar estado: si algo no se verificó, decirlo ("no verificado").

## Trampas conocidas (detalle en `brain/LEARNINGS.md`)

- VLAN **10 = Servidores, 20 = DMZ** (no al revés).
- Las redes Docker son macvlan y se crean con `infra/create-networks.sh` (lo hace
  `make up`), no con `docker-compose.networks.yml` (ese archivo es solo referencia).
- Macvlan: **`docker-host` no puede hablar con sus propios contenedores**. Probar los
  servicios desde el router u otra VM (en VirtualBox: túnel `vagrant ssh router -- -L ...`).
- En VirtualBox, las NIC de VLAN de `docker-host` necesitan modo promiscuo "allow-all"
  (el `Vagrantfile` lo pone); sin eso los contenedores no responden desde afuera.
- Un contenedor Docker ve cada red como `eth0`, `eth1`... propio, no con el nombre del
  host: por eso Suricata está en una sola red.
- `cd X && docker compose up -d && cd ..` corta la cadena si falla el compose — usar
  `make up` o rutas absolutas.
