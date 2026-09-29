---
id: ipv6-tipos-de-direccion
tema: ipv6
subtema: tipos
titulo: Tipos de dirección IPv6 y sus prefijos
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
palabras_clave: ipv6, tipos de dirección, unicast, multicast, link-local, ula, gua, global unicast, loopback, documentación, broadcast, prefijo
fuente: RFC 4291 - IP Version 6 Addressing Architecture | §2.4, §2.7 | https://www.rfc-editor.org/rfc/rfc4291
fuente: RFC 4193 - Unique Local IPv6 Unicast Addresses | §3.1, §4.1 | https://www.rfc-editor.org/rfc/rfc4193
fuente: RFC 3849 - IPv6 Address Prefix Reserved for Documentation | §2, §3 | https://www.rfc-editor.org/rfc/rfc3849
---
| Tipo | Prefijo | Qué es |
|---|---|---|
| No especificada | `::/128` | Sin dirección asignada |
| Loopback | `::1/128` | El propio equipo (como 127.0.0.1) |
| Link-local | `fe80::/10` | Válida solo en el enlace local |
| Local única (ULA) | `fc00::/7` (en la práctica `fd00::/8`) | Privada, **no enrutable en Internet** (RFC 4193) |
| Multicast | `ff00::/8` | Un mensaje a un grupo de equipos |
| Documentación | `2001:db8::/32` | Reservada para ejemplos; **no se enruta** (RFC 3849) |
| Unicast global | el resto; las que se ven en Internet empiezan por `2` o `3` (`2000::/3`) | Enrutable |

- En IPv6 **no existe broadcast**: su función la cumple multicast.
- El **ámbito** de un multicast está en el segundo dígito: `1` interfaz, `2` enlace local, `4` administrativo, `5` sitio, `8` organización, `e` global (RFC 4291 §2.7). Por ejemplo `ff02::1` = todos los nodos del enlace y `ff02::2` = todos los routers del enlace.
- Una ULA tiene la forma: prefijo `fc00::/7`, bit L en 1 (`fd00::/8`), **ID global de 40 bits**, **ID de subred de 16 bits** e ID de interfaz de 64 bits.
