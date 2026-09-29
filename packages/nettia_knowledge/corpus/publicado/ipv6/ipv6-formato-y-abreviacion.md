---
id: ipv6-formato-y-abreviacion
tema: ipv6
subtema: formato
titulo: Cómo se escribe y se abrevia una dirección IPv6
nivel: basico
plataforma: generico
version: -
protocolo: ipv6
audiencia: estudiante, profesional
idioma: es
estado: publicado
verificacion: fuentes-cruzadas
comandos_probados: no
fecha_revision: 2026-09-20
revisado_por: Claude (fuentes cruzadas); sin prueba en equipo
palabras_clave: ipv6, abreviar, comprimir, expandir, doble dos puntos, ceros, notación, formato, hexadecimal, ::
fuente: RFC 4291 - IP Version 6 Addressing Architecture | §2.2 | https://www.rfc-editor.org/rfc/rfc4291
fuente: RFC 5952 - A Recommendation for IPv6 Address Text Representation | §4 | https://www.rfc-editor.org/rfc/rfc5952
---
Una dirección IPv6 mide **128 bits** y se escribe como **8 grupos de 16 bits** en hexadecimal, separados por `:` (por ejemplo `2001:0db8:0000:0000:0000:ff00:0042:8329`).

**Reglas de la RFC 4291 (§2.2):**
- Los ceros a la izquierda de cada grupo se pueden omitir, pero cada grupo debe conservar al menos un dígito.
- `::` reemplaza una o más secuencias consecutivas de grupos en cero y **solo puede aparecer una vez** en la dirección.

**Forma recomendada (RFC 5952, §4):**
1. Se quitan siempre los ceros a la izquierda: `2001:0db8::0001` se escribe `2001:db8::1`.
2. `::` se usa al máximo: se abrevia la racha **más larga** de grupos en cero. `2001:db8:0:0:0:0:2:1` queda `2001:db8::2:1`.
3. `::` **no** se usa para un único grupo en cero: `2001:db8:0:1:1:1:1:1` es lo correcto, y `2001:db8::1:1:1:1:1` no.
4. Si hay dos rachas del mismo largo, se abrevia la **primera**: `2001:db8:0:0:1:0:0:1` queda `2001:db8::1:0:0:1`.
5. Las letras `a` a `f` van en **minúscula**.
