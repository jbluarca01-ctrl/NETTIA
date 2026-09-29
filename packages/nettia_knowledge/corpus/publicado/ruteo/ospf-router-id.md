---
id: ospf-router-id
tema: ruteo
subtema: ospf-router-id
titulo: Cómo elige OSPF el Router ID
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
palabras_clave: ospf, router id, router-id, loopback, ip más alta, clear ip ospf process, identificador
fuente: Cisco - IOS XE 17.x, Configuring OSPF | Router ID | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-cfg-0.html
fuente: Cisco - IOS XE 17.x, Enabling OSPFv2 on an Interface Basis | router-id | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-mode-ospfv2.html
---
El Router ID se elige así (documentación de Cisco), en este orden:
1. El configurado con el comando **`router-id`** dentro de `router ospf` (tiene prioridad sobre todo).
2. Si no hay, la **IP más alta de las interfaces loopback**.
3. Si no hay loopback, la **IP más alta de cualquier interfaz activa**.

Las loopback se prefieren porque **nunca caen**, lo que da más estabilidad.
```
Router(config)# router ospf 1
Router(config-router)# router-id 1.1.1.1
```
Si cambias el Router ID con el proceso ya activo, hay que reiniciar el proceso para que tome efecto:
```
Router# clear ip ospf process
```
