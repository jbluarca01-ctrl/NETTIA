---
id: ipv6-ndp-reemplaza-arp
tema: ipv6
subtema: ndp
titulo: NDP: el reemplazo de ARP en IPv6
nivel: intermedio
plataforma: generico
version: -
protocolo: ipv6,icmpv6
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ipv6, ndp, neighbor discovery, descubrimiento de vecinos, arp, nd, icmpv6, solicited-node, router solicitation, 133, 134, 135, 136
fuente: RFC 4861 - Neighbor Discovery for IP version 6 | §4, §7 | https://www.rfc-editor.org/rfc/rfc4861
fuente: RFC 4291 - IP Version 6 Addressing Architecture | §2.7.1 | https://www.rfc-editor.org/rfc/rfc4291
---
IPv6 no usa ARP: usa **NDP** (Neighbor Discovery Protocol), que va sobre ICMPv6 (RFC 4861). Los cinco mensajes:

| Mensaje | ICMPv6 tipo | Para qué |
|---|---|---|
| Router Solicitation (RS) | 133 | Un host pide un RA de inmediato |
| Router Advertisement (RA) | 134 | El router anuncia prefijo y parámetros |
| Neighbor Solicitation (NS) | 135 | Pregunta la MAC de un vecino / DAD |
| Neighbor Advertisement (NA) | 136 | Respuesta con la MAC |
| Redirect | 137 | El router indica un mejor siguiente salto |

**Resolución de direcciones:** en vez de un broadcast, el NS se envía a la dirección **multicast de nodo solicitado** de la dirección buscada: `ff02::1:ffXX:XXXX`, donde `XX:XXXX` son los **24 bits finales** de esa dirección (RFC 4291 §2.7.1). Así solo se interrumpe a los equipos con ese sufijo. El destino responde con un NA unicast.

**Seguridad básica:** todos los mensajes NDP se envían con **Hop Limit 255**; si llegan con otro valor se descartan, así no pueden venir de fuera del enlace.
