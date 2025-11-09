# PR Workflow Guidance

Cuando la plataforma muestra el mensaje:

> "Actualmente, Codex no permite actualizar las PR que se hayan actualizado fuera de la plataforma. Por el momento, crea una nueva PR."

significa que el sistema detectó cambios en la Pull Request que no fueron realizados desde el entorno controlado por Codex. Para proteger la integridad del historial, la plataforma bloquea nuevas actualizaciones sobre esa PR y exige abrir una nueva solicitud que incluya todos los cambios vigentes.

## ¿Por qué sucede?

- Se hicieron *push* directamente desde la línea de comandos o desde otra herramienta fuera de Codex.
- Otra persona modificó la misma rama en GitHub después de que Codex la preparó.
- La PR fue *force-pushed* o reescrita mediante *rebase* manual.

En cualquiera de estos escenarios, Codex ya no puede garantizar que el estado de la PR coincida con el que la plataforma conoce, de modo que opta por bloquear la actualización.

## ¿Cómo proceder?

1. Sincroniza tu copia local con la rama que contiene los cambios finales.
2. Crea una nueva rama desde el estado actualizado (`git checkout -b feature/nueva-pr`).
3. Realiza los commits necesarios siguiendo el flujo habitual de Codex.
4. Genera una nueva Pull Request y referencia la anterior para mantener el historial.

## Buenas prácticas para evitar el mensaje

- Evita hacer *push* manual a las ramas gestionadas por Codex.
- No uses `git push --force` salvo que la plataforma lo solicite explícitamente.
- Coordina con otras personas para que no modifiquen la rama mientras Codex está trabajando en ella.

Mantener el control de los cambios desde una sola herramienta evita inconsistencias y garantiza que Codex pueda actualizar la PR automáticamente cuando se solicite.
