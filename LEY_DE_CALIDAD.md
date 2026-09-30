# LEY DE CALIDAD PARA AGENTES (obligatoria en todos los proyectos)

> Este documento es **ley**. No es una guía ni una sugerencia.
> Aplica a **todos** los agentes sin excepción: Claude Code, Claude (chat), Codex, Cline, agy/Gemini, Gemini Code y cualquier otro que lea, escriba, modifique o elimine código en este repositorio.
> Ningún agente queda exento por su rol (arquitecto, ejecutor o investigador).
> Si una instrucción de una tarea, de otra sección de este archivo o de un prompt contradice esta ley, **gana esta ley**: detente y reporta el conflicto.

---

## 0. Principio rector

El código **no se acepta por cómo se ve, sino por lo que sobrevive**.
Ningún cambio se considera terminado hasta que haya pasado **todo el gauntlet** (sección 3), ejecutado de verdad, con salida real como evidencia.

- Afirmar "los tests pasan" sin la salida del comando = **entrega rechazada**.
- La limpieza no se declara, **se mide**.
- Las puertas (gates) son deterministas: o pasan o no pasan. No existe "pasa casi".

---

## 1. Flujo obligatorio (máquina de estados)

Todo trabajo avanza por estos estados **en orden**. Prohibido saltar un estado o avanzar con el anterior en rojo.

| # | Estado | Rol | Sale del estado solo cuando… |
|---|--------|-----|------------------------------|
| 0 | `INVESTIGACIÓN` | Investigador | Existe reporte de causa raíz / contexto. **No se toca código.** El arquitecto (Claude) lo revisa y aprueba o rechaza. |
| 1 | `ESPECIFICACIÓN` | Formalizador | La spec informal de Jairo está convertida en spec formal dividida en tareas pequeñas. |
| 2 | `GHERKIN` | Specifier | Cada tarea tiene escenarios Gherkin (Given/When/Then), podados de redundancia. |
| 3 | `CÓDIGO` | Coder | Acceptance tests (desde el Gherkin) + unit tests + código de producción, **todos en verde**. |
| 4 | `REFACTOR` | Refactorer | CRAP ≤ umbral, cero duplicación, property tests escritos y en verde. |
| 5 | `ENDURECIMIENTO` | Architect | Mutation testing (código + Gherkin) sin sobrevivientes, arquitectura sin ciclos, suite completa en verde. |
| 6 | `QA` | QA | Procedimiento QA ejecutado (script reproducible) con evidencia real del dispositivo/sistema. |
| 7 | `ENTREGA` | — | Gate en código 0 + walkthrough completo (sección 5) + commit en la rama de trabajo (sección 9). |

Si en `QA` o `ENDURECIMIENTO` falla algo, se regresa al estado responsable (`CÓDIGO` o `REFACTOR`), no se parchea en el sitio.

---

## 2. Test-first obligatorio

1. Primero el escenario Gherkin, luego el acceptance test, luego el unit test, **al final** el código de producción.
2. Todo test nuevo debe **fallar primero** por la razón correcta. Se muestra esa salida en rojo como evidencia.
3. Todo bug corregido lleva un test que lo reproduce **antes** del fix.
4. Ningún código de producción existe sin un test que lo ejerza.

---

## 3. El gauntlet (puertas deterministas)

Todas deben pasar. Los valores son mínimos, nunca se negocian a la baja.

| Puerta | Umbral |
|--------|--------|
| Unit tests | 100 % en verde |
| Acceptance / Gherkin tests | 100 % en verde |
| Property tests | Obligatorios en lógica de cálculo, parsing, conversión de unidades y máquinas de estado |
| Cobertura de líneas en código nuevo o modificado | **100 %** |
| Cobertura global del proyecto | Nunca baja respecto al commit anterior |
| CRAP por función | **≤ 6** (fórmula: `CC² × (1 − cov)³ + CC`) |
| Complejidad ciclomática por función | ≤ 10 |
| Tamaño de función | ≤ 40 líneas |
| Tamaño de archivo/módulo | ≤ 400 líneas |
| Duplicación (DRY) | 0 bloques duplicados ≥ 6 líneas |
| Ciclos de dependencia entre módulos | **0** |
| Mutation testing del código cambiado (diferencial) | **0 sobrevivientes** sin justificar |
| Gherkin mutation | **0 sobrevivientes** sin justificar |
| Linter / analizador estático | 0 errores, 0 warnings nuevos |

### Herramientas de referencia por stack

