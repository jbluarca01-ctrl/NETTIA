---
id: ipv6-subneteo-48-a-64
tema: ipv6
subtema: subneteo
titulo: Subnetear IPv6: de /48 a /64
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
palabras_clave: ipv6, subneteo, subred, /48, /64, /56, id de subred, cuántas subredes, prefijo, plan de direccionamiento
fuente: RFC 4291 - IP Version 6 Addressing Architecture | §2.5.1 | https://www.rfc-editor.org/rfc/rfc4291
fuente: RFC 4193 - Unique Local IPv6 Unicast Addresses | §3.1 | https://www.rfc-editor.org/rfc/rfc4193
fuente: Cisco - Catalyst 2960-XR, Configuring IPv6 Unicast Routing | EUI-64 / 2000::/3 | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960xr/software/15-2_4_e/configuration_guide/b_1524e_consolidated_2960xr_cg/b_1524e_consolidated_2960xr_cg_chapter_010101.html
---
Una dirección global IPv6 tiene **64 bits de red/subred** y **64 bits de identificador de interfaz**: para todas las direcciones unicast que no empiezan por `000`, el ID de interfaz mide 64 bits (RFC 4291 §2.5.1). Por eso las subredes de usuarios son **/64**.

Si tu sitio tiene un prefijo **/48**, quedan **16 bits** para el ID de subred:
- Subredes /64 disponibles: 2^16 = **65 536**.
- Ejemplo con `2001:db8:acad::/48`:
  - `2001:db8:acad:0::/64`
  - `2001:db8:acad:1::/64`
  - `2001:db8:acad:2::/64`
  - …
  - `2001:db8:acad:ffff::/64`

Con un **/56** quedan 8 bits: 2^8 = 256 subredes /64.

Regla general: subredes = 2^(nuevo prefijo − prefijo actual). No se descuentan dirección de red ni de broadcast (IPv6 no tiene broadcast).
