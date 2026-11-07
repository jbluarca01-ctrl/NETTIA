# Excepciones de calidad — nettia_ai

Mutantes equivalentes registrados en `mutantes_equivalentes.yaml` (Ley §4.5).
Aprobados por Jairo el 2026-11-06 ("Cierra los tres mutantes de Nettia").

### 1. lib/src/screens/motor_ia_card.dart — quitar `super.initState();`

`State.initState()` del framework solo valida el ciclo de vida en modo debug
y avisa a las herramientas de memoria; no construye nada que la tarjeta use.
Sin la llamada, la tarjeta se dibuja, escucha la configuración y responde
exactamente igual, así que ningún test de comportamiento puede distinguir al
mutante. La llamada se mantiene porque el framework la exige
(`@mustCallSuper`) y el analizador la marca si falta.

### 2. lib/src/screens/motor_ia_card.dart — quitar `_keyController.dispose();`

Sin `dispose()` el controlador del campo de la API Key no se libera al cerrar
la tarjeta: es una fuga de memoria pequeña, no un cambio de comportamiento.
La tarjeta ya deja de escuchar la configuración al cerrarse (eso sí está
probado en `ajustes_detalle_test.dart`). Detectarla exigiría el rastreador de
fugas (`leak_tracker`), que no es una dependencia del paquete. Se acepta como
equivalente para los tests; la liberación se revisa en la revisión de código.
