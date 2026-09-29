---
id: dhcp-servidor-pool-exclusion
tema: dhcp
subtema: servidor
titulo: Configurar un router IOS como servidor DHCP (pool y exclusiones)
nivel: basico
plataforma: ios
version: IOS 15.M&T
protocolo: dhcp
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ip dhcp pool, ip dhcp excluded-address, default-router, dns-server, lease, dhcp server ios
fuente: Cisco IOS Release 15M&T - IP Addressing DHCP Configuration Guide | Configuring the Cisco IOS DHCP Server | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipaddr_dhcp/configuration/15-mt/dhcp-15-mt-book/config-dhcp-server.html
fuente: Cisco IOS XE 17.x - IP Addressing Configuration Guide | Configuring the Cisco IOS XE DHCP Server | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-addressing/b-ip-addressing/m_config-dhcp-server-xe.html
---
```
ip dhcp excluded-address 192.168.1.1 192.168.1.10
!
ip dhcp pool LAN-VENTAS
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8 8.8.4.4
 lease 2
```

- **`ip dhcp excluded-address`** se configura en modo global, **antes** de definir el pool, y evita que el servidor reparta direcciones que ya usan otros equipos (routers, switches de gestión, servidores). La IP configurada directamente en la interfaz del router **se excluye sola**, pero cualquier otra IP fija sí hay que excluirla a mano.
- **`network`** define el rango completo del que salen las direcciones a repartir.
- **`default-router`** y **`dns-server`** aceptan hasta **8 direcciones** cada uno.
- **`lease [días] [horas] [minutos]`**: si no se configura, el valor por defecto es **un día**.

Verificación:
```
Router# show ip dhcp pool LAN-VENTAS
Router# show ip dhcp binding
```
