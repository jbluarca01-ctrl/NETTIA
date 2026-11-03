# GUÍA UNIVERSAL DE TRABAJO (anexo de la Ley de Calidad)

> **Qué es:** el *cómo* trabajar en cualquier proyecto. La [Ley de Calidad](LEY_DE_CALIDAD.md) dice *qué* se exige; esta guía dice cómo cumplirlo sin perder tiempo.
> **Precedencia:** si algo de aquí choca con la Ley, **gana la Ley**. Esta guía no baja ningún umbral ni levanta ninguna prohibición.
> **Aplica a:** todos los agentes (Claude Code, AGY/Gemini, Codex, Cline y cualquier otro), en todos los proyectos.
> **Origen:** rescata lo útil de la "Guía Maestra — Flujo universal" (evaluada el 2026-11-01, ver `c:\dev\informes\INFORME_EVALUACION_GUIA_MAESTRA_FLUJO_2026-11-01.md`), adaptado a la Ley §1–§11. Aprobada por Jairo el 2026-11-03.
> **Fuente única:** `C:\Users\jblua\.claude\GUIA_UNIVERSAL.md`. Las copias en la raíz de cada repo deben ser idénticas (sección 9).

---

## 1. Primer paso de toda tarea: fijar el nivel (Ley §11)

| Nivel | Señales (rutas o tipo de cambio) | Lo que se paga |
|-------|----------------------------------|----------------|
| **N0 trivial** | `*.md`, textos/traducciones, estilos sin lógica, borrar código muerto sin importadores, configuración sin lógica | Linter en 0 + suite existente en verde |
| **N1 normal** | Pantallas y widgets, cableado entre capas, bugs simples, refactor sin cambio de comportamiento | Test-first con rojo previo + todas las puertas **menos mutación** |
| **N2 crítico** | Cálculo, parsing, conversión, máquinas de estado, corrección de respuestas, seguridad/secretos, persistencia y migraciones, núcleo IA/RAG, el propio gate | **Gauntlet completo**; mutación una sola vez al cierre de la feature |

Reglas: manda el nivel más alto de lo tocado; en duda, el superior; el ejecutor nunca baja el nivel (lo reporta). El nivel se escribe en la orden de la tarea y en el walkthrough.

---

## 2. Flujo por nivel

### N0
1. Cambiar.
2. `analyze` + suite → verde.
3. Commit (`docs:`/`chore:` … `— N0`). Entrega: hash + `git diff --stat`.

### N1
1. **Investigación** solo si la causa es desconocida (plantilla 4.1).
2. **Gherkin** solo si hay comportamiento visible nuevo (`features/*.feature`).
3. Test(s) nuevos → **mostrar el rojo** → código → verde.
4. Refactor + endurecimiento en un paso: cobertura 100 % de lo nuevo, CRAP ≤ 6, CC ≤ 10, función ≤ 40 líneas, archivo ≤ 400, 0 duplicación, 0 ciclos.
5. QA en el dispositivo si el usuario lo ve.
6. Entrega (sección 6).

### N2 (los 8 estados de la Ley §1)
`INVESTIGACIÓN → ESPECIFICACIÓN → GHERKIN → CÓDIGO → REFACTOR → ENDURECIMIENTO → QA → ENTREGA`

- Feature de **más de un día** o con varias tareas: usar las plantillas 4.1–4.4 completas.
- Feature N2 de una sola tarea pequeña: basta la spec corta (4.2) con los requisitos EARS y los `.feature`.
- Durante las tareas intermedias el gate corre **sin mutación**; la mutación (código + Gherkin) corre **una vez** al cierre, diferencial. El watchdog cuenta los intentos de esa corrida final.

---

## 3. Convenciones

