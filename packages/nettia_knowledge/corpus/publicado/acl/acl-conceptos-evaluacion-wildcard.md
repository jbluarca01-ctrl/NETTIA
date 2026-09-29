---
id: acl-conceptos-evaluacion-wildcard
tema: acl
subtema: conceptos
titulo: Cómo se evalúa una ACL y qué es una wildcard mask
nivel: basico
plataforma: generico
version: IOS 15.M&T / IOS XE
protocolo: acl
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: acl, access list, wildcard mask, mascara inversa, implicit deny, deny implicito, evaluacion secuencial, primera coincidencia
fuente: Cisco IOS Release 15M&T - Security Configuration Guide: Access Control Lists | IP Access List Overview | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/15-mt/sec-data-acl-15-mt-book/sec-access-list-ov.html
fuente: Cisco IOS XE 3S - Security Configuration Guide: Access Control Lists | IP Access List Overview | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/xe-3s/sec-data-acl-xe-3s-book/sec-access-list-ov.html
---
Una ACL se evalúa **línea por línea, de arriba hacia abajo**. En cuanto una línea coincide con el paquete, el router aplica esa acción (`permit` o `deny`) y **deja de revisar el resto de las líneas** — el orden importa: una línea más específica colocada después de una más general nunca se llega a evaluar para los paquetes que ya coincidieron arriba.

Si un paquete no coincide con ninguna línea escrita, cae en un **`deny` implícito** al final de toda ACL (no aparece en la configuración, pero siempre está ahí). Cisco recomienda escribir un `deny` explícito al final (por ejemplo `deny ip any any log`) para poder ver en los contadores cuánto tráfico se está descartando por esa razón.

**Wildcard mask** (a veces llamada "máscara inversa"): es la máscara que usan las ACL (y OSPF) para decidir qué bits de una dirección deben coincidir exactamente y cuáles no importan:
- Bit en **0** → ese bit de la dirección **debe coincidir**.
- Bit en **1** → ese bit **no importa** (se ignora).

```
! Estas dos líneas son equivalentes:
access-list 1 permit host 192.168.10.1
access-list 1 permit 192.168.10.1 0.0.0.0

! Para una red completa 192.168.10.0/24, la wildcard es la inversa de la máscara:
! 255.255.255.0  →  wildcard  0.0.0.255
access-list 101 permit ip 192.168.10.0 0.0.0.255 any
```

Si no escribes una wildcard mask junto a una dirección, IOS asume `0.0.0.0` (todos los bits deben coincidir, es decir, esa IP exacta) — por eso `host 192.168.10.1` es equivalente a `192.168.10.1 0.0.0.0`.

Verificación (una vez aplicada a una interfaz, ver el fragmento de aplicación):
```
Router# show access-lists
```
