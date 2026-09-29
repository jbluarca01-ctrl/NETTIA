---
id: dns-resolucion-en-el-router
tema: dns
subtema: resolucion-router
titulo: Resolución de nombres en el propio router (ip name-server, domain-lookup)
nivel: basico
plataforma: ios
version: IOS XE 17.x
protocolo: dns
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ip name-server, ip domain lookup, ip domain name, dns router, show hosts, resolucion de nombres cisco
fuente: Cisco IOS XE 17.x - IP Addressing Configuration Guide | Configuring DNS | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-addressing/b-ip-addressing/m_configuring_dns.html
fuente: Cisco IOS Release 15M&T - IP Addressing DNS Configuration Guide | Configuring DNS | https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipaddr_dns/configuration/15-mt/dns-15-mt-book/dns-config-dns.html
---
Esto es la resolución DNS que usa **el propio router** para sus comandos (por ejemplo, si escribes `ping servidor.miempresa.com`), no la que reparte el pool DHCP a los clientes (eso va en el fragmento de DHCP).

```
ip domain name miempresa.com
ip name-server 8.8.8.8 8.8.4.4
```

- La búsqueda de nombres (**domain lookup**) viene **activada por defecto** en IOS. Sin un `ip name-server` configurado, el router igual intenta resolver — mandando la consulta como broadcast a `255.255.255.255`, que normalmente no llega a ningún lado.
- **`ip name-server`** acepta hasta **6 servidores DNS**.
- **`ip domain name`** define el sufijo que el router agrega a un nombre sin punto (ej. escribir `switch1` intenta resolver `switch1.miempresa.com`).
- Un problema clásico de laboratorio: si escribes mal un comando (ej. `shwo run`), IOS no lo reconoce como comando y, al tener domain-lookup activo sin servidor DNS que responda rápido, **se queda "colgado" varios segundos** intentando resolverlo como si fuera un hostname. Por eso en muchos labs se desactiva con `no ip domain lookup`.

Verificación:
```
Router# show hosts
```
