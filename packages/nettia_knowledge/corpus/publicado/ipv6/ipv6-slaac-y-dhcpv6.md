---
id: ipv6-slaac-y-dhcpv6
tema: ipv6
subtema: slaac
titulo: SLAAC, DHCPv6 y los indicadores M y O
nivel: intermedio
plataforma: generico
version: -
protocolo: ipv6,slaac,dhcpv6
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ipv6, slaac, autoconfiguración, dhcpv6, router advertisement, ra, indicador m, indicador o, dad, prefijo
fuente: RFC 4862 - IPv6 Stateless Address Autoconfiguration | §5.3 a §5.5 | https://www.rfc-editor.org/rfc/rfc4862
fuente: RFC 4861 - Neighbor Discovery for IP version 6 | §4.2 | https://www.rfc-editor.org/rfc/rfc4861
---
**SLAAC** (autoconfiguración de dirección sin estado, RFC 4862):
1. El equipo forma su **link-local** (`fe80::/10` + ID de interfaz).
2. Comprueba que no esté repetida con **DAD** (detección de direcciones duplicadas), enviando un mensaje *Neighbor Solicitation*.
3. Recibe un **Router Advertisement (RA)** con el prefijo. Si el indicador **A** (autónomo) está activo, el equipo une ese prefijo con su ID de interfaz y forma la dirección global.

**Indicadores del RA (RFC 4861):**
- **M = 1**: la configuración de direcciones se administra por **DHCPv6**.
- **O = 1**: hay **otra información** (por ejemplo DNS) disponible por DHCPv6.

Combinaciones habituales: solo SLAAC (M=0, O=0); SLAAC con DHCPv6 para lo demás (O=1); DHCPv6 con dirección asignada por el servidor (M=1).
