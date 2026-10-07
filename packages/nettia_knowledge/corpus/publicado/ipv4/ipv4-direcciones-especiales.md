---
id: ipv4-direcciones-especiales
tema: ipv4
subtema: especiales
titulo: Direcciones IPv4 especiales (loopback, APIPA, 0.0.0.0 y 255.255.255.255)
nivel: basico
plataforma: generico
version: IPv4
protocolo: ipv4
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-10-06
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: loopback, 127.0.0.1, apipa, 169.254, link-local, 0.0.0.0, 255.255.255.255, broadcast limitado, dhcp fallo, direccion especial, autoasignada
fuente: RFC 6890 - Special-Purpose IP Address Registries | 2.2.2 IPv4 Special-Purpose Address Registry Entries | https://www.rfc-editor.org/rfc/rfc6890
fuente: RFC 3927 - Dynamic Configuration of IPv4 Link-Local Addresses | 1. Introduction | https://www.rfc-editor.org/rfc/rfc3927
fuente: RFC 1122 - Requirements for Internet Hosts | 3.2.1.3 Addressing | https://www.rfc-editor.org/rfc/rfc1122
---
Direcciones que **nunca se asignan a un host** como su IP normal:

| Dirección | Nombre | Para qué sirve |
|---|---|---|
| 127.0.0.0/8 (127.0.0.1) | Loopback | tráfico hacia el propio equipo; `ping 127.0.0.1` prueba la pila TCP/IP |
| 169.254.0.0/16 | Link-local (APIPA) | el equipo se la **autoasigna cuando falla el DHCP**; sin conectividad útil fuera del enlace |
| 0.0.0.0 | No especificada | origen de un cliente mientras pide IP por DHCP; también es la ruta por defecto (0.0.0.0/0) |
| 255.255.255.255 | Broadcast limitado | a todos los equipos del segmento local; los routers no lo reenvían |

- Si `ipconfig` muestra **169.254.x.x**, el problema no es la IP: la PC **no recibió respuesta del DHCP**. Revisa el servidor o pool, la VLAN del puerto y el trunk, o asigna una IP fija.
- Además, la primera dirección de cada subred (dirección de red) y la última (broadcast) tampoco se asignan a hosts.
