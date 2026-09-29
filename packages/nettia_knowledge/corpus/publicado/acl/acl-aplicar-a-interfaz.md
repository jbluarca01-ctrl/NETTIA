---
id: acl-aplicar-a-interfaz
tema: acl
subtema: aplicacion
titulo: Aplicar una ACL a una interfaz (in/out) y verificarla
nivel: basico
plataforma: ios
version: IOS 15.M&T / IOS XE
protocolo: acl
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ip access-group, acl in out, aplicar acl a interfaz, una acl por interfaz por protocolo por direccion, show access-lists
fuente: Cisco IOS XE 16.9.x - Security Configuration Guide: Access Control Lists | Creating an IP Access List and Applying It to an Interface | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/xe-16-9/sec-data-acl-xe-16-9-book/sec-create-ip-apply.html
fuente: Cisco IOS XE 3S - Security Configuration Guide: Access Control Lists | IP Access List Overview | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/xe-3s/sec-data-acl-xe-3s-book/sec-access-list-ov.html
---
Una ACL (numerada o con nombre) no filtra nada hasta que se aplica a una interfaz con una dirección:

```
interface GigabitEthernet0/1
 ip access-group 101 in
```

- **`in`**: filtra el tráfico que **entra** por esa interfaz, antes de que el router decida por dónde enrutarlo.
- **`out`**: filtra el tráfico que **sale** por esa interfaz, después de que ya se tomó la decisión de ruteo.

**Regla clave:** solo se puede aplicar **una ACL por interfaz, por protocolo (ej. IPv4) y por dirección** (`in` u `out`). Si necesitas filtrar en ambos sentidos de la misma interfaz, son dos ACL distintas: una para `in` y otra para `out`.

```
interface GigabitEthernet0/1
 ip access-group ENTRADA-LAN in
 ip access-group SALIDA-LAN out
```

Verificación:
```
Router# show access-lists
Router# show ip interface GigabitEthernet0/1
```
`show access-lists` muestra, entre otras cosas, cuántos paquetes coincidieron con cada línea (útil para confirmar que el `deny` implícito o explícito realmente se está disparando). `show ip interface` confirma qué ACL está aplicada y en qué sentido en esa interfaz puntual.
