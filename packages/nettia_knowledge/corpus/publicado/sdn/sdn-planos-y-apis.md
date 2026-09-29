---
id: sdn-planos-y-apis
tema: sdn
subtema: conceptos
titulo: "SDN: planos de datos, control y gestión; APIs northbound y southbound"
nivel: intermedio
plataforma: generico
version: RFC 7426
protocolo: sdn
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-27
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: sdn, redes definidas por software, plano de datos, plano de control, plano de gestion, controlador, northbound api, southbound api, openflow, rest
fuente: IETF RFC 7426 - SDN: Layers and Architecture Terminology | §2 Terminology, §3 SDN Layers, §4.3 OpenFlow | https://www.rfc-editor.org/rfc/rfc7426
fuente: IBM - What Is Software-Defined Networking (SDN)? | SDN architecture | https://www.ibm.com/think/topics/sdn
---
Todo equipo de red hace tres tipos de trabajo, llamados **planos**:

| Plano | Qué hace | Ejemplo |
|---|---|---|
| **Datos** (*forwarding*) | Mueve cada paquete: lo reenvía, lo descarta o lo modifica según las reglas que ya tiene. | Buscar la MAC/IP de destino y sacar el paquete por un puerto. |
| **Control** | Decide **cómo** se debe reenviar y le entrega esas reglas al plano de datos. | Un protocolo de ruteo (ej. OSPF) calculando las mejores rutas. |
| **Gestión** | Configura, monitorea y mantiene los equipos, en escalas de minutos a días. | SNMP, NETCONF, cambios de configuración. |

En una red tradicional, **cada router o switch tiene su propio plano de control**. En **SDN** (redes definidas por software), el plano de control se **separa** de los equipos y se centraliza en un **controlador** con visión de toda la red; los equipos se quedan principalmente con el plano de datos y obedecen las reglas que les manda el controlador.

**APIs del controlador:**
- **Southbound (hacia abajo):** por donde el controlador programa a los switches y routers. **OpenFlow** es el ejemplo clásico; también se usan protocolos de gestión.
- **Northbound (hacia arriba):** por donde las aplicaciones y los scripts le piden cosas al controlador (típicamente **REST**), sin tener que hablar con cada equipo uno por uno.

Idea clave: con SDN se automatiza pidiéndole al controlador ("quiero que esta aplicación tenga esta política") en lugar de entrar por CLI a configurar equipo por equipo.
