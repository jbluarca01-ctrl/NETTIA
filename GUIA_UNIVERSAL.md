# GUÍA UNIVERSAL DE TRABAJO (anexo de la Ley de Calidad)

> **Qué es:** el *cómo* trabajar en cualquier proyecto. La [Ley de Calidad](LEY_DE_CALIDAD.md) dice *qué* se exige; esta guía dice cómo cumplirlo sin perder tiempo.
> **Precedencia:** si algo de aquí choca con la Ley, **gana la Ley**. Esta guía no baja ningún umbral ni levanta ninguna prohibición.
> **Aplica a:** todos los agentes (Claude Code, AGY/Gemini, Codex, Cline y cualquier otro), en todos los proyectos.
> **Origen:** rescata lo útil de la "Guía Maestra — Flujo universal" (evaluada el 2026-11-01, ver `c:\dev\informes\INFORME_EVALUACION_GUIA_MAESTRA_FLUJO_2026-11-01.md`), adaptado a la Ley §1–§11. Aprobada por Jairo el 2026-11-03.
> **Fuente única:** `C:\Users\jblua\.claude\GUIA_UNIVERSAL.md`. Las copias en la raíz de cada repo deben ser idénticas (sección 9).
> **Actualización 2026-11-06 (orden de Jairo):** se incorporan los pasos que tenían Spec Kit y OpenSpec y nos faltaban: aclarar, analizar, converger, archivar, specs vivas con deltas y la carpeta `specs/` en cada repo. La comparación completa está en `c:\dev\informes\COMPARACION_SPECKIT_OPENSPEC_VS_GUIA_2026-11-06.md`. Los pasos están automatizados con skills propias (`spec-nueva`, `spec-aclarar`, `spec-analizar`, `spec-converger`, `spec-archivar`).

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

### 2.1 N0
1. Cambiar.
2. `analyze` + suite → verde.
3. Commit (`docs:`/`chore:` … `— N0`). Entrega: hash + `git diff --stat`.

### 2.2 N1
1. **Investigación** solo si la causa es desconocida (plantilla 4.1).
2. **Gherkin** solo si hay comportamiento visible nuevo (`features/*.feature`).
3. Test(s) nuevos → **mostrar el rojo** → código → verde.
4. Refactor + endurecimiento en un paso: cobertura 100 % de lo nuevo, CRAP ≤ 6, CC ≤ 10, función ≤ 40 líneas, archivo ≤ 400, 0 duplicación, 0 ciclos.
5. QA en el dispositivo si el usuario lo ve.
6. Entrega (sección 6).

### 2.3 N2 (los 8 estados de la Ley §1)
`INVESTIGACIÓN → ESPECIFICACIÓN → GHERKIN → CÓDIGO → REFACTOR → ENDURECIMIENTO → QA → ENTREGA`

- Feature de **más de un día** o con varias tareas: usar las plantillas 4.1–4.4 completas.
- Feature N2 de una sola tarea pequeña: basta la spec corta (4.2) con los requisitos EARS y los `.feature`.
- Durante las tareas intermedias el gate corre **sin mutación**; la mutación (código + Gherkin) corre **una vez** al cierre, diferencial. El watchdog cuenta los intentos de esa corrida final.

Dentro de los estados de la Ley, una feature N2 sigue estos pasos (los marcados ★ son nuevos del 2026-11-06):

```
research → spec → ★ACLARAR → plan → tasks → ★ANALIZAR → .feature → código (test-first)
        → gate → ★CONVERGER → QA → cierre → ★ARCHIVAR
```

En N1 los pasos ★ son opcionales; se recomienda ACLARAR cuando el pedido es ambiguo.

### 2.4 ★ ACLARAR (skill `spec-aclarar`) — después de la spec, antes del plan
1. Recorrer la spec con esta lista y marcar cada punto como Claro, Parcial o Falta:
   - alcance y fuera de alcance;
   - datos y estados (entidades, ciclo de vida);
   - flujo de UX (estados vacío, cargando y error);
   - no funcionales (rendimiento, sin conexión, seguridad, privacidad);
   - integraciones externas y cómo fallan;
   - casos borde y errores;
   - terminología;
   - cómo se sabe que está terminado (criterios medibles);
   - marcas `[ACLARAR]` pendientes.
