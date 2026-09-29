---
id: ipv6-configuracion-ios
tema: ipv6
subtema: configuracion
titulo: Configurar IPv6 en una interfaz Cisco IOS y verificarlo
nivel: basico
plataforma: ios
version: IOS / IOS XE
protocolo: ipv6
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ipv6, configurar, ipv6 unicast-routing, ipv6 address, show ipv6 interface brief, show ipv6 route, ping ipv6, cisco ios, interfaz
fuente: Cisco - Catalyst 2960-XR, Configuring IPv6 Unicast Routing | IPv6 addressing | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960xr/software/15-2_4_e/configuration_guide/b_1524e_consolidated_2960xr_cg/b_1524e_consolidated_2960xr_cg_chapter_010101.html
fuente: Cisco - Catalyst 3850, Configuring IPv6 Unicast Routing (IOS XE 16.12) | IPv6 unicast routing | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst3850/software/release/16-12/configuration_guide/ipv6/b_1612_ipv6_3850_cg/configuring_ipv6_unicast_routing.html
---
Pasos en un router Cisco (`ipv6 unicast-routing` habilita el reenvío de paquetes IPv6):
```
Router(config)# ipv6 unicast-routing
Router(config)# interface gigabitethernet0/0
Router(config-if)# ipv6 address 2001:db8:acad:1::1/64
Router(config-if)# ipv6 address fe80::1 link-local
Router(config-if)# no shutdown
```
Variantes de `ipv6 address`:
- Dirección completa: `ipv6 address 2001:db8:acad:1::1/64`.
- Con EUI-64: `ipv6 address 2001:db8:acad:1::/64 eui-64`.
- Solo link-local: `ipv6 enable` o `ipv6 address fe80::1 link-local`.

Verificación:
```
Router# show ipv6 interface brief
Router# show ipv6 interface gigabitethernet0/0
Router# show ipv6 route
Router# ping ipv6 2001:db8:acad:1::2
```
**Aviso para switches Catalyst 2960 reales:** la guía de Cisco indica que, para usar IPv4 e IPv6 a la vez (doble pila), el switch debe usar la plantilla SDM dual: `sdm prefer dual-ipv4-and-ipv6 default` (y recargar).
