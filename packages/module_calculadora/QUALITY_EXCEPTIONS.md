# QUALITY_EXCEPTIONS — module_calculadora

Registro obligatorio (Ley de Calidad §4.4 y §4.5) de pragmas de exclusión y
mutantes declarados equivalentes o no detectables por la puerta de tests.

## Mutantes

### M-001 / M-002 — quitar `super.build(context)` en tabs con keep-alive

- **Archivos:** `lib/src/dividir_tab.dart` (`build`, líneas 76-77) y
  `lib/src/vlsm_tab.dart` (`build`, líneas 44-45).
- **Mutante:** `mutation_test` 1.8.1 (reglas builtin) borra la línea
  `super.build(context);` del `build` de los `State` que mezclan
  `AutomaticKeepAliveClientMixin`.
- **Fecha:** 2026-09-27. **Registrado por:** Claude Code.
- **Por qué la puerta de tests no lo detecta:** en Flutter
  (`packages/flutter/lib/src/widgets/automatic_keep_alive.dart`, líneas
  459-484), `initState()` ya llama `_ensureKeepAlive()` cuando
  `wantKeepAlive` es `true`. `build()` del mixin solo vuelve a pedir el
  keep-alive si `deactivate()` lo liberó, lo que ocurre únicamente al
  reubicar el elemento con una `GlobalKey`. En estos tabs `wantKeepAlive` es
  la constante `true` y no hay reubicación con `GlobalKey`, así que quitar la
  llamada no cambia ningún comportamiento observable en esta app. El test de
  keep-alive (saltar a "Práctica" y volver) pasa igual con y sin el mutante.
- **Quién sí lo detecta:** la puerta de análisis estático. `flutter analyze`
  reporta `must_call_super` (el método del mixin está anotado con
  `@mustCallSuper`), y el gate exige 0 advertencias, así que el mutante no
  puede llegar a entregarse. Verificado el 2026-09-27 con un archivo de
  prueba que omite la llamada: `warning - This method overrides a method
  annotated as '@mustCallSuper' in 'AutomaticKeepAliveClientMixin', but
  doesn't invoke the overridden method - must_call_super`.
- **Decisión:** se acepta como no detectable por tests y cubierto por el
  analizador. No se agregan tests que reubiquen el widget con `GlobalKey`,
  porque probarían el framework y no el código de la app.