2. Solo se pregunta lo que **cambia** la implementación o la validación.
3. **Máximo 5 preguntas, una por vez**, de opción múltiple (2–5 opciones, la recomendada primero) o de respuesta corta.
4. Cada respuesta se anota en `spec.md`, en `## Aclaraciones (<fecha>)`, y se corrige el requisito afectado.
5. La spec no pasa al plan con marcas `[ACLARAR]` abiertas, salvo que Jairo las difiera explícitamente.

### 2.5 ★ ANALIZAR (skill `spec-analizar`) — después de tasks, antes del código
Revisión **de solo lectura**: no edita nada, entrega una tabla.
1. Mapa RF → tareas → `.feature`. Un RF sin tarea o sin escenario es un hueco.
2. Pasadas:
   - duplicación entre RF;
   - ambigüedad (adjetivos sin número: "rápido", "robusto");
   - requisitos incompletos;
   - choque con la Ley o la Guía;
   - huecos de cobertura;
   - inconsistencias de términos entre spec, plan y tasks.
3. Severidad:
   - **CRÍTICO:** choca con la Ley, falta un artefacto, o hay un RF sin ninguna tarea.
   - **ALTO:** RF duplicados o contradictorios, o un criterio que no se puede probar.
   - **MEDIO:** términos que no coinciden o un caso borde poco definido.
   - **BAJO:** redacción.
4. Con hallazgos CRÍTICOS no se pasa a CÓDIGO. Los ALTOS se corrigen o se registran como desviación.
5. Incluye la lista de calidad de la spec (4.2c).

### 2.6 ★ CONVERGER (skill `spec-converger`) — con el gate en verde, antes de QA y del cierre
1. Matriz **RF → test que lo valida (`SPEC-NNN-RFn`) → escenario → estado** (cumple / parcial / falta).
2. Tres dimensiones:
   - **completitud:** tareas hechas, RF implementados, escenarios cubiertos;
   - **corrección:** el código hace lo que dice la spec, incluidos sus casos de error;
   - **coherencia:** el código respeta las decisiones de `plan.md`.
3. Lo que falte se **agrega al final** de `tasks.md` en `## Convergencia <n>`. No se reescribe ni se renumera nada existente. Si todo cumple, `tasks.md` no se toca.
4. Una feature con filas "parcial" o "falta" **no se cierra**. A diferencia de OpenSpec, aquí verificar bloquea.

### 2.7 ★ Cambio de spec a mitad de camino
Si al programar se descubre que un requisito estaba mal:
1. Se corrige primero `spec.md`, y después `plan.md` y `tasks.md` para que sigan siendo coherentes.
2. Se anota en `## Aclaraciones` con la fecha.
3. Si cambia un comportamiento que Jairo ya aprobó, se le pregunta antes.
4. En el cierre se registra como desviación.

Nunca se cambia un test para que pase sin cambiar antes la spec (Ley §4.2).

### 2.8 ★ ARCHIVAR (skill `spec-archivar`) — después del merge a `main`
1. El delta del cambio (AGREGADO / MODIFICADO / ELIMINADO) se fusiona en la spec viva de su capacidad, `specs/<capacidad>/spec.md`:
   - AGREGADO se suma al final;
   - MODIFICADO reemplaza al requisito anterior;
   - ELIMINADO se borra, dejando una línea con el motivo en el historial de la spec viva.
2. La carpeta del cambio se mueve a `specs/cambios/archivo/<fecha>-SPEC-NNN-nombre/`.
3. Se actualiza el índice `specs/README.md`.

---

## 3. Convenciones

