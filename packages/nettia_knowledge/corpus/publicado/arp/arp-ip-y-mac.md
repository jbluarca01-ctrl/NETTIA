---
id: arp-ip-y-mac
tema: arp
subtema: ip-y-mac
titulo: IP lógica, MAC física y cómo ARP las une (arp -a)
nivel: basico
plataforma: generico
version: IPv4 / Ethernet
protocolo: arp
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-10-06
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: arp, arp -a, mac, ip vs mac, direccion fisica, direccion logica, cache arp, ipconfig, broadcast arp, gateway, tabla arp
fuente: RFC 826 - An Ethernet Address Resolution Protocol | Packet Generation y Packet Reception | https://www.rfc-editor.org/rfc/rfc826
fuente: Microsoft Learn - Windows Commands | arp | https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/arp
---
- La **IP** es **lógica**: la asigna el administrador o el DHCP, identifica la red y el equipo, y cambia si el equipo se mueve de red.
- La **MAC** es **física**: 48 bits en hexadecimal grabados en la tarjeta de red (p. ej. AA:BB:CC:DD:EE:FF); sirve para entregar tramas **dentro de la red local**.

**ARP** une las dos: para enviar a una IP de su misma red, el equipo pregunta por **broadcast** (FF:FF:FF:FF:FF:FF) "¿quién tiene esta IP?"; solo el dueño responde (unicast) y la respuesta queda en la **caché**, así que el siguiente envío ya no pregunta.

Comandos en la PC:
```
ipconfig /all     (muestra la IP y la MAC propias)
arp -a            (tabla ARP: IP → MAC aprendidas)
```
- Si la tabla está vacía, haz `ping` a un vecino y vuelve a ver `arp -a`: aparece una entrada nueva.
- ARP **solo alcanza la red local**: para llegar a otra red la PC busca la MAC de su **gateway**, no la del destino.
