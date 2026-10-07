---
id: ipv4-privadas-rfc1918
tema: ipv4
subtema: privadas
titulo: Direcciones IPv4 privadas (RFC 1918) y públicas
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
palabras_clave: ip privada, ip publica, rfc 1918, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, nat, es privada, es publica, 172.15, 172.32
fuente: RFC 1918 - Address Allocation for Private Internets | 3. Private Address Space | https://www.rfc-editor.org/rfc/rfc1918
fuente: RFC 6890 - Special-Purpose IP Address Registries | 2.2.2 IPv4 Special-Purpose Address Registry Entries | https://www.rfc-editor.org/rfc/rfc6890
---
Los tres bloques **privados** de RFC 1918:

| Bloque | Rango | Equivale a |
|---|---|---|
| 10.0.0.0/8 | 10.0.0.0 – 10.255.255.255 | una red de clase A |
| 172.16.0.0/12 | 172.16.0.0 – 172.31.255.255 | 16 redes de clase B |
| 192.168.0.0/16 | 192.168.0.0 – 192.168.255.255 | 256 redes de clase C |

- Una dirección **privada** solo es válida dentro de la red interna: se **reutiliza** en millones de redes y necesita **NAT** para salir a Internet. La asigna el administrador o el DHCP local.
- Una dirección **pública** es única y enrutable en Internet; la reparte IANA a los registros regionales y estos a los ISP.
- Trampa frecuente: **172.15.x.x y 172.32.x.x son públicas**; el bloque privado de clase B va solo de **172.16 a 172.31**.
- Privada no significa falsa: es válida en su red; para unir redes hace falta un router y para salir a Internet, NAT.
