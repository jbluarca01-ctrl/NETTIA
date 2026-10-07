---
id: ipv4-vlsm-mayor-a-menor
tema: ipv4
subtema: vlsm
titulo: VLSM - subredes a medida, de mayor a menor y sin solapes
nivel: intermedio
plataforma: generico
version: IPv4
protocolo: ipv4
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-10-06
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: vlsm, mascara variable, mayor a menor, solape, alineado, multiplo del bloque, 2^n-2, tabla vlsm, desperdicio, mascara fija
fuente: RFC 4632 - Classless Inter-domain Routing (CIDR) | 3. Classless Addressing | https://www.rfc-editor.org/rfc/rfc4632
fuente: RFC 950 - Internet Standard Subnetting Procedure | Subnet Mask | https://www.rfc-editor.org/rfc/rfc950
---
Con **máscara fija** todas las subredes miden lo mismo y se desperdician direcciones; con **VLSM** cada red recibe el bloque más pequeño que le alcanza.

Pasos (ejemplo 192.168.10.0/24 para 50, 25, 12 y 5 hosts):

1. **Ordenar de mayor a menor**: 50 → 25 → 12 → 5.
2. Elegir el **/ mínimo** con 2^h − 2 ≥ hosts: 50 → /26 (62), 25 → /27 (30), 12 → /28 (14), 5 → /29 (6).
3. **Bloques**: 64, 32, 16, 8.
4. Asignar **contiguo y alineado** (cada red empieza en un múltiplo de su bloque): .0/26, .64/27, .96/28, .112/29. Queda libre .120 – .255.

Controles antes de configurar:
- Ningún rango toca al siguiente (broadcast .63 → red .64, .95 → .96, .111 → .112).
- La suma de bloques no pasa del espacio disponible (64+32+16+8 = 120 ≤ 256).
- Si se empieza por la red pequeña, la grande queda desalineada o no cabe.
