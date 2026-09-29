---
id: ipv6-link-local
tema: ipv6
subtema: link-local
titulo: Dirección link-local (fe80::/10)
nivel: basico
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
palabras_clave: ipv6, link-local, fe80, enlace local, ndp, automática, ipv6 enable
fuente: RFC 4291 - IP Version 6 Addressing Architecture | §2.1, §2.5.6 | https://www.rfc-editor.org/rfc/rfc4291
fuente: RFC 4862 - IPv6 Stateless Address Autoconfiguration | §5.3 | https://www.rfc-editor.org/rfc/rfc4862
fuente: Cisco - Catalyst 2960-XR, Configuring IPv6 Unicast Routing | link-local | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960xr/software/15-2_4_e/configuration_guide/b_1524e_consolidated_2960xr_cg/b_1524e_consolidated_2960xr_cg_chapter_010101.html
---
- **Toda interfaz con IPv6 debe tener al menos una dirección link-local** (RFC 4291 §2.1). Empieza por `fe80::/10`.
- Se forma **automáticamente** cuando la interfaz se habilita: prefijo `fe80::/10` + identificador de interfaz (RFC 4862 §5.3).
- Solo vale en el **enlace local**: un router no la reenvía a otras redes.
- Se usa en el descubrimiento de vecinos (NDP) y en la autoconfiguración.

En Cisco IOS puedes fijarla a mano (más fácil de leer y recordar) o dejar que se genere sola:
```
Router(config-if)# ipv6 address fe80::1 link-local
Router(config-if)# ipv6 enable
```
`ipv6 enable` genera la link-local automáticamente y habilita IPv6 en la interfaz sin asignar una dirección global.
