---
id: ospf-costo-y-ancho-de-banda
tema: ruteo
subtema: ospf-costo
titulo: Costo OSPF y ancho de banda de referencia
nivel: intermedio
plataforma: ios
version: IOS / IOS XE
protocolo: ospf
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ospf, costo, cost, métrica, ancho de banda de referencia, reference bandwidth, auto-cost, fastethernet, gigabit, 100 mbps
fuente: Cisco - IOS XE 17.x, Configuring OSPF | auto-cost reference-bandwidth | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-cfg-0.html
fuente: RFC 2328 - OSPF Version 2 | §16.1 (métrica) | https://www.rfc-editor.org/rfc/rfc2328
---
En Cisco, el costo de una interfaz = **ancho de banda de referencia ÷ ancho de banda de la interfaz**, con referencia **por defecto de 10^8 bps (100 Mbps)**.

Consecuencia: una interfaz de 100 Mbps cuesta **1**, y una de 1 Gbps también sale con costo **1** (el resultado no baja de 1), así que **OSPF no distingue** entre ambas. Para distinguirlas se sube la referencia, con el **mismo valor en todos los routers**:
```
Router(config-router)# auto-cost reference-bandwidth 1000
```
(El valor va en Mbps.) El costo de una ruta es la **suma** de los costos de las interfaces de salida a lo largo del camino.
