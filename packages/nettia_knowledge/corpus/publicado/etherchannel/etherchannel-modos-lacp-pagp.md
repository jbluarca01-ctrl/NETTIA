---
id: etherchannel-modos-lacp-pagp
tema: etherchannel
subtema: modos
titulo: "Modos de EtherChannel: on, LACP (active/passive) y PAgP (desirable/auto)"
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
palabras_clave: etherchannel, channel-group, lacp, pagp, active, passive, desirable, auto, on mode, port-channel
fuente: Cisco Catalyst 9600 - Layer 2 Configuration Guide, IOS XE Amsterdam 17.3.x | Configuring EtherChannels | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9600/software/release/17-3/configuration_guide/lyr2/b_173_lyr2_9600_cg/configuring_etherchannels.html
fuente: Cisco Catalyst 9000 - EtherChannel Configuration Guide, IOS XE 17 | EtherChannel | https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/lyr2-fwd/etherchannel/etherchannel-configuration-guide/m_ethernetchannel.html
---
`channel-group [número] mode [modo]` agrupa varios puertos físicos en una sola interfaz lógica `Port-channel`. El modo define **si negocia** el enlace y con qué protocolo:

| Protocolo | Modo | Comportamiento |
|---|---|---|
| — (manual) | `on` | Fuerza el puerto a unirse al canal **sin negociar nada**. |
| LACP (802.3ad) | `active` | Empieza a negociar enviando paquetes LACP. |
| LACP (802.3ad) | `passive` | Solo responde si el otro lado ya está negociando. |
| PAgP (Cisco) | `desirable` | Empieza a negociar enviando paquetes PAgP. |
| PAgP (Cisco) | `auto` | Solo responde si el otro lado ya está negociando. |

**Combinaciones que sí forman el canal:** `active`+`active`, `active`+`passive`, `desirable`+`desirable`, `desirable`+`auto`, `on`+`on`.
**Combinaciones que NO forman el canal:** `passive`+`passive` y `auto`+`auto` (ninguno de los dos lados inicia la negociación), y `on` con cualquier modo negociado (LACP o PAgP) del otro lado.

```
interface range GigabitEthernet0/1 - 2
 channel-group 1 mode active
!
interface Port-channel1
 switchport mode trunk
```

Límite de puertos por canal: hasta **8** con PAgP; con LACP hasta **16** físicos, de los cuales como máximo **8 activos** a la vez (el resto queda en espera/standby).

Verificación:
```
Switch# show etherchannel summary
Switch# show interfaces port-channel 1
```
