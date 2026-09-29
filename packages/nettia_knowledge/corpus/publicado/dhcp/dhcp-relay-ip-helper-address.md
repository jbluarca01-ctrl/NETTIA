---
id: dhcp-relay-ip-helper-address
tema: dhcp
subtema: relay
titulo: "DHCP relay: por qué se necesita ip helper-address y dónde se configura"
nivel: intermedio
plataforma: ios
version: IOS 15S
protocolo: dhcp
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ip helper-address, dhcp relay, giaddr, broadcast dhcp, dhcp entre subredes
fuente: Cisco IOS Release 15S - IP Addressing DHCP Configuration Guide | Configuring the Cisco IOS DHCP Relay Agent | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipaddr_dhcp/configuration/15-s/dhcp-15-s-book/dhcp-relay-agent.html
fuente: Cisco IOS Release 15SY - IP Addressing DHCP Configuration Guide | Configuring the Cisco IOS DHCP Relay Agent | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipaddr_dhcp/configuration/15-sy/dhcp-15-sy-book/dhcp-relay-agent.html
---
Un cliente DHCP manda su solicitud como **broadcast** en su propia LAN — y un broadcast **no cruza routers**. Si el servidor DHCP está en otra subred, el router que conecta al cliente necesita actuar como **agente de relay** para reenviar esa solicitud como unicast hacia el servidor.

```
interface GigabitEthernet0/1
 ip address 192.168.1.1 255.255.255.0
 ip helper-address 10.0.0.100
```

- `ip helper-address` se configura **en la interfaz que recibe el broadcast del cliente** (la que da hacia la LAN de los clientes), no en la que va hacia el servidor.
- El agente de relay solo se activa en esa interfaz cuando este comando está presente; sin él, el router simplemente descarta el broadcast DHCP/BOOTP.
- Al reenviar la solicitud, el router escribe su propia IP (la de esa interfaz) en el campo **`giaddr`** del paquete DHCP — así el servidor sabe de qué subred vino la petición y qué pool usar para responder.

Verificación:
```
Router# show ip interface GigabitEthernet0/1
```
(la salida debe mostrar la dirección configurada en "Helper address").
