# ADR 0006: PlantUML como estándar de modelado

## Estado
Aceptado

## Contexto
El repositorio documenta más de dos docenas de flujos de aprovisionamiento y operación mediante diagramas UML. La generación original usaba Mermaid porque MkDocs Material lo soporta de manera nativa. Sin embargo, el proyecto estableció como criterio técnico que las representaciones UML debían emplear PlantUML para alinearse con la documentación corporativa existente, permitir reutilizar plantillas previas y facilitar la exportación de diagramas hacia herramientas externas (por ejemplo, IDEs o suites de arquitectura) que reconocen PlantUML.

## Decisión
Se reemplazó Mermaid por PlantUML en todo el repositorio. MkDocs queda configurado con `pymdownx.plantuml` y una valla personalizada `plantuml` dentro de `pymdownx.superfences`, habilitando la renderización desde el servidor público de PlantUML. Todos los artefactos bajo `docs/use_cases/` se regeneraron para emitir diagramas de actividad y de secuencia en sintaxis PlantUML, y la guía de documentación ahora instruye explícitamente sobre el uso de este formato.

## Consecuencias
- Los diagramas del proyecto siguen un formato homogéneo compatible con el estándar técnico solicitado.
- Cualquier contribución nueva debe utilizar bloques `plantuml`, lo que simplifica la validación automatizada incluida en la suite de pruebas.
- El flujo de MkDocs depende del servidor PlantUML especificado; en entornos sin acceso a Internet deberá habilitarse un servidor local o ajustarse la configuración.
