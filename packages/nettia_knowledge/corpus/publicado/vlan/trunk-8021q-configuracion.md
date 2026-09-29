---
id: trunk-8021q-configuracion
tema: vlan
subtema: trunk
titulo: Configurar un trunk 802.1Q (modos, VLAN nativa, VLAN permitidas)
nivel: intermedio
plataforma: ios
version: IOS 15.2
protocolo: 802.1q
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: trunk, troncal, 802.1q, dot1q, switchport mode trunk, vlan nativa, native vlan, allowed vlan, dtp, dynamic auto, nonegotiate, show interfaces trunk
fuente: Cisco - Catalyst 2960, Configuring VLAN Trunks (IOS 15.2(2)E) | Trunking | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/15-2_2_e/configuration/guide/b_1522e_2960_2960c_2960s_2960sf_2960p_cg/m_1522e_vlan_trunk_2960s_cg.html
fuente: Cisco - Catalyst 2960-X, Configuring VLAN Trunks (IOS 15.2(2)E) | VLAN trunks | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960x/software/15-2_2_e/vlan/configuration_guide/b_vlan_1522e_2960x_cg/b_vlan_152ex_2960-x_cg_chapter_0100.html
---
```
Switch(config)# interface gigabitethernet0/1
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk native vlan 99
Switch(config-if)# switchport trunk allowed vlan remove 30
```
Comportamiento según la guía de Cisco:
- **Modo predeterminado:** `dynamic auto` (negocia por DTP). Otros modos: `access`, `dynamic desirable`, `trunk`.
- **VLAN nativa:** VLAN 1 por defecto. **Debe ser la misma en ambos extremos**; si no coincide, pueden aparecer **bucles de spanning-tree**.
- **VLAN permitidas:** por defecto **todas** (1 a 4094). Se ajustan con `switchport trunk allowed vlan {add | all | except | remove} lista`.
- Para un trunk hacia un equipo que no usa DTP: `switchport mode trunk` + `switchport nonegotiate` (el puerto queda en trunk sin enviar tramas DTP).

Verificación:
```
Switch# show interfaces gigabitethernet0/1 trunk
Switch# show interfaces gigabitethernet0/1 switchport
```
