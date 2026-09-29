---
id: ospf-hello-dead-y-vecinos
tema: ruteo
subtema: ospf-vecinos
titulo: Por qué OSPF no forma vecinos: hello, dead, área, máscara
nivel: intermedio
plataforma: generico
version: -
protocolo: ospf
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ospf, vecinos, no forma adyacencia, hello, dead interval, hello interval, intervalo, área, máscara, mismatch, neighbor, troubleshooting, diagnóstico
fuente: RFC 2328 - OSPF Version 2 | §10.5, Apéndice C | https://www.rfc-editor.org/rfc/rfc2328
fuente: Cisco - IOS XE, OSPF Support for Fast Hello Packets (intervalos por defecto) | hello/dead por defecto | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/iproute_ospf/configuration/xe-16/iro-xe-16-book/iro-fast-hello.html
---
Dos routers solo forman vecindad si los paquetes *Hello* **coinciden** en estos campos (RFC 2328 §10.5); si no, el Hello se descarta:
- **Máscara de red** (en redes broadcast/NBMA).
- **HelloInterval** y **RouterDeadInterval**.
- **ID de área**.
- **Autenticación**.

**Valores por defecto en Cisco:** hello **10 s** y dead **40 s** en Ethernet (broadcast) y punto a punto; hello **30 s** y dead **120 s** en enlaces no broadcast. El dead es 4 veces el hello si no se cambia.

Se ajustan por interfaz:
```
Router(config-if)# ip ospf hello-interval 10
Router(config-if)# ip ospf dead-interval 40
```
**Lista de revisión cuando no aparece el vecino:**
1. ¿Las dos interfaces están activas y en la misma subred con la misma máscara?
2. ¿Están en la **misma área**?
3. ¿Coinciden hello y dead?
4. ¿La interfaz está declarada como `passive-interface`? (una pasiva no envía hello)
5. ¿La sentencia `network` (o `ip ospf area`) realmente cubre la interfaz?

Comandos: `show ip ospf neighbor`, `show ip ospf interface`, `show ip protocols`.