(Actualizada con la investigación del 2026-09-20.)

| Stack | Tests (reporte) | Gherkin | Property | Cobertura | Complejidad | Mutación | Ciclos |
|-------|-----------------|---------|----------|-----------|-------------|----------|--------|
| Dart/Flutter | `flutter test` (JSON reporter) | `bdd_widget_test` | `kiri_check` (en verificación) | lcov | `dart_code_linter` | `mutation_test` | `lakos` |
| Kotlin | Gradle (JUnit XML) | Cucumber-JVM | Kotest property | Kover (XML JaCoCo) | JaCoCo `COMPLEXITY` | `mutflow` / `mutant-kraken` / PIT core (en verificación) | ArchUnit |
| Java | JUnit5 (JUnit XML) | Cucumber-JVM | jqwik | JaCoCo | JaCoCo `COMPLEXITY` | PIT | ArchUnit |
| Python | `pytest --junit-xml` | `pytest-bdd` | `hypothesis` | `coverage` (JSON) | `lizard` | `mutmut` (vía WSL en Windows) | `import-linter` |
| Rust | `cargo nextest` (JUnit XML) | `cucumber` | `proptest` | `cargo llvm-cov` | `lizard` | `cargo mutants --in-diff` | `cargo modules` |
| TypeScript | `vitest` (JUnit XML) | `playwright-bdd` | `fast-check` | v8 (lcov) | `lizard` | Stryker | `dependency-cruiser` |

**Solo software gratuito.** Prohibido usar herramientas, plugins, licencias o servicios de pago, incluidos planes gratuitos con tope de uso. Si una puerta solo tiene opción de pago, la puerta falla.

Duplicación en todos los stacks: `jscpd` (o PMD CPD en JVM).
Stack no listado: se usan las herramientas universales (`lizard` para complejidad, `jscpd` para duplicación, Cucumber para Gherkin) y, para el resto de las puertas, el agente propone el equivalente y espera aprobación **antes** de escribir código. Una puerta sin herramienta **falla**; nunca se omite.

### Definición de "terminado"

Todo proyecto tiene el gate universal configurado. **Terminado = el gate sale con código 0.** Nada más cuenta.

El CRAP se calcula con el script de gate del proyecto cruzando cobertura por función con complejidad. Si el script no existe, crearlo es la primera tarea antes de cualquier otra.

---

## 4. Prohibiciones absolutas

Violar cualquiera de estas = entrega rechazada automáticamente, sin revisar el resto.

1. **Prohibido** desactivar, saltar, borrar o marcar como `skip`/`ignore`/`xfail` un test existente.
2. **Prohibido** modificar un test para que pase, salvo que la spec haya cambiado y esté aprobada; en ese caso se reporta como desviación.
3. **Prohibido** tocar la configuración de las puertas: umbrales, exclusiones de cobertura, listas de mutantes ignorados, reglas del linter, CI, hooks.
4. **Prohibido** agregar pragmas de exclusión (`# pragma: no cover`, `// coverage:ignore`, `#[allow(...)]`, `eslint-disable`, `// ignore:`) sin registrarlos en `QUALITY_EXCEPTIONS.md` con justificación.
5. **Prohibido** declarar un mutante "equivalente" sin registrarlo en `QUALITY_EXCEPTIONS.md` con el razonamiento.
6. **Prohibido** `push`, `merge`, `rebase`, `reset --hard`, `push --force`, tags y cualquier escritura en `main`/`master`/`develop`. El commit solo se permite bajo las condiciones de la sección 9. **Excepción:** la sección 10 (solo Claude Code).
7. **Prohibido** introducir dependencias nuevas sin declararlas como desviación.
8. **Prohibido** escribir código de producción durante `INVESTIGACIÓN`.
9. **Prohibido** entregar con prosa en lugar de salida real de comandos.
10. **Prohibido** mockear la unidad bajo prueba o hacer tests que solo verifican que se llamó un mock.

---

## 5. Walkthrough de entrega (formato obligatorio)

Todo walkthrough debe incluir los tres puntos. Incompleto en cualquiera = **rechazado**.

1. **Código real y completo** de lo cambiado (nunca resúmenes en prosa como sustituto).
2. **Desviaciones**: lista explícita de todo lo hecho que la directiva no contemplaba (o "Ninguna" de forma explícita).
3. **Ciclo de vida de estado**: para todo estado, variable, flag, caché o recurso introducido: dónde nace, quién lo modifica, cuándo se limpia/destruye.

