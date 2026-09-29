---
id: ospf-conceptos-basicos
tema: ruteo
subtema: ospf-conceptos
titulo: OSPFv2: conceptos básicos (áreas, vecinos, DR/BDR)
nivel: intermedio
plataforma: generico
version: -
protocolo: ospf
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ospf, ospfv2, conceptos, área 0, backbone, dr, bdr, designated router, estados de vecino, full, 224.0.0.5, 224.0.0.6, protocolo 89, router id
fuente: RFC 2328 - OSPF Version 2 | §3.1, §9.4, §10.1 | https://www.rfc-editor.org/rfc/rfc2328
fuente: Cisco - IOS XE 17.x, Configuring OSPF | Configuring OSPF | https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/ip-routing/b-ip-routing/m_iro-cfg-0.html
---
- OSPF es un protocolo de **estado de enlace** para enrutar dentro de un sistema autónomo. Va directo sobre IP, **protocolo 89** (RFC 2328).
- Multicast: **224.0.0.5** (todos los routers OSPF) y **224.0.0.6** (DR y BDR).
- **Área 0 (0.0.0.0) = backbone.** Debe ser contigua; las demás áreas se conectan a ella.
- **Estados de un vecino:** Down, Attempt, Init, 2-Way, ExStart, Exchange, Loading y **Full** (adyacencia completa).
- **DR/BDR (redes de acceso múltiple):** se elige el router con **mayor prioridad**; si empatan, el de **mayor Router ID**. Prioridad **0** = no puede ser DR ni BDR. La elección **no es expropiativa**: un router mejor que aparece después no desplaza al DR actual.
- Para activar OSPF en Cisco se crea el proceso, se indican las direcciones/interfaces que participan y el **área** de cada una.