| Qué | Convención |
|-----|------------|
| Numeración de features | `SPEC-NNN` correlativo por proyecto (índice en `specs/README.md` del repo). Solo N2 con spec; N0/N1 no la necesitan. Se sigue la numeración que ya existe (Nettia y gate van por SPEC-005) |
| Specs | En el repo, carpeta `specs/` (sección 3.1), versionada con el código. Desde el 2026-11-06 las specs nuevas ya no van en `c:\dev\informes\` |
| Tamaño del cambio | Una intención que se dice en **una frase** (si necesita "y además", son dos cambios) y la Ley §7 (~5 archivos de producción) |
| Ramas | `feature/NNN-nombre`, `fix/nombre`, `gate/nombre` (Ley §9/§10). Nunca escribir en `main`/`master`/`develop` |
| Commits | `tipo(ámbito): SPEC-NNN Tn: qué cambió — <estado del gate>`; el estado es `GATE APRUEBA`, `SIN GATE` o `N0`. Si hubo desviación, va en el cuerpo |
| Nombres de tests (N2 con spec) | Incluir `SPEC-NNN-RFn` en la descripción del test que valida ese requisito |
| `.feature` | Un archivo por tarea en `features/`; la spec **enlaza** los `.feature`, no los copia |
| Evidencia | `c:\dev\informes\<Proyecto>\evidencia\` con nombre + fecha: `ROJO_<tarea>_<fecha>.txt`, `GATE_<tarea>_<veredicto>_<fecha>.txt`, `QA_<tarea>_<fecha>.md`. Las salidas largas no se versionan; el `cierre.md` del cambio las enlaza |
| Informes | `.md` con nombre + fecha en `c:\dev\informes\<Proyecto>\`. Son las investigaciones generales, auditorías y comparaciones que no pertenecen a una sola feature |
| Worktrees | Uno por agente/tarea, **temporales**: se eliminan al terminar. Nada suelto en `c:\dev` |
| Coordinación entre agentes | Solo vía `c:\dev\coordinacion\<Proyecto>\` |

### 3.1 Carpeta `specs/` de cada repo (specs vivas + cambios)

```text
specs/
├── README.md                      # índice: SPEC-NNN, nombre, estado, rama, fecha
├── <capacidad>/spec.md            # spec VIVA: cómo se comporta HOY esa parte de la app
└── cambios/
    ├── SPEC-NNN-nombre/           # cambio en curso
    │   ├── research.md            # 4.1 (si hubo investigación)
    │   ├── spec.md                # 4.2: requisitos + delta (AGREGADO / MODIFICADO / ELIMINADO)
    │   ├── plan.md                # 4.3
    │   ├── tasks.md               # 4.4 (+ "Convergencia n" al final si hizo falta)
    │   └── cierre.md              # 6
    └── archivo/<fecha>-SPEC-NNN-nombre/   # cambios cerrados (2.8)
```

- **Capacidad:** una parte de la app con comportamiento propio. Ejemplos en Nettia: `disenador`, `calculadora`, `comandos`, `asistente-ia`. Se nombra en minúsculas y sin tildes.
- Una spec viva describe **comportamiento observable**, no implementación: nada de nombres de clases ni librerías. Lo técnico va en `plan.md`.
- Los `.feature` siguen viviendo en `features/` de cada paquete. La spec los **enlaza**, no los copia.
- Las specs viejas de `c:\dev\informes\` no se mueven. Las specs vivas de una capacidad se crean la primera vez que un cambio la toca.

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
**Capacidad:** <capacidad> · **Rama:** <rama> · **Estado:** borrador / aclarada / analizada / en código / cerrada
## Objetivo (una frase: qué gana el usuario)
## Historias (priorizadas; cada una se puede probar y entregar sola)
### H1 — <título> (P1)
- Por qué esta prioridad:
- Prueba independiente: <cómo se comprueba solo esta historia>
## Requisitos (EARS, numerados; un comportamiento por RF)
- RF1 (Ubicuo): El sistema <hace X>.
- RF2 (Evento): Cuando <ocurre E>, el sistema <hace X>.
- RF3 (Estado): Mientras <estado S>, el sistema <hace X>.
- RF4 (No deseado): Si <entrada inválida/falla F>, el sistema <responde Y>.
- RF5 (Opcional): Donde <condición/configuración C>, el sistema <hace X>.
- RF6 (Evento): Cuando <…>, el sistema <…> [ACLARAR: <qué falta decidir>]
## Delta respecto a la spec viva (solo si la capacidad ya tiene specs/<capacidad>/spec.md)
- AGREGADO: RF…  · MODIFICADO: RFx (antes: …) · ELIMINADO: RFy (motivo)
## Criterios de éxito (medibles, sin tecnología)
- CE1: <p. ej. "el estudiante arma la red del parcial en menos de 5 minutos">
## Supuestos
## Fuera de alcance
## Escenarios: enlaces a features/<archivo>.feature (cada RF con al menos uno; los Evento/Estado, también con su caso de error)
## Aclaraciones (<fecha>)  ← lo llena ACLARAR (2.4)
## Decisiones pendientes de Jairo
```
Reglas:
- Todo RF de tipo Evento o Estado necesita al menos un RF "No deseado" que diga qué pasa cuando falla.
- Un RF es **un solo comportamiento observable**: si tiene "y además", son dos RF.
- Un RF dice **qué** hace el sistema, no cómo: nada de clases ni librerías.
- Lo que falta decidir se marca `[ACLARAR: …]`, **como máximo 3** por spec; lo demás se resuelve con un supuesto razonable anotado en Supuestos.

