# Reproducción portable (VirtualBox/Vagrant) — para el Red Team

Esta carpeta NO es la infraestructura del Blue Team (esa vive en Proxmox, ver
`../infra/README.md`). Es una **copia reproducible en VirtualBox** de la misma
arquitectura (mismas 4 VLANs, mismas IPs, mismos stacks Docker) para que el Red Team la
levante en su propia máquina y la ataque sin depender del Proxmox compartido.

## Por qué no es 100% idéntica

| Pieza | Blue Team (Proxmox) | Acá (VirtualBox) | Por qué |
|---|---|---|---|
| Router | OPNsense/pfSense (VM) | **OPNsense real, importando el `config.xml` real** (opción A) o VM Linux + nftables (opción B, fallback automatizable) | Ver abajo. |
| docker-host | LXC privilegiado | VM completa | VirtualBox no tiene LXC. Por eso pide más RAM (no hay kernel compartido). |
| Todo lo demás | Docker Compose | Docker Compose (los mismos `docker-compose.yml`) | Idéntico — por eso el resto de la arquitectura es fiel. |

## Router — opción A (recomendada): OPNsense real con el config real importado

Se bajó el `config.xml` real de `opnrouter` vía su API (`/api/core/backup/download/this`).
**Ese archivo NO está en este repo** (trae el hash de la contraseña de admin y las API
keys) — pedírselo al Blue Team por un canal privado (no git).

Mapeo de interfaces confirmado (importa limpio si se arma la VM en este mismo orden):

| Interfaz OPNsense | NIC (virtio) | Rol | IP |
|---|---|---|---|
| WAN | `vtnet0` | Internet | DHCP |
| LAN | `vtnet1` | Servidores | 10.10.10.254 |
| OPT1 | `vtnet2` | DMZ | 10.10.20.254 |
| OPT2 | `vtnet3` | Usuarios | 10.10.30.254 |
| OPT3 | `vtnet4` | Gestión | 10.10.90.254 |

Pasos:
1. Descargar el ISO de OPNsense (opnsense.org/download) e instalarlo en una VM nueva de
   VirtualBox — instalador rápido (~10 min), casi todo por defecto.
2. Antes de instalar, agregarle **5 adaptadores de red**, todos tipo
   **"Paravirtualized Network (virtio-net)"** (no el Intel PRO/1000 por defecto) y **en
   este orden**: NAT (o Bridged, para que WAN tenga internet real) → Internal Network
   `vlan_srv` → `vlan_dmz` → `vlan_usr` → `vlan_mgmt` (mismos nombres que usa
   `docker-host` en el `Vagrantfile` de esta carpeta). El orden importa: define qué
   `vtnetN` es cuál.
3. Instalado OPNsense, entrar a su consola (usuario/pass por defecto `installer`/
   `opnsense`, se pide cambiar) solo para confirmar que asignó las interfaces en el
   mismo orden — no hace falta configurar nada más ahí.
4. Entrar a la UI web → **System → Configuration → Backups** (o **Diagnostics → Config
   History**, según versión) → **Restore configuration** → subir el `config.xml` que te
   pasó el Blue Team.
5. Reiniciar. Debería quedar con las mismas 4 VLANs, mismas reglas de firewall y mismo
   NAT que la `opnrouter` real.

Si algún `vtnetN` no coincide (quedó una interfaz sin red real detrás), reasignar a mano
en **Interfaces → Assignments** — 2 minutos, no bloquea nada más.

## Router — opción B (fallback 100% automatizado): nftables

Si no querés/podés instalar OPNsense a mano, `vagrant up` sigue levantando una VM Linux
con nftables en vez de OPNsense — ver `Vagrantfile`/`provision-router.sh`. Mismo
comportamiento de red (NAT + segmentación por VLAN), pero si algún hallazgo del Red Team
depende de una particularidad específica de OPNsense (un paquete, una regla del panel),
**no se va a reproducir con esta opción** — avisar al Blue Team para validarlo en su
Proxmox real.

## Requisitos

- VirtualBox + Vagrant instalados.
- **~12 GB de RAM libres** (docker-host pide 10 GB, el router 1 GB, más el margen del
  host). Si la máquina tiene menos, bajar `vb.memory` en el `Vagrantfile` — Wazuh es lo
  que más pesa, se puede probar con 6-7 GB si hace falta ajustar.
- Conexión a internet (`vagrant up` descarga el box + todas las imágenes Docker la
  primera vez — puede tardar 10-15 min).

## Uso

```bash
cd vagrant/
vagrant up
```

Levanta 2 VMs: `router` y `docker-host`. El segundo clona el repo entero vía carpeta
compartida (no hace falta `git clone` aparte) y levanta todos los stacks automáticamente
(mismo proceso que se hizo a mano en Proxmox, pero con los fixes ya aplicados de entrada
— ver `../brain/LEARNINGS.md`).

Al terminar, `vagrant up` imprime las URLs (dashboard de Wazuh, app de préstamos, etc.).

## Cómo sumar la máquina atacante (Red Team)

Las 4 VLANs internas (`vlan_srv`, `vlan_dmz`, `vlan_usr`, `vlan_mgmt`) son redes
**Internal Network** de VirtualBox — aisladas, no llegan ni desde ni hacia tu máquina
anfitriona por defecto. Para atacar como si vinieras "de internet", el router expone una
quinta red, `vlan_wan` (203.0.113.0/24, rango reservado para documentación — no es
internet real), pensada para que sumes tu propia VM de ataque (Kali u otra) ahí:

1. VirtualBox → tu VM atacante → Settings → Network → una NIC → "Internal Network" →
   nombre **`vlan_wan`**.
2. Dentro de esa VM, configurar IP estática en `203.0.113.0/24` (ej. `203.0.113.100/24`,
   gateway `203.0.113.254`).
3. Desde ahí, atacar lo que el router deja pasar hacia la DMZ: mail (25/587/993), Wazo
   (5060), honeypot (2222/2223) — igual que un atacante real de internet contra esta
   consigna. Ver `../docs/40-consigna-propia.md` §3 para los 5 casos de uso y
   `../docs/00-arquitectura.md` para el detalle de IPs de cada servicio.

Si en algún caso de uso hace falta simular un atacante que YA está adentro de una VLAN
(ej. un puesto comprometido en Usuarios, para CU-02), sumar esa VM a la Internal Network
correspondiente (`vlan_usr`, etc.) en vez de `vlan_wan`.

## Troubleshooting

- Mismos problemas que documentamos en Proxmox pueden aparecer acá (certs de mail,
  `vm.max_map_count` de Wazuh, Suricata con mounts `:ro`) — el script de provisioning ya
  los resuelve de entrada, pero si algo falla, `../brain/LEARNINGS.md` tiene el
  diagnóstico de cada uno.
- `vagrant reload <nombre-vm>` reinicia una VM sin recrearla. `vagrant destroy -f &&
  vagrant up` empieza de cero si algo quedó en mal estado.
- Si el provisioning de `docker-host` falla porque las NICs todavía no tienen IP, correr
  `vagrant provision docker-host` de nuevo (el script ya tiene un reintento de 60s, pero
  por las dudas).
