# Excepciones de calidad — nettia_core

## Contratos abstractos sin cuerpo ejecutable (2026-09-28)

`lib/src/contracts/ai_diagnosis_service.dart` (`AiDiagnosisService.diagnosticarFallaStream`,
`AiDiagnosisService.cancelarStream`) y `lib/src/contracts/fuentes_locales.dart`
(`ConFuentesLocales.fuentesUltimaRespuesta`, `ConFuentesLocales.sanitizarParaReporte`)
son `abstract interface class` con solo firmas: ningún método tiene cuerpo,
por lo que no existe ninguna línea ejecutable que un test pueda cubrir. El
lector de LCOV reporta "sin datos de cobertura" para el archivo completo
porque nada lo instrumenta (no hay statement que instrumentar), no porque
falte un test.

Las implementaciones reales de estos contratos (en `nettia_ai` y otros
paquetes que dependen de `nettia_core`) sí tienen su propia cobertura, en su
propio `gate.yaml`. Cubrir la interfaz misma no es posible ni tiene sentido:
no hay comportamiento que ejercitar aquí, solo una forma.

**Decisión:** aceptar la ausencia de cobertura/CRAP en estos dos archivos
como excepción estructural, no como deuda pendiente. Si en el futuro se les
agrega código con cuerpo (p. ej. un método `provided` con lógica por
defecto), este archivo deja de aplicar para esa parte y debe revisarse.

## Constructor privado de una clase de solo-estáticos (2026-09-28)

`lib/src/theme/network_theme.dart:42` — `NetworkTheme._();`

**Motivo:** `NetworkTheme` es una clase de solo miembros `static` (colores,
`TextStyle`s, `ThemeData`); el constructor privado existe únicamente para
**impedir** que alguien la instancie (`NetworkTheme()` no compila fuera del
archivo). Por diseño, nunca se llama desde ningún lado — llamarlo a
propósito desde un test sería instanciar la clase que el propio constructor
existe para prohibir, lo contrario de lo que se quiere verificar.

**Decisión:** aceptar la ausencia de cobertura en esa línea como excepción
estructural del patrón "clase de solo-estáticos" de Dart. Si `NetworkTheme`
alguna vez deja de ser solo-estática, este constructor debería eliminarse
(ya no haría falta) y esta excepción deja de aplicar.

## Constructores `const` sin cobertura de línea aparente (2026-09-28)

Encontrado al revisar por qué `lib/src/widgets/editor_code_block.dart:12`
(`EditorCodeBlock({...})`) y `lib/src/widgets/nettia_logo.dart:72`
(`AnimatedNettiaLogo({...})`) aparecían "sin cobertura" en el gate a pesar
de que ambos widgets se construyen en varios tests.

**Motivo (verificado empíricamente):** en los tests existentes, **todas**
las instancias se creaban dentro de un `const Scaffold(...)`, y Dart
propaga el contexto `const` a los hijos aunque no se repita la palabra
`const` en cada nivel. Un constructor `const` se evalúa en tiempo de
**compilación** (constant-folding del compilador), no en tiempo de
ejecución: el instrumentador de cobertura de línea, que solo ve ejecución
en el VM, nunca registra un "hit" en esa línea sin importar cuántas
instancias `const` distintas existan.

**Corrección aplicada (no es una excepción, es un fix real):** en
`test/editor_code_block_test.dart` y `test/nettia_logo_test.dart` se quitó
el `const` de un `Scaffold` en cada archivo, forzando una construcción real
en tiempo de ejecución del widget. Verificado que esto sí genera el hit de
cobertura esperado. Esta entrada queda como referencia del porqué, no como
una excepción activa (el hallazgo se corrigió, no se aceptó).

## Mutantes equivalentes de mutación (2026-09-28)

Cada uno produce un programa con comportamiento observable idéntico; ningún
test puede distinguirlo. Lista de candidatos; los que sobrevivan en el gate
tras los tests se confirman aquí (línea = archivo original de `lib/src/`).

- `widgets/nettia_avatar.dart:11` — `math.min(a, b)` → `math.min(b, a)`:
  `min` es conmutativa.
- `widgets/nettia_avatar.dart:12` — `d >= ancho` → `d > ancho`: en el caso de
  igualdad ambas ramas devuelven el mismo valor.
- `widgets/nettia_avatar.dart:64` — eliminar `super.didUpdateWidget(old)`:
  `State.didUpdateWidget` es un método vacío (solo `@mustCallSuper` para
  subclases); no tiene efecto observable.
- `widgets/nettia_avatar.dart:70` — `if (mounted)` → `if (true)`: la
  animación no completa su `Future` tras `dispose`, por lo que la rama con
  `mounted == false` es inalcanzable.
- `widgets/nettia_avatar.dart:95`, `widgets/nettia_logo.dart:41,122`,
  `profile/profile_selection_screen.dart:82,91` — acceso null-aware
  (`textTheme.bodyLarge?.color`, `headlineSmall?.copyWith`) → acceso directo:
  con `NetworkTheme` los estilos nunca son nulos; la rama nula es inalcanzable.
- `widgets/nettia_avatar.dart:171` — `v * 1.0` → `v / 1.0` y `% -1.0`: la
  división entre 1.0 es identidad y el operador `%` de Dart devuelve siempre
  un resultado no negativo, igual con divisor negativo.
- `syntax/ios_syntax.dart:53` — rangos `A-Z` y `a-z` de `[A-Za-z]` alterados:
  el `RegExp` es `caseSensitive: false`, cada rango es redundante con el otro.
