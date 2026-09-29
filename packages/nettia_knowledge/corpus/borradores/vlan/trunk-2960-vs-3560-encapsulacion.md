---
id: trunk-2960-vs-3560-encapsulacion
tema: vlan
subtema: trunk
titulo: Por qué switchport trunk encapsulation no existe en un 2960
nivel: intermedio
plataforma: ios
version: -
protocolo: 802.1q
audiencia: estudiante, profesional
idioma: es
estado: borrador
verificacion: sin-verificar
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: trunk, encapsulation, dot1q, isl, 2960, 3560, invalid input
fuente: Cisco - Catalyst 2960, Configuring VLAN Trunks (IOS 15.2(2)E) | Trunking | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/15-2_2_e/configuration/guide/b_1522e_2960_2960c_2960s_2960sf_2960p_cg/m_1522e_vlan_trunk_2960s_cg.html
---
BORRADOR: la idea es que el 2960 solo soporta 802.1Q y por eso no acepta `switchport trunk encapsulation`, mientras que un 3560 (que soporta ISL y 802.1Q) sí lo pide. **Falta una fuente primaria de Cisco que lo afirme**: la guía del 2960 consultada no lo dice explícitamente. No se publica hasta tenerla.