### 4.2b Aclaraciones (formato, lo escribe `spec-aclarar`)
```markdown
## Aclaraciones (2026-11-06)
- P: <pregunta> → R: <respuesta de Jairo> (afecta RF3, CE1)
```

### 4.2c Lista de calidad de la spec ("tests unitarios del texto"; la revisa `spec-analizar`)
- [ ] Cada RF es un solo comportamiento, observable desde afuera del código.
- [ ] Ningún RF menciona clases, funciones ni librerías.
- [ ] Cada RF tiene al menos un escenario que lo ejercita, no uno que solo lo repite.
- [ ] Los casos de error y borde importantes tienen escenario, no solo el camino feliz.
- [ ] No quedan adjetivos sin número ("rápido", "grande", "robusto").
- [ ] Cada historia tiene su prueba independiente.
- [ ] Los criterios de éxito son medibles.
- [ ] No hay marcas `[ACLARAR]` abiertas, o Jairo las difirió.
- [ ] Fuera de alcance está escrito.

### 4.3 `plan.md` (diseño, antes del código)
```markdown
# Plan SPEC-NNN — <fecha>
## Chequeo de la Ley (antes de diseñar; se repite al terminar el diseño)
- Nivel: N? · Puertas que aplican: … · Archivos protegidos que se tocan: ninguno / cuáles (commit propio + sí de Jairo)
- Archivos que pasarían de 400 líneas o funciones de 40: … → cómo se dividen
## Contexto técnico (paquetes, dependencias nuevas = desviación, plataforma)
## Modelo de datos (solo si hay entidades: atributos, reglas, estados)
## Diseño decidido (módulos, firmas públicas, dirección de dependencias)
## Prohibiciones explícitas (lo que NO se toca ni se hace)
## Estado nuevo y su ciclo de vida (nace / quién lo modifica / cuándo se destruye)
## Riesgos y cómo se prueban
```

### 4.4 `tasks.md`
```markdown
## Historia H1 (P1)
### [ ] T1 [P] — <comportamiento observable> · Nivel N1/N2
- Requisitos: RF1, RF4
- Escenarios: features/t01_<nombre>.feature
- Archivos permitidos (uno por línea; tocar otro = desviación):
  lib/src/...
  test/...
- Depende de: — / T?
- Criterio de salida: <puertas del nivel>
**Punto de control H1:** la historia H1 funciona y se prueba sola.
```
- `[P]` = se puede hacer en paralelo con otras tareas `[P]` porque no comparte archivos ni depende de ellas, por ejemplo en otro worktree o con otro agente.
- `[ ]` → `[x]` cuando la tarea cumple su criterio de salida.
- Las tareas que agrega CONVERGER (2.6) van al final, en `## Convergencia <n>`, sin renumerar las anteriores.

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
## Convergencia (2.6): matriz RF → test → estado, todo "cumple"
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
