# QUALITY_EXCEPTIONS — module_comandos

Registro obligatorio (Ley de Calidad §4.4 y §4.5) de pragmas de exclusión y
mutantes declarados equivalentes.

## Mutantes

### M-001 — `ordenarHallazgos`: peso de `Nivel.ok` 2 → 3

- **Archivo:** `lib/src/logic/modelo_show.dart`, línea 47 (función
  `ordenarHallazgos`, movida sin cambios desde `explicador_show.dart`).
- **Mutante:** motor de mutación de `c:\dev\gate` (`motor.entero`), 2 → 3.
- **Fecha:** 2026-10-06. **Registrado por:** Claude Code.
- **Por qué es equivalente:** los pesos solo se comparan entre sí
  (`compareTo`). Con `problema = 0`, `aviso = 1` y `ok = 2` u `ok = 3` el
  orden relativo de los tres niveles es el mismo (0 < 1 < 2 y 0 < 1 < 3), así
  que ninguna lista de hallazgos puede ordenarse distinto.

### M-002 — `ordenarHallazgos`: desempate `c != 0 ? c : …` → `c`

- **Archivo:** `lib/src/logic/modelo_show.dart`, línea 54.
- **Mutante:** motor (`motor.ternario.true`): el comparador devuelve siempre
  `c` y deja de desempatar por la posición original.
- **Fecha:** 2026-10-06. **Registrado por:** Claude Code.
- **Por qué no lo detectan los tests:** `List.sort` de Dart usa ordenamiento
  por inserción (estable) para listas de hasta 32 elementos
  (`sdk/lib/internal/sort.dart`, `_INSERTION_SORT_THRESHOLD = 32`); las salidas
  de un comando dan muchos menos hallazgos, así que con o sin el desempate el
  resultado es idéntico. El desempate explícito se conserva porque el
  contrato de `sort` no garantiza estabilidad en general (listas largas usan
  dual-pivot quicksort). El test `orden: … estable entre iguales` de
  `test/unit/explicador_mas_test.dart` fija el comportamiento observable.
