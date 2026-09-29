---
id: ospf-ruta-por-defecto
tema: ruteo
subtema: ospf-default
titulo: Propagar una ruta por defecto en OSPF
nivel: intermedio
plataforma: ios
version: IOS / IOS XE
protocolo: ospf
audiencia: estudiante, profesional
idioma: es
estado: borrador
verificacion: sin-verificar
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ospf, ruta por defecto, default route, default-information originate, always, asbr
fuente: Cisco - IOS XE 17.x, Configuring OSPF | default-information originate | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-cfg-0.html
---
BORRADOR: `default-information originate [always] [metric valor] [metric-type tipo] [route-map nombre]` hace que el ASBR anuncie una ruta por defecto al dominio OSPF; sin `always` solo lo hace si él mismo tiene una ruta por defecto en su tabla. **Solo hay una fuente verificada** (la guía OSPF de Cisco IOS XE 17.x); falta contrastarla con una segunda antes de publicar.
