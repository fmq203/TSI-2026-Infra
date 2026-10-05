# Despliegue desde cero en VirtualBox

Camino para levantar **toda la infraestructura en tu propia máquina**, sin acceso a
ningún otro servidor. Sirve para el Blue Team (construir y probar) y para el Red Team
(atacar una copia). Misma arquitectura que `../docs/00-arquitectura.md`: 4 VLANs, mismas
IPs, mismos stacks Docker de `../infra/`.

## Requisitos de tu máquina

- **CPU x86_64 (Intel/AMD)** con virtualización activada en la BIOS (VT-x / AMD-V).
  VirtualBox **no** corre estas VMs en Mac con chip Apple (M1/M2/M3).
- **16 GB de RAM o más.** `docker-host` pide 10 GB (Wazuh es lo pesado) + 1 GB el router
  + lo que use tu sistema. Con menos RAM, bajarlo así (Wazuh puede quedar justo):
  `DOCKER_HOST_MEM=7168 vagrant up` (en PowerShell: `$env:DOCKER_HOST_MEM=7168; vagrant up`).
- ~30 GB de disco libre.
- [VirtualBox 7.x](https://www.virtualbox.org/wiki/Downloads) y
  [Vagrant 2.4+](https://developer.hashicorp.com/vagrant/install).
- **Windows:** si tenés Hyper-V, WSL2 o "Plataforma de máquina virtual" activados,
  VirtualBox puede andar muy lento o no arrancar las VMs. Si pasa, desactivarlos
  (Características de Windows) y reiniciar.
- Internet (la primera vez baja el box de Debian y ~5 GB de imágenes Docker).

## Qué se levanta

| VM | Qué es | Redes |
|---|---|---|
| `router` | Debian + nftables: NAT, segmentación y firewall entre VLANs | `vlan_wan` + las 4 VLANs |
| `docker-host` | Debian + Docker con todos los stacks (`make up` de `../infra/`) | las 4 VLANs |

| Red de VirtualBox | VLAN | Subred | Gateway |
|---|---|---|---|
| `vlan_wan` | "Internet simulada" (de acá ataca el Red Team) | `203.0.113.0/24` | `.254` |
| `vlan_srv` | Servidores | `10.10.10.0/24` | `.254` |
| `vlan_dmz` | DMZ | `10.10.20.0/24` | `.254` |
| `vlan_usr` | Usuarios | `10.10.30.0/24` | `.254` |
| `vlan_mgmt` | Gestión | `10.10.90.0/24` | `.254` |

Son redes **internas** de VirtualBox ("Internal Network"): no se ven desde tu máquina,
solo entre VMs. Ver "Cómo entrar a las consolas" abajo.

## Uso

```bash
git clone https://github.com/fmq203/TSI-2026-Infra.git
cd TSI-2026-Infra/vagrant
vagrant up
```

Tarda 15-30 min la primera vez. `docker-host` clona este mismo repo de GitHub
adentro (en `/opt/TSI-2026-Infra`) y corre `make up`. Si trabajás en un fork, pasá
`REPO_URL=https://github.com/<vos>/<fork>.git vagrant up`.

Comandos útiles:

```bash
vagrant status                       # estado de las VMs
vagrant ssh docker-host              # entrar; adentro: sudo docker ps
vagrant provision docker-host        # re-correr la instalación (es idempotente)
vagrant halt                         # apagar todo
vagrant destroy -f && vagrant up     # empezar de cero
```

Para aplicar cambios del repo dentro de `docker-host`: `vagrant ssh docker-host`, y ahí
`cd /opt/TSI-2026-Infra && sudo git pull && cd infra && sudo make up`.

## Cómo entrar a las consolas

Las VLANs no se ven desde tu máquina, y **`docker-host` tampoco puede hablar con sus
propios contenedores** (limitación de las redes macvlan: el host y sus contenedores no
se ven entre sí). El router sí los ve a todos, así que se pasa por él con un túnel SSH.
Desde la carpeta `vagrant/`, dejá esto corriendo en una terminal:

```bash
vagrant ssh router -- -N -L 5601:10.10.90.12:5601 -L 8080:10.10.90.20:8080 -L 8081:10.10.10.10:80
```

| Servicio | En tu navegador | Credenciales por defecto |
|---|---|---|
| Wazuh dashboard | <http://localhost:5601> (tarda ~1 min en levantar) | sin login (plugin de seguridad desactivado). API: `wazuh-wui` / `WAZUH_API_PASSWORD` de `infra/siem-hids/.env` |
| Keycloak (admin) | <http://localhost:8080> | `admin` / `changeme`. *No verificado:* Keycloak está configurado con hostname `auth.lab.local`; si redirige ahí, agregar `127.0.0.1 auth.lab.local` al archivo hosts de tu máquina y entrar por `http://auth.lab.local:8080` |
| App de préstamos (DVWA) | <http://localhost:8081> | `admin` / `password` (DVWA por defecto; la primera vez pide "Create / Reset Database") |

Para el resto (SSH víctima, honeypot, mail) lo más cómodo es una VM extra conectada a la
VLAN que corresponda (ver "Sumar una VM atacante o de administración"). Si reemplazaste
el router por una OPNsense, no hay `vagrant ssh router`: usá esa VM extra.

Los `.env` reales quedan dentro de `docker-host` en `/opt/TSI-2026-Infra/infra/*/.env`,
copiados de los `.env.example` (contraseñas de laboratorio — cambiarlas antes de la
auditoría).

## Sumar una VM atacante o de administración

Cualquier VM (Kali, un Ubuntu con escritorio, etc.) se suma creándola en VirtualBox y en
**Configuración → Red → Adaptador → "Red interna"** eligiendo el nombre:

| Para... | Red interna | IP estática de ejemplo | Gateway |
|---|---|---|---|
| Atacar como si vinieras de internet (Red Team, CU-01) | `vlan_wan` | `203.0.113.100/24` | `203.0.113.254` |
| Simular un puesto de usuario comprometido (CU-02) | `vlan_usr` | `10.10.30.100/24` | `10.10.30.254` |
| Administrar Wazuh y Keycloak sin túnel (están en Gestión) | `vlan_mgmt` | `10.10.90.100/24` | `10.10.90.254` |

Desde `vlan_wan` el router solo deja pasar lo que una DMZ real publicaría: mail
(`10.10.20.20` puertos 25/587/993), honeypot (`10.10.20.30` puertos 2222/2223) y Wazo
(UDP 5060, cuando exista).

## Probar la detección (CU-01: reconocimiento)

Cadena probada en el despliegue de referencia el 2026-10-05: escaneo → firma propia de
Suricata (`infra/nids/rules/local.rules`) → regla 86601 de Wazuh → alerta en el dashboard
(**Threat Hunting**, filtro `rule.groups: suricata`, rango "Today"; aparecen como *low
severity*, nivel 3).

Dos cosas que hay que saber antes de probar (detalle en `../brain/LEARNINGS.md`):

- **Suricata solo ve el tráfico dirigido a su propia IP, `10.10.20.50`** (es un
  contenedor macvlan más en la DMZ, no recibe un espejo del tráfico). Atacar esa IP.
- **El firewall tiene que dejar pasar el ataque hasta ahí.** Desde `vlan_wan` el router
  solo deja pasar los puertos publicados de la DMZ: un `ping` o un `nmap -sS -p 1-1000`
  no llegan y Suricata no ve casi nada (pasó lo mismo con OPNsense en el despliegue de
  referencia y llevó un buen rato darse cuenta).

La forma más simple: atacar **desde el router** (su tráfico propio no pasa por el
filtro), desde la carpeta `vagrant/`:

```bash
vagrant ssh router -- "sudo apt-get install -y -qq nmap && ping -c 20 -i 0.2 10.10.20.50 && sudo nmap -sS -p 1-1000 10.10.20.50"
```

Desde una VM atacante en `vlan_wan` (más realista, como un atacante de internet), usar
escaneos que entren por los puertos publicados:

```bash
sudo nmap -sN -p 25,587,993 10.10.20.50    # NULL → regla 1000002
sudo nmap -sF -p 25,587,993 10.10.20.50    # FIN  → regla 1000003
```

Si usás OPNsense como router y atacás desde otra VLAN, agregá una regla temporal de paso
hacia `10.10.20.50` (y borrala después).

Verificar en orden si no aparece nada (todo con `vagrant ssh docker-host`, luego `sudo -i`):

```bash
docker exec suricata grep -c '"event_type":"alert"' /var/log/suricata/eve.json   # ¿Suricata detectó?
docker exec suricata grep '"src_ip":"<IP atacante>"' /var/log/suricata/eve.json | tail -3   # ¿llegó el tráfico, a qué puertos?
docker exec wazuh.manager grep -c suricata /var/ossec/logs/alerts/alerts.json    # ¿Wazuh la procesó?
docker exec wazuh.manager curl -s "http://wazuh.indexer:9200/_cat/indices/wazuh-alerts*?v"   # ¿llegó al indexer?
```

## Probar la respuesta automática (CU-02: fuerza bruta SSH)

Cadena: muchos logins SSH fallidos contra `target-ssh-client` (`10.10.30.10:2222`) → el
agente Wazuh de ese contenedor manda su `auth.log` → reglas estándar de sshd **5763** /
**5712** (nivel 10) → **Active Response `firewall-drop`**: el agente agrega un `DROP` de
iptables para la IP atacante durante 10 min → el manager manda un mail a
`soc@lab.local`. (Construido 2026-10-05; **no verificado todavía de punta a punta**.)

Antes de atacar, verificar que el agente quedó enrolado y conectado:

```bash
docker exec wazuh.manager /var/ossec/bin/agent_control -l    # debe listar "ssh-client", Active
```

Si no aparece: el router no deja pasar Usuarios → Gestión 1514/1515 (en nftables ya está;
en OPNsense ver la tabla de abajo), o mirar `docker logs target-ssh-client`.

Ataque desde el router (8+ contraseñas incorrectas en menos de 2 min alcanzan; la
contraseña real está en `infra/targets/.env`):

```bash
vagrant ssh router -- "sudo apt-get install -y -qq sshpass && for i in \$(seq 1 12); do sshpass -p incorrecta\$i ssh -p 2222 -o StrictHostKeyChecking=no labuser@10.10.30.10 true; done"
```

(También sirve `hydra` desde una VM en `vlan_usr`.) Lo que se tiene que ver:

```bash
docker exec target-ssh-client iptables -L INPUT -n          # DROP con la IP atacante
docker exec target-ssh-client tail /var/ossec/logs/active-responses.log
docker exec wazuh.manager grep -E '"id":"(5763|5712)"' /var/ossec/logs/alerts/alerts.json | tail -1
```

En el dashboard: **Threat Hunting**, filtro `rule.id: 5763`, y la fila de Active Response
(`rule.id: 651`, "Host Blocked by firewall-drop"). A los 10 min el bloqueo se levanta solo.

## Router: nftables (por defecto) u OPNsense (manual)

`vagrant up` usa un router **Linux con nftables**, 100% automático. La letra sugiere
**OPNsense / pfSense / IPFire** como firewall: si este entorno de VirtualBox es el que se
va a mostrar en la auditoría, conviene reemplazarlo por una OPNsense. No hay box de
Vagrant para OPNsense, así que es manual (~30 min):

1. Levantar solo `docker-host`: `vagrant up docker-host` (si ya levantaste el router:
   `vagrant destroy -f router`; los dos no pueden convivir, ambos usan las `.254`).
2. Bajar el ISO de [opnsense.org](https://opnsense.org/download/) (tipo *dvd*, amd64) y
   crear una VM en VirtualBox: tipo FreeBSD 64-bit, 2 GB RAM, 20 GB disco, **5
   adaptadores de red** en este orden, todos tipo *Paravirtualized Network (virtio-net)*
   para que OPNsense los vea como `vtnet0`..`vtnet4`:

   | Adaptador | Red interna | Interfaz OPNsense | IP |
   |---|---|---|---|
   | 1 | `vlan_wan` | WAN | `203.0.113.254/24` (estática, sin gateway) |
   | 2 | `vlan_srv` | LAN (Servidores) | `10.10.10.254/24` |
   | 3 | `vlan_dmz` | OPT1 (DMZ) | `10.10.20.254/24` |
   | 4 | `vlan_usr` | OPT2 (Usuarios) | `10.10.30.254/24` |
   | 5 | `vlan_mgmt` | OPT3 (Gestión) | `10.10.90.254/24` |

3. Instalar (usuario `installer` / `opnsense`), asignar interfaces e IPs desde la consola
   (opciones 1 y 2 del menú), y entrar a la web desde una VM en `vlan_srv`:
   `https://10.10.10.254` (usuario `root`).
4. En **Interfaces → WAN**: destildar *Block private networks* y **Block bogon
   networks** (`203.0.113.0/24` está en la lista de bogons y si no se destilda, todo lo
   que llegue del atacante se descarta).
5. Habilitar OPT1/OPT2/OPT3 y crear las reglas de **Firewall → Rules** (OPNsense ya
   deja a la LAN salir a todo por defecto; las OPT arrancan bloqueadas):

   | Interfaz | Acción | Protocolo | Destino | Puertos |
   |---|---|---|---|---|
   | WAN | Pass | TCP | `10.10.20.20` | 25, 587, 993 |
   | WAN | Pass | TCP | `10.10.20.30` | 2222, 2223 |
   | WAN | Pass | UDP | `10.10.20.40` | 5060 (cuando exista Wazo) |
   | OPT2 (Usuarios) | Pass | TCP | `10.10.10.10` | 80, 443 |
   | OPT2 (Usuarios) | Pass | TCP | `10.10.90.10` | 1514, 1515 (agente Wazuh) |
   | OPT3 (Gestión) | Pass | TCP | `10.10.20.20` | 25 (mails de alerta de Wazuh) |
   | OPT1 (DMZ) | — | — | — | sin reglas: solo responde, no inicia (igual que nftables) |

   Es el mismo criterio de `../docs/40-consigna-propia.md` §2 y de `provision-router.sh`.

Si el otro integrante te pasa un backup `config.xml` de su OPNsense, se puede importar
en **System → Configuration → Backups → Restore** en vez del paso 5, pero revisá después
la WAN (su WAN usa DHCP, acá es estática) y las asignaciones de interfaz. Ese archivo
trae hashes de contraseñas: **nunca subirlo al repo** (ya está en `.gitignore`).

Diferencia a tener en cuenta con nftables: si un hallazgo del Red Team depende de algo
propio de OPNsense (un paquete, una regla del panel), con el router nftables no se
reproduce.

## Problemas conocidos

- **`vagrant up` se queda en "Waiting for machine to boot"**: la virtualización por
  hardware no llega a VirtualBox. En Windows, ver Hyper-V/WSL2 arriba. No funciona
  dentro de otra VM (VirtualBox anidado en KVM/Proxmox cuelga siempre en el mismo punto
  del arranque — probado, ver `../brain/LEARNINGS.md`).
- **Un contenedor arranca pero no responde desde otra VM**: revisar que las NIC 2-5 de
  `tarea3-docker-host` tengan *Modo promiscuo: Permitir todo* (el `Vagrantfile` lo
  configura; si se recreó la VM a mano, hay que ponerlo).
- **Wazuh: "connection refused" entre manager/dashboard e indexer en el primer
  minuto**: normal, esperar.
- **Scripts que fallan con `^M` o "bad interpreter"**: el repo se clonó en Windows con
  conversión de fin de línea. Ya hay un `.gitattributes` que lo evita; si pasa igual,
  volver a clonar.
- Resto de errores ya vistos y su causa: `../brain/LEARNINGS.md`.
