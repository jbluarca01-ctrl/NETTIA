---
id: ipv4-clases-y-mascara-por-defecto
tema: ipv4
subtema: clases
titulo: Clases de direcciones IPv4 (A a E) y máscara por defecto
nivel: basico
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
palabras_clave: clase a, clase b, clase c, clase d, clase e, primer octeto, mascara por defecto, classful, multicast, experimental, que clase es, ip clase
fuente: RFC 791 - Internet Protocol | 3.2 Addressing (formatos de clase A, B y C) | https://www.rfc-editor.org/rfc/rfc791
fuente: RFC 4632 - Classless Inter-domain Routing (CIDR) | 1. Introduction (por qué se dejaron las clases) | https://www.rfc-editor.org/rfc/rfc4632
---
La **clase** de una IPv4 la fija el **primer octeto**, no la máscara que tenga configurada:

| Clase | Primer octeto | Bits iniciales | Máscara por defecto | Uso |
|---|---|---|---|---|
| A | 1 – 126 | 0… | 255.0.0.0 (/8) | redes muy grandes |
| B | 128 – 191 | 10… | 255.255.0.0 (/16) | redes medianas |
| C | 192 – 223 | 110… | 255.255.255.0 (/24) | redes pequeñas |
| D | 224 – 239 | 1110… | no tiene | multicast (un origen, un grupo de destinos) |
| E | 240 – 255 | 1111… | no tiene | experimental / reservada |

- El **127** empieza con bit 0 (como la clase A), pero está reservado para **loopback**; el **0** también está reservado. Por eso los hosts de clase A van de 1 a 126.
- Ejemplo: 10.1.1.1/24 sigue siendo **clase A** aunque use máscara /24.
- Hoy el direccionamiento es **sin clases (CIDR)**: la máscara se elige según la necesidad. Las clases se siguen usando para leer rápido una dirección y su máscara "natural".
