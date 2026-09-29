---
id: hsrp-conceptos-mac-y-estados
tema: hsrp
subtema: conceptos
titulo: "HSRP: MAC virtual, temporizadores y máquina de estados"
nivel: intermedio
plataforma: ios
version: IOS XE 17.9.x
protocolo: hsrp
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: hsrp, mac virtual, 0000.0c07.ac, hello timer, hold timer, estados hsrp, active standby, gateway redundante
fuente: Cisco - Understand the Hot Standby Router Protocol Features and Functionality | Virtual MAC address y máquina de estados | https://www.cisco.com/c/en/us/support/docs/ip/hot-standby-router-protocol-hsrp/9234-hsrpguidetoc.html
fuente: Cisco Catalyst 9300 - IP Addressing Services Configuration Guide, IOS XE 17.9.x | Configuring HSRP | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9300/software/release/17-9/configuration_guide/ip/b_179_ip_9300_cg/configuring___hsrp.html
---
HSRP le da a varios hosts de una LAN un **gateway redundante**: dos (o más) routers comparten una IP y una MAC virtuales, aunque solo uno (el **activo**) responde tráfico en un momento dado.

**MAC virtual:** `0000.0c07.acXX`, donde `XX` es el número de grupo HSRP en hexadecimal (en la mayoría de medios; Token Ring es la excepción). Por eso dos grupos HSRP distintos en la misma LAN nunca comparten MAC virtual.

**Temporizadores por defecto:** hello cada **3 segundos**, hold (tiempo para declarar caído al activo si dejan de llegar hellos) de **10 segundos**.

**Estados por los que pasa un router HSRP** (de menor a mayor participación): `Initial` → `Learn` → `Listen` → `Speak` → `Standby` → `Active`. Solo un router del grupo llega a `Active`; el que le sigue en prioridad queda en `Standby` listo para tomar el rol si el activo falla.

Verificación:
```
Router# show standby brief
Router# show standby GigabitEthernet0/1 1
```
