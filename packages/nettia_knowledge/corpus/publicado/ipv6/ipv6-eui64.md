---
id: ipv6-eui64
tema: ipv6
subtema: eui-64
titulo: EUI-64: identificador de interfaz a partir de la MAC
nivel: intermedio
plataforma: generico
version: -
protocolo: ipv6
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ipv6, eui-64, eui64, mac, identificador de interfaz, fffe, bit universal local, u/l
fuente: RFC 4291 - IP Version 6 Addressing Architecture | Apéndice A | https://www.rfc-editor.org/rfc/rfc4291
fuente: Cisco - Catalyst 2960-XR, Configuring IPv6 Unicast Routing | ipv6 address eui-64 | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960xr/software/15-2_4_e/configuration_guide/b_1524e_consolidated_2960xr_cg/b_1524e_consolidated_2960xr_cg_chapter_010101.html
---
El **EUI-64 modificado** convierte una MAC de 48 bits en un identificador de interfaz de 64 bits (RFC 4291, Apéndice A):
1. Se parte la MAC por la mitad.
2. Se inserta `ff:fe` en medio.
3. Se **invierte el 7.º bit** del primer byte (el bit universal/local).

Ejemplo con la MAC `00:1A:2B:3C:4D:5E`:
- Con `ff:fe` en medio: `00:1A:2B:FF:FE:3C:4D:5E`.
- El primer byte `00` pasa a `02` al invertir el bit: identificador `021a:2bff:fe3c:4d5e`, que abreviado es `21a:2bff:fe3c:4d5e`.
- Con el prefijo `2001:db8:acad:1::/64` la dirección queda `2001:db8:acad:1:21a:2bff:fe3c:4d5e`.

En Cisco IOS basta el prefijo; los últimos 64 bits se calculan solos desde la MAC de la interfaz:
```
Router(config-if)# ipv6 address 2001:db8:acad:1::/64 eui-64
```
