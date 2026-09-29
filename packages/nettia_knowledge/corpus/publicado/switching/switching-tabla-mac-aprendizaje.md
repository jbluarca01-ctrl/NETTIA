---
id: switching-tabla-mac-aprendizaje
tema: switching
subtema: tabla-mac
titulo: Cómo aprende y reenvía un switch (tabla MAC, flooding y aging)
nivel: basico
plataforma: ios
version: IOS 15.2 / IOS XE
protocolo: ethernet
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: tabla mac, cam, show mac address-table, aprendizaje mac, flooding, unicast desconocido, aging time, 300 segundos, mac estatica
fuente: Cisco Catalyst 2960 - Software Configuration Guide, IOS 15.2(1)E | Administering the Switch - Managing the MAC Address Table | https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/15-2_1_e/configuration/guide/2960_scg/swadmin.html
fuente: Cisco Catalyst 9000 - CDP, LLDP, MAC, and UDLD Configuration Guide | Configure MAC | https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/lyr2-fwd/cdp-lldp-mac-udld/cdp-lldp-mac-udld-configuration-guide/configure-mac.html
---
Un switch decide a qué puerto mandar cada trama con su **tabla de direcciones MAC** (también llamada tabla CAM). La llena así:

1. **Aprende del origen:** cada vez que recibe una trama, mira la **MAC de origen** y anota "esta MAC está detrás de este puerto, en esta VLAN". Nunca aprende de la MAC de destino.
2. **Reenvía según el destino:** si la **MAC de destino** ya está en la tabla, manda la trama solo por ese puerto.
3. **Destino desconocido → flooding:** si la MAC de destino no está en la tabla, manda la trama por **todos los puertos de la misma VLAN, menos por el que entró**. Cuando el destino responda, el switch aprenderá su MAC y la próxima vez ya no inundará.

**Aging:** las entradas dinámicas se borran si no llega ninguna trama desde esa MAC durante el tiempo de aging, que por defecto es **300 segundos** (5 minutos). Así la tabla no se queda con equipos que se desconectaron o se movieron de puerto.

```
! Cambiar el aging (10 a 1000000 segundos; 0 lo desactiva)
Switch(config)# mac address-table aging-time 600

! Entrada estática: no envejece y se conserva al reiniciar
Switch(config)# mac address-table static 0011.2233.4455 vlan 10 interface gigabitethernet0/5
```

Verificación:
```
Switch# show mac address-table
Switch# show mac address-table dynamic vlan 10
```
