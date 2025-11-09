# ADR 0003: Automatización local para la documentación MkDocs

## Estado
Aceptado

## Contexto
La documentación del proyecto utiliza MkDocs con la plantilla Material. Una iteración previa introdujo un flujo de GitHub Actions para construir y publicar la documentación automáticamente. Sin embargo, el equipo estableció como requisito explícito evitar la dependencia de GitHub Actions o de cualquier plataforma CI/CD externa para este proceso.

## Decisión
Se elimina el workflow de GitHub Actions responsable de la construcción y despliegue de MkDocs. En su lugar, se incorpora el script `scripts/build_docs.sh`, que construye el sitio estático de MkDocs de forma local reutilizando las utilidades de logging y validación existentes. El script verifica la presencia de MkDocs, valida la existencia del archivo de configuración y ejecuta `mkdocs build --config-file docs/mkdocs.yml`.

## Consecuencias
- El equipo puede construir la documentación localmente de manera consistente sin depender de GitHub Actions.
- Los desarrolladores conservan el control total del proceso, pudiendo integrarlo en pipelines personalizados o ejecutarlo manualmente.
- Las pruebas automatizadas se actualizan para garantizar la ausencia del workflow de GitHub Actions y la presencia del script local, previniendo regresiones futuras.