| Qué | Convención |
|-----|------------|
| Numeración de features | `SPEC-NNN` correlativo por proyecto (registro en `c:\dev\informes\<Proyecto>\SPECS.md`). Solo N2 con spec; N0/N1 no la necesitan |
| Ramas | `feature/NNN-nombre`, `fix/nombre`, `gate/nombre` (Ley §9/§10). Nunca escribir en `main`/`master`/`develop` |
| Commits | `tipo(ámbito): SPEC-NNN Tn: qué cambió — <estado del gate>`; el estado es `GATE APRUEBA`, `SIN GATE` o `N0`. Si hubo desviación, va en el cuerpo |
| Nombres de tests (N2 con spec) | Incluir `SPEC-NNN-RFn` en la descripción del test que valida ese requisito |
| `.feature` | Un archivo por tarea en `features/`; la spec **enlaza** los `.feature`, no los copia |
| Evidencia | `c:\dev\informes\<Proyecto>\evidencia\` con nombre + fecha: `ROJO_<tarea>_<fecha>.txt`, `GATE_<tarea>_<veredicto>_<fecha>.txt`, `QA_<tarea>_<fecha>.md` |
| Informes | `.md` con nombre + fecha en `c:\dev\informes\<Proyecto>\` |
| Worktrees | Uno por agente/tarea, **temporales**: se eliminan al terminar. Nada suelto en `c:\dev` |
| Coordinación entre agentes | Solo vía `c:\dev\coordinacion\<Proyecto>\` |

---

## 4. Plantillas

### 4.1 `research.md` (estado INVESTIGACIÓN — sin tocar código)
```markdown
# Investigación: <pregunta> — <fecha>
**Nivel previsto:** N1/N2 · **Autor:** <agente>
## Pregunta
## Hallazgos (cada uno con ruta:línea o comando + salida real)
## Causa raíz
## Alternativas (con costo y riesgo)
## Riesgos
## Recomendación
## Dictamen: GO / NO-GO (lo firma el arquitecto)
## Qué no se pudo verificar
```

### 4.2 `spec.md` (estado ESPECIFICACIÓN)
```markdown
# SPEC-NNN <nombre> — <fecha> · Nivel N2
## Objetivo (una frase: qué gana el usuario)
## Requisitos (EARS, numerados)
- RF1 (Ubicuo): El sistema <hace X>.
- RF2 (Evento): Cuando <ocurre E>, el sistema <hace X>.
- RF3 (Estado): Mientras <estado S>, el sistema <hace X>.
- RF4 (No deseado): Si <entrada inválida/falla F>, el sistema <responde Y>.
- RF5 (Opcional): Donde <condición/configuración C>, el sistema <hace X>.
## Fuera de alcance
## Escenarios: enlaces a features/<archivo>.feature (cada RF con su caso de error)
## Decisiones pendientes de Jairo
```
Regla: todo RF de tipo Evento o Estado necesita al menos un RF "No deseado" que diga qué pasa cuando falla.

### 4.3 `plan.md` (diseño, antes del código)
```markdown
# Plan SPEC-NNN — <fecha>
## Diseño decidido (módulos, firmas públicas, dirección de dependencias)
## Prohibiciones explícitas (lo que NO se toca ni se hace)
## Estado nuevo y su ciclo de vida (nace / quién lo modifica / cuándo se destruye)
## Riesgos y cómo se prueban
```

### 4.4 `tasks.md`
```markdown
## T1 — <comportamiento observable> · Nivel N1/N2
- Requisitos: RF1, RF4
- Escenarios: features/t01_<nombre>.feature
- Archivos permitidos (uno por línea; tocar otro = desviación):
  lib/src/...
  test/...
