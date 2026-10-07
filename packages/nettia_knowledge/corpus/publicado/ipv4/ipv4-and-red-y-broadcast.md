---
id: ipv4-and-red-y-broadcast
tema: ipv4
subtema: and
titulo: Red, broadcast y rango útil con la operación AND
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
palabras_clave: and, operacion and, direccion de red, broadcast, rango util, octeto interesante, bloque, 256 menos, primer host, ultimo host, no se asigna, extremos
fuente: RFC 950 - Internet Standard Subnetting Procedure | Address Format y Subnet Mask | https://www.rfc-editor.org/rfc/rfc950
fuente: RFC 1122 - Requirements for Internet Hosts | 3.2.1.3 Addressing (direcciones de red y broadcast) | https://www.rfc-editor.org/rfc/rfc1122
---
**Red = IP AND máscara** (bit a bit: 1 solo si ambos son 1). **Broadcast** = la red con todos los bits de host en 1.

Método rápido con el **octeto interesante** (donde la máscara no es 255 ni 0). Ejemplo 192.168.45.100/19:

1. /19 = 255.255.**224**.0 → el octeto interesante es el 3.º.
2. Bloque = 256 − 224 = **32**.
3. AND del 3.º octeto: 45 = 00101101, 224 = 11100000 → 00100000 = **32**. Red: **192.168.32.0**.
4. Broadcast: red + 31 en ese octeto y 255 después → **192.168.63.255**.
5. Rango útil: **192.168.32.1 – 192.168.63.254**; gateway habitual: el primero.

- Error típico: copiar el octeto del host como red (el .45 **no** es la red en /19).
- La dirección de **red** identifica a la subred y el **broadcast** llega a todos; por eso **ninguna de las dos se asigna a un PC** (excepción: /31 punto a punto).
- Hosts útiles = 2^h − 2, con h = bits de host.
