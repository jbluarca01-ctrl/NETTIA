---
id: ipv4-31-punto-a-punto
tema: ipv4
subtema: punto-a-punto
titulo: Subredes /31 en enlaces punto a punto
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
palabras_clave: /31, 255.255.255.254, punto a punto, rfc 3021, enlace serial, dos direcciones, sin broadcast, asignable
fuente: RFC 3021 - Using 31-Bit Prefixes on IPv4 Point-to-Point Links | 2. Motivation y 3. Addressing | https://www.rfc-editor.org/rfc/rfc3021
fuente: RFC 6890 - Special-Purpose IP Address Registries | 2.2.2 IPv4 Special-Purpose Address Registry Entries | https://www.rfc-editor.org/rfc/rfc6890
---
Una subred **/31** (máscara 255.255.255.254) tiene solo **2 direcciones**. En un enlace **punto a punto** (dos routers, un cable) **las dos se usan**, una en cada extremo:

- 10.0.0.4/31 → extremos **10.0.0.4** y **10.0.0.5**. No hay broadcast útil: en un enlace con un solo vecino no hace falta.
- Con /30 el mismo enlace gasta 4 direcciones (red, 2 hosts y broadcast); /31 ahorra la mitad.
- Fuera de un enlace punto a punto **la regla normal se mantiene**: la red y el broadcast no se asignan. Tratar un /31 como una LAN es un error.
