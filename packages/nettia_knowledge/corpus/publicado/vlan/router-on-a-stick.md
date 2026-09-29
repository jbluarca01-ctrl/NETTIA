---
id: router-on-a-stick
tema: vlan
subtema: inter-vlan
titulo: Router-on-a-stick: enrutar entre VLAN con subinterfaces
nivel: intermedio
plataforma: ios
version: IOS / IOS XE
protocolo: 802.1q
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: router on a stick, router-on-a-stick, subinterfaz, encapsulation dot1q, inter-vlan, enrutamiento entre vlan, gateway, native
fuente: Cisco - IOS XE 17.x, Configuring Routing Between VLANs with IEEE 802.1Q Encapsulation | Routing between VLANs | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/lan-wan/b-lan-wan/m_lnsw-conf-vlan-ieee.html
fuente: Cisco - Configure Inter-VLAN Routing with an External Router (doc 14976) | Router-on-a-stick | https://www.cisco.com/c/en/us/support/docs/lan-switching/inter-vlan-routing/14976-50.html
---
Un solo enlace **trunk** entre el switch y el router; el router usa **una subinterfaz por VLAN** (cada una es el gateway de su VLAN).

Router:
```
Router(config)# interface gigabitethernet0/0
Router(config-if)# no shutdown
Router(config-if)# interface gigabitethernet0/0.10
Router(config-subif)# encapsulation dot1Q 10
Router(config-subif)# ip address 10.10.10.1 255.255.255.0
Router(config-subif)# interface gigabitethernet0/0.20
Router(config-subif)# encapsulation dot1Q 20
Router(config-subif)# ip address 10.10.20.1 255.255.255.0
```
Switch (puerto hacia el router):
```
Switch(config-if)# switchport mode trunk
```
Puntos clave de la documentación de Cisco:
- Cada subinterfaz necesita un **ID de VLAN distinto** en `encapsulation dot1Q`.
- Para la VLAN nativa se usa la palabra `native`: `encapsulation dot1Q 1 native`. Si una subinterfaz es nativa, la interfaz física no puede llevar dirección IP.
- Un error común es **no hacer coincidir la VLAN nativa** entre router y switch.
- Los hosts de cada VLAN usan la IP de su subinterfaz como gateway.

Verificación: `show ip route`, `show interface`, `show vlans` en el router y `show interfaces gigabitethernet0/1 switchport` en el switch.