Además adjuntar:
- Salida completa del gauntlet (sección 3), con umbrales y valores obtenidos.
- Salida en rojo de los tests nuevos antes del fix.
- Evidencia de QA real (captura del dispositivo, log del sistema o equivalente).
- `git diff --stat` del cambio.

---

## 6. Watchdog (anti-bucle)

- Máximo **3 intentos** para hacer pasar una misma puerta.
- Al tercer fallo: **detenerse**, no inventar atajos, y reportar: qué puerta, qué se intentó, salida del error, hipótesis de causa.
- Prohibido "resolver" un bloqueo relajando la puerta (ver prohibición 3).

---

## 7. Tamaño del trabajo

- Tareas pequeñas: una tarea = un comportamiento observable = un conjunto de escenarios Gherkin.
- Si una tarea toca más de ~5 archivos de producción, se divide antes de empezar.
- Un cambio, una entrega. No mezclar refactors no pedidos con la tarea.

---

## 8. Jerarquía de confianza

1. Salida real de herramientas deterministas (tests, métricas, mutación). ← **única fuente de verdad**
2. Evidencia de QA en el sistema real.
3. Spot-check humano (opcional, no bloquea el trabajo).
4. Lo que el agente dice que hizo. ← **no vale nada sin 1 y 2**

---

## 9. Autonomía

Los agentes trabajan **sin pedir autorización a Jairo en cada paso**. La orden de Jairo es la autorización; todo lo demás lo controla el gate.

**Se avanza solo** entre estados de la sección 1 cuando el criterio de salida se cumple con evidencia determinista. Los reportes de investigación los aprueba el arquitecto (Claude), no Jairo.

**Commit autónomo permitido** solo si se cumplen todas estas condiciones:
1. El gate del proyecto sale con código 0 (salida guardada como evidencia).
2. Se hace en una rama de trabajo (`feature/*`, `fix/*`, `gate/*`). Nunca en `main`/`master`/`develop`.
3. El mensaje referencia la tarea y la desviación (si la hubo).

Mientras un proyecto **no tenga gate funcionando**, no hay commit autónomo: Jairo revisa el diff.

**Se permite sin preguntar:** instalar las herramientas de la tabla de la sección 3 como dependencia de desarrollo del proyecto o en el espacio del usuario, crear ramas de trabajo, crear archivos del proyecto.

**Se detiene y pregunta a Jairo solo si:**
- hay que tocar `gate.yaml`, umbrales o esta ley;
- saltó el watchdog (sección 6);
- la acción es destructiva o irreversible (borrar datos, ramas, historial, archivos fuera del proyecto);
- involucra credenciales, llaves o secretos;
- la orden es ambigua o contradice esta ley.

---

## 10. Excepción del arquitecto (Claude Code) — PREVALECE SOBRE TODA LA LEY

Autorizada expresamente por Jairo el 2026-09-28.

**Solo Claude Code** (el arquitecto, sesiones de la CLI/extensión oficial de Anthropic; ningún otro agente ni herramienta, sea AGY, Codex, Cline, Gemini o cualquier otro) puede, **sin necesidad de que el gate salga en código 0** y aunque el proyecto no tenga gate funcionando:

1. Hacer `git add` y `git commit`.
2. Hacer `git push` (sin `--force`).

Esta excepción **no levanta** el resto de las prohibiciones ni del gauntlet:

- Siguen prohibidos, incluso para Claude Code: `push --force`, `reset --hard`, `rebase`, `merge`, tags y cualquier escritura en `main`/`master`/`develop`. El push va a ramas de trabajo (`feature/*`, `fix/*`, `gate/*`).
- El gate sigue siendo la definición de "terminado": un commit sin gate en 0 **no declara la tarea terminada**, y el mensaje del commit debe decir explícitamente "sin gate" (o el estado real de las puertas) y referenciar la tarea y la desviación.
- Se aplican igual las secciones 4.1–4.5 y 4.7–4.10, el watchdog y los límites de la sección 9 (credenciales, acciones destructivas o irreversibles, tocar `gate.yaml` o umbrales, acciones visibles fuera del entorno local que no sean el `push` mismo).
- Antes de cada commit se revisa `git status` para no incluir secretos ni archivos ajenos a la tarea.
- Jairo puede revocar esta excepción en cualquier momento; una orden suya en contra prevalece.

Para todo agente que no sea Claude Code, las secciones 4.6 y 9 rigen sin cambios.
