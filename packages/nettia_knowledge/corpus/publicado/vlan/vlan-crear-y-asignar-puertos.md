---
id: vlan-crear-y-asignar-puertos
tema: vlan
subtema: configuracion
titulo: Crear una VLAN y asignar puertos de acceso
nivel: basico
plataforma: ios
version: IOS 15.2
protocolo: vlan
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: vlan, crear vlan, nombre, switchport access vlan, switchport mode access, show vlan brief, puerto de acceso, rango de vlan, vlan 1
fuente: Cisco - Catalyst 2960, Configuring VLANs (IOS 15.2(2)E) | Configuring VLANs | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/15-2_2_e/configuration/guide/b_1522e_2960_2960c_2960s_2960sf_2960p_cg/m_1522e_vlan_vlan_2960s_cg.html
fuente: Cisco - Catalyst 2960-X, Configuring VLANs (IOS 15.2(3)E) | Normal-range VLANs | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960x/software/15-2_3_e/consolidated_guide/b_1523e_consolidated_2960x_cg/m_vlan_vlan_cg_2960-x.html
---
```
Switch(config)# vlan 10
Switch(config-vlan)# name VENTAS
Switch(config-vlan)# exit
Switch(config)# interface fastethernet0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
```
Datos de la guía de Cisco:
- **Rango normal:** VLAN 1 a 1005. **Rango extendido:** 1006 a 4094 (con VTP versión 1 o 2 el switch debe estar en modo *transparent* para crearlas).
- La VLAN 1 (y las 1002 a 1005) **no se pueden borrar**. La VLAN 1 es la predeterminada de todos los puertos.
- Si asignas un puerto a una VLAN que **no existe**, esa VLAN se **crea**.
- Si **borras** una VLAN, los puertos que tenía quedan **inactivos** hasta que los muevas a otra VLAN.

Verificación:
```
Switch# show vlan brief
Switch# show interfaces fastethernet0/1 switchport
```
