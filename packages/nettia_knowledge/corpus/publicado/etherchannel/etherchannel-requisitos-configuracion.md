---
id: etherchannel-requisitos-configuracion
tema: etherchannel
subtema: configuracion
titulo: Requisitos de puertos para armar un EtherChannel
nivel: intermedio
plataforma: ios
version: IOS XE 17.x
protocolo: etherchannel
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: etherchannel requisitos, speed duplex etherchannel, vlan etherchannel, trunk etherchannel, mismatch
fuente: Cisco Catalyst 9600 - Layer 2 Configuration Guide, IOS XE Amsterdam 17.3.x | Configuring EtherChannels | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9600/software/release/17-3/configuration_guide/lyr2/b_173_lyr2_9600_cg/configuring_etherchannels.html
fuente: Cisco Catalyst 9600 - Layer 2 Configuration Guide, IOS XE 16.12.x | Configuring EtherChannels | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9600/software/release/16-12/configuration_guide/lyr2/configuring_etherchannels.html
---
Antes de meter puertos a un `channel-group`, todos deben quedar **configurados igual**; si alguno no coincide, ese puerto queda fuera del canal (o el canal ni se forma). Lo que Cisco exige que coincida entre todos los puertos del mismo EtherChannel:

- **Velocidad y dúplex** iguales en todos los puertos.
- **VLAN**: todos en la misma VLAN de acceso, **o** todos configurados como `trunk` (no se puede mezclar un puerto de acceso con uno trunk en el mismo canal).

Por eso, en la práctica, conviene configurar la interfaz física **antes** de meterla al `channel-group`, o configurar el `Port-channel` primero y dejar que las físicas hereden la config al unirse — pero siempre verificando que ninguna quedó "suspendida" por no coincidir.

```
interface range GigabitEthernet0/1 - 2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 1 mode active
```

Verificación (un puerto en estado distinto a "P" -bundled- no está realmente en el canal):
```
Switch# show etherchannel summary
Switch# show etherchannel 1 port
```
