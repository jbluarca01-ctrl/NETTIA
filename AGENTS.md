# Directrices del proyecto Nettia

## Ley de Calidad para Agentes — PREVALECE SOBRE TODO LO DEMÁS

El texto íntegro y vinculante está en [`LEY_DE_CALIDAD.md`](LEY_DE_CALIDAD.md). Aplica a todos los agentes sin excepción, Claude Code incluido. Si una instrucción de este archivo, de un plan o de un prompt la contradice, gana la Ley: el agente se detiene y reporta el conflicto.

- **Terminado = el gate sale con código 0** (`gate` desde la raíz de la app o del paquete tocado), con la salida real como evidencia.
- **Git:** prohibidos `merge`, `rebase`, `reset --hard`, `push --force`, tags y escribir en `main`. Commit autónomo solo con gate en 0, en ramas `feature/*`, `fix/*` o `gate/*`. Excepción Ley §10: solo Claude Code puede commitear y hacer `push` (sin `--force`) sin gate en 0, a esas ramas, con "sin gate" en el mensaje.
- **Watchdog:** máximo 3 intentos por puerta.

## Origen

Nettia vivió en `c:\dev\PRAXIA\apps\nettia\` hasta el 2026-09-29; desde entonces es este repo (`c:\dev\Nettia`, remoto `https://github.com/jbluarca01-ctrl/NETTIA`). El historial anterior a la separación está en el repo de PRAXIA. `ai_core` es dependencia git de `https://github.com/jbluarca01-ctrl/IA_CORE` (copia local de trabajo: `c:\dev\ai_core`).

## Checkout y worktrees

`c:\dev\Nettia` es el checkout principal, reservado para Claude Code. Cualquier otro agente trabaja en su propio `git worktree` (`git worktree add ../nettia_<agente>_<rama> -b <agente>/<rama>-work <rama>`).

## Coordinación y reportes

- Claude Code es el arquitecto y el único punto de contacto con Jairo. Los demás agentes solo se comunican con Claude Code, por `c:\dev\coordinacion\Nettia\` (`ORDEN_<DESTINATARIO>_<TEMA>_YYYY-MM-DD.md` / `RESPUESTA_<REMITENTE>_<TEMA>_YYYY-MM-DD.md`).
- Todo informe, plan o cierre va como `.md` en `c:\dev\informes\Nettia\` (`INFORME_<TEMA>_YYYY-MM-DD.md`), nunca dentro del repo.