- Criterio de salida: <puertas del nivel>
```
Límite (Ley §7): si una tarea toca más de ~5 archivos de producción, se divide antes de empezar.

### 4.5 Orden para otro agente (directiva)
```markdown
# Directiva <tarea> — <fecha> · Nivel N?
Worktree: <ruta> · Rama: <rama> · Base: <commit>
Objetivo / Requisitos / Escenarios / Archivos permitidos / Prohibiciones
Entrega: walkthrough de la Ley §5 en c:\dev\coordinacion\<Proyecto>\
Recordatorio: no commit sin gate en 0, nunca push, nunca tocar gate.yaml ni tests existentes.
```

---

## 5. Revisión del arquitecto

1. **Informes de otros agentes:** se verifican contra el código y la salida real antes de aceptarlos; afirmación sin comando = no vale (Ley §8).
2. **Archivos permitidos:** `git diff --name-only <base>` contra la lista de `tasks.md`; cualquier archivo extra se rechaza o se registra como desviación.
3. **Ley y configuración intactas:** el diff no debe tocar `LEY_DE_CALIDAD.md`, `GUIA_UNIVERSAL.md`, `gate.yaml`, reglas de linter/mutación, `QUALITY_EXCEPTIONS.md`, CI ni hooks (salvo orden de Jairo).
4. **Revisión de escenarios** (mientras la mutación de Gherkin no esté integrada en el gate del proyecto): cada regla tiene su caso de error y cada valor de un `Then` lo comprueba su paso. Se anota en el walkthrough.
5. **Dos rechazos del mismo punto** → no se parchea una tercera vez: se vuelve a `plan.md` (o a INVESTIGACIÓN) y se replantea.

---

## 6. Entrega (Ley §5, formato corto)

```markdown
# Cierre <tarea> — <fecha> · Nivel N? · Commit <hash> en <rama>
## Cambio: git diff --stat
## Rojo previo: <ruta de la evidencia>
## Gauntlet: salida real (o ruta) con veredicto y código de salida
## Revisión de escenarios: OK / hallazgos
## QA: evidencia del dispositivo (o "no aplica: no lo ve el usuario")
## Desviaciones: lista o "Ninguna"
## Estado nuevo: nace / lo modifica / se destruye (o "Ninguno")
## Pendiente / decisiones de Jairo
```
El código no se pega si está commiteado.

---

## 7. Antes de publicar (Play, APK a terceros o release)

Checklist por proyecto en `c:\dev\informes\<Proyecto>\PERFIL_PRODUCCION_<PROYECTO>_<fecha>.md`, con estado `CUMPLE / N/A (motivo) / PENDIENTE / REVISAR` y evidencia. No es por tarea: se revisa **antes de cada publicación**. Controles mínimos:

| ID | Control | Cómo se comprueba |
|----|---------|-------------------|
| U1 | Sin secretos en repo ni artefacto | Escaneo del historial (gitleaks/Betterleaks) + CI de secretos |
| U2 | Tokens y claves en almacén seguro | `flutter_secure_storage` o equivalente; nunca en `SharedPreferences` ni en el APK |
| U3 | Aislamiento por usuario | Solo si hay backend |
| U4 | Entrada validada | Property tests en parsing/cálculo (Ley §3) |
| U5 | Build endurecido | R8/minify + `flutter build --obfuscate --split-debug-info=<dir>`; respaldar los símbolos |
| U6 | Dependencias fijas y escaneadas | `pubspec.lock` versionado + OSV-Scanner en 0 (128 = sin paquetes, nunca es éxito) |
| U7 | Firma fuera del repo | Keystore fuera de git; idealmente firma desde CI |
| U8 | Versionado y ramas | Ley §9/§10 |
| U9 | Requisitos de Play | targetSdk vigente, ficha, política de datos |
| U11 | Transporte cifrado | Solo HTTPS |
| U12 | Llamadas resilientes | Timeouts, reintentos acotados, error visible al usuario |
| U15 | Funciona sin conexión donde se promete | QA en modo avión |
| U19 | Reporte de fallos | Errores globales capturados y persistidos |
| U21 | Privacidad | Aviso de qué datos salen del dispositivo (p. ej. al proveedor de IA) |
| U22 | Superficie mínima | Permisos mínimos, `allowBackup="false"`, `exported` solo lo necesario |
| U23 | Accesibilidad | Tamaños de toque, contraste, etiquetas semánticas |
| U24 | Cobro | Solo si la app cobra |
| U25 | Páginas de 16 KB en `.so` | `zipalign -c -P 16 -v 4 <apk>`. Obligatorio en Play desde el 1-feb-2027 |
| U26–U28 | Ley de Calidad | Gate en 0 sobre el commit publicado + QA en dispositivo real |

Los IDs que faltan (U10, U13, U14, U16–U18, U20) se agregan aquí cuando un proyecto los necesite; no se inventan.

---

## 8. Lo que NO se adopta de la Guía Maestra original (choca con la Ley)

- Ramas `work/NNN-nombre` → se usan `feature/*`, `fix/*`, `gate/*`.
- "Solo se commitea con gate en 0" para todos → Claude Code puede commitear y pushear sin gate marcando `SIN GATE` (Ley §10).
- Orden fijo de ejecutores → el arquitecto asigna; cada agente en su worktree.
- Código de salida 2 = "solo advertencias" → en `c:\dev\gate`, 2 = configuración inválida y 70 = error interno.
- Fases F0–F8 como sustituto de los estados de la Ley → no; mandan los estados de la Ley §1.
- Gherkin dentro de `spec.md` → los `.feature` viven en `features/`.
- Checks en `.sh` → los checks nuevos van en Dart dentro de `c:\dev\gate`.

---

## 9. Sincronización de copias

- Fuente: `C:\Users\jblua\.claude\LEY_DE_CALIDAD.md` y `C:\Users\jblua\.claude\GUIA_UNIVERSAL.md`.
- Copias idénticas en la raíz de cada repo (`c:\dev\PRAXIA`, `c:\dev\Nettia`, `c:\dev\gate`, y todo proyecto nuevo).
- Solo Jairo cambia la fuente (o el arquitecto con su orden explícita); el cambio se propaga a las copias en la misma sesión, en una rama `feature/*` de cada repo, como cambio N0.
- Comprobación (sin diferencias = sincronizado; se ignoran los fines de línea):
  ```bash
  for r in PRAXIA Nettia gate; do for f in LEY_DE_CALIDAD.md GUIA_UNIVERSAL.md; do
    diff -q <(tr -d '\r' < ~/.claude/$f) <(tr -d '\r' < /c/dev/$r/$f) >/dev/null && echo "OK $r/$f" || echo "DIFIERE $r/$f"
  done; done
  ```
- Pendiente (requiere autorización de Jairo porque toca `gate.yaml`): convertir esta comprobación y la del punto 5.2–5.3 en puertas del gate.
