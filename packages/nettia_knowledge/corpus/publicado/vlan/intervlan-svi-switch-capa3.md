---
id: intervlan-svi-switch-capa3
tema: vlan
subtema: inter-vlan
titulo: Enrutar entre VLAN con SVI en un switch de capa 3
nivel: intermedio
plataforma: ios-xe
version: IOS XE 17.9.x
protocolo: vlan
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: inter-vlan, svi, interface vlan, ip routing, switch capa 3, multilayer, gateway por vlan, no switchport, routed port
fuente: Cisco - Configure Inter-VLAN Routing with Catalyst Switches | Configure / Verify | https://www.cisco.com/c/en/us/support/docs/lan-switching/inter-vlan-routing/41260-189.html
fuente: Cisco Catalyst 9300 - Interface and Hardware Components Configuration Guide, IOS XE 17.9.x | Configuring Interface Characteristics - Switch Virtual Interfaces | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9300/software/release/17-9/configuration_guide/int_hw/b_179_int_and_hw_9300_cg/configuring_interface_characteristics.html
---
En un switch de capa 3 no hace falta un router externo (router-on-a-stick) para comunicar VLAN distintas: cada VLAN tiene su propia **SVI** (*Switch Virtual Interface*), una interfaz lógica `interface vlan X` que funciona como el gateway de esa VLAN.

```
Switch(config)# ip routing
!
Switch(config)# interface vlan 10
Switch(config-if)# ip address 192.168.10.1 255.255.255.0
Switch(config-if)# no shutdown
!
Switch(config)# interface vlan 20
Switch(config-if)# ip address 192.168.20.1 255.255.255.0
Switch(config-if)# no shutdown
```

- **`ip routing`** (modo global) es obligatorio: sin él, el switch se comporta como uno de capa 2 y **no enruta** entre las VLAN aunque las SVI tengan IP.
- Cada host usa como **default gateway la IP de la SVI de su VLAN** (en el ejemplo, 192.168.10.1 para la VLAN 10).
- Una SVI solo sube (up/up) si **la VLAN existe y tiene al menos un puerto activo** en estado *forwarding* de STP. Una SVI "down" suele significar que falta crear la VLAN o que no hay ningún puerto conectado en ella.
- La SVI de la **VLAN 1** existe por defecto (para administración) y no se puede borrar.
- Diferencia con un **routed port**: la SVI representa a toda una VLAN (varios puertos); un routed port es **un solo puerto físico** pasado a capa 3 con `no switchport` y con IP propia, sin VLAN asociada.

Verificación:
```
Switch# show ip interface brief
Switch# show ip route
```
