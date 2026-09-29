---
id: acl-estandar-vs-extendida
tema: acl
subtema: tipos
titulo: ACL estándar vs. extendida, numeradas y con nombre
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
palabras_clave: acl estandar, acl extendida, access-list numerada, ip access-list standard, ip access-list extended, rango acl, acl con nombre
fuente: Cisco IOS Release 15M&T - Security Configuration Guide: Access Control Lists | IP Access List Overview | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/15-mt/sec-data-acl-15-mt-book/sec-access-list-ov.html
fuente: Cisco IOS XE 16.9.x - Security Configuration Guide: Access Control Lists | Creating an IP Access List and Applying It to an Interface | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_data_acl/configuration/xe-16-9/sec-data-acl-xe-16-9-book/sec-create-ip-apply.html
fuente: Cisco - Configure Commonly Used IP ACLs | Standard and extended ACL examples | https://www.cisco.com/c/en/us/support/docs/ip/access-lists/26448-ACLsamples.html
---
**ACL estándar:** solo filtra por **dirección IP de origen**. Rango numerado clásico **1–99**, ampliado a **1300–1999**.
```
access-list 1 permit 192.168.10.0 0.0.0.255
```

**ACL extendida:** filtra por **origen, destino, protocolo y puerto/tipo de mensaje** (más específica y más usada en la práctica). Rango numerado clásico **100–199**, ampliado a **2000–2699**.
```
access-list 101 permit ip 192.168.10.0 0.0.0.255 192.168.200.0 0.0.0.255
access-list 102 deny tcp any any eq 23
access-list 102 permit ip any any
```

**ACL con nombre:** en vez de un número, se identifica con un nombre descriptivo. Se editan dentro de un submodo, lo que permite **borrar una sola línea** (con `no permit ...` / `no deny ...`) sin recrear toda la lista — algo que las numeradas clásicas no permiten sin usar números de secuencia.
```
ip access-list standard SOLO-VENTAS
 permit 192.168.10.0 0.0.0.255
!
ip access-list extended BLOQUEA-TELNET
 deny tcp any any eq 23
 permit ip any any
```

Las ACL con nombre están disponibles desde IOS 11.2 en adelante y también admiten filtrar por flags de TCP y opciones de IP, algo que las numeradas más antiguas no cubren igual de bien.

Verificación:
```
Router# show access-lists
Router# show ip access-lists SOLO-VENTAS
```
