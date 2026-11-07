# Excepciones de calidad — Nettia (app raíz)

Mutantes equivalentes registrados en `mutantes_equivalentes.yaml` (Ley §4.5).

### 1. lib/src/shell/nettia_shell.dart — `if (_perfil.puedeUsar(m))` siempre verdadero

Hoy ningún módulo es `soloProfesional`, así que todo perfil puede usar todos los módulos y el menú solo ofrece módulos visibles: la guarda siempre se cumple. Se mantiene como defensa para cuando exista un módulo solo profesional; en ese momento esta entrada deja de aplicar y hay que probarla.

### 2. lib/src/shell/nettia_shell.dart — `bodyLarge?.color` cambiado a `bodyLarge.color`

`ThemeData` siempre trae `textTheme.bodyLarge` (Material lo completa), así que el `?.` nunca encuentra `null` y quitarlo no cambia nada.
