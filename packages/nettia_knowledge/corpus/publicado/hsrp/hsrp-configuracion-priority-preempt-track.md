---
id: hsrp-configuracion-priority-preempt-track
tema: hsrp
subtema: configuracion
titulo: "Configurar HSRP: priority, preempt y track"
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
palabras_clave: standby ip, standby priority, standby preempt, standby track, hsrp preempt, decremento de prioridad
fuente: Cisco Catalyst 9300 - IP Addressing Services Configuration Guide, IOS XE 17.9.x | Configuring HSRP | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9300/software/release/17-9/configuration_guide/ip/b_179_ip_9300_cg/configuring___hsrp.html
fuente: Cisco - Use HSRP Preempt and Track Commands | standby preempt y standby track | https://www.cisco.com/c/en/us/support/docs/ip/hot-standby-router-protocol-hsrp/13780-6.html
---
Configuración mínima de un grupo HSRP en una interfaz:
```
interface GigabitEthernet0/1
 ip address 192.168.1.2 255.255.255.0
 standby 1 ip 192.168.1.1
 standby 1 priority 110
 standby 1 preempt
 standby 1 track GigabitEthernet0/2 20
```

- **`standby [grupo] priority [1-255]`**: entre más alto, más prioridad. Por defecto es **100**. El de mayor prioridad debería ser el activo.
- **`standby [grupo] preempt`**: **sin este comando, un router NUNCA vuelve a ser activo automáticamente** aunque tenga la prioridad más alta — solo se vuelve activo si el que era activo se cae mientras este ya estaba arriba. Con `preempt`, en cuanto detecta que su prioridad es mayor que la del activo actual, toma el rol.
- **`standby [grupo] track [interfaz] [decremento]`**: si esa interfaz rastreada cae, la prioridad de este router baja en `decremento` (por defecto **10** si no se especifica). Así, si el enlace de salida del router "principal" se cae, su prioridad baja lo suficiente para que el otro router (con `preempt`) tome el control.

Verificación:
```
Router# show standby brief
```
