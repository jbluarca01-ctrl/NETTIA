---
id: ospf-configuracion-basica
tema: ruteo
subtema: ospf-config
titulo: Configurar OSPFv2 de un solo área en Cisco IOS
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
palabras_clave: ospf, configurar ospf, router ospf, network, wildcard, area 0, passive-interface, ip ospf area, router-id, un solo área, single area
fuente: Cisco - IOS XE 17.x, Configuring OSPF | Enabling OSPF | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-cfg-0.html
fuente: Cisco - IOS XE 17.x, Enabling OSPFv2 on an Interface Basis | Enabling OSPFv2 on an Interface Basis | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-mode-ospfv2.html
---
Método con la sentencia `network` (dirección + **máscara wildcard** + área):
```
Router(config)# router ospf 1
Router(config-router)# router-id 1.1.1.1
Router(config-router)# network 192.168.1.0 0.0.0.255 area 0
Router(config-router)# network 10.0.0.0 0.0.0.3 area 0
Router(config-router)# passive-interface gigabitethernet0/1
```
- El **ID de proceso** (1 a 65535) solo tiene significado local.
- `passive-interface` evita enviar *hello* por esa interfaz (típico en la LAN de usuarios: la red se anuncia pero no se forman vecinos).
- Cisco evalúa las sentencias `network` **en orden**, comparando cada interfaz con el par dirección/wildcard.

Método recomendado por la documentación de Cisco para OSPFv2 (por interfaz):
```
Router(config)# interface gigabitethernet0/0
Router(config-if)# ip ospf 1 area 0
```
Verificación:
```
Router# show ip ospf neighbor
Router# show ip ospf interface brief
Router# show ip protocols
Router# show ip route ospf
```
