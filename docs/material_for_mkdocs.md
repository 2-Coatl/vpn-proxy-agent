# Material for MkDocs: Guía Completa

Este tutorial paso a paso explica cómo crear, personalizar y publicar un portal de documentación usando [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). La guía se basa en el flujo de trabajo descrito en el video "Material for MkDocs" e incluye todas las tareas demostradas para que puedas replicarlas directamente en este repositorio o en un proyecto nuevo.

## Contenido

1. [Material for MkDocs vs. MkDocs](#material-for-mkdocs-vs-mkdocs)
2. [Requisitos previos](#requisitos-previos)
3. [Instalación inicial](#instalación-inicial)
4. [Validación del esquema de configuración](#validación-del-esquema-de-configuración)
5. [Personalización del tema](#personalización-del-tema)
6. [Fuentes, emojis, iconos y logotipos](#fuentes-emojis-iconos-y-logotipos)
7. [Bloques de código avanzados](#bloques-de-código-avanzados)
8. [Pestañas de contenido](#pestañas-de-contenido)
9. [Admoniciones (callouts)](#admoniciones-callouts)
10. [Diagramas con Mermaid](#diagramas-con-mermaid)
11. [Pie de página y enlaces sociales](#pie-de-página-y-enlaces-sociales)
12. [Publicación con GitHub Pages](#publicación-con-github-pages)

## Material for MkDocs vs. MkDocs

- **MkDocs** es un generador de sitios estáticos orientado a documentación. Proporciona la estructura base del sitio.
- **Material for MkDocs** es un tema avanzado construido sobre MkDocs. Aporta diseño responsive inspirado en Material Design y una colección de extensiones, como búsqueda avanzada, tarjetas sociales, integración con blogs y componentes interactivos.

## Requisitos previos

1. **Python 3.10 o superior** (el video usa 3.12). Comprueba la versión:
   ```bash
   python3 --version
   ```
   - En macOS/Linux, `which python3` indica la ruta.
   - En Windows, usa `where python`.
2. **pip** (incluido a partir de Python 3.4). Verifica su versión:
   ```bash
   pip --version
   ```
3. **Editor de texto** (Visual Studio Code en el video).
4. **Cuenta de GitHub** y Git configurado en la línea de comandos.

> 💡 Se recomienda crear y activar un entorno virtual antes de instalar dependencias.

```bash
python3 -m venv .venv
source .venv/bin/activate   # macOS/Linux
.venv\Scripts\activate     # Windows PowerShell
```

## Instalación inicial

1. **Instala Material for MkDocs**:
   ```bash
   pip install mkdocs-material
   ```
2. **Crea un nuevo sitio** (opcional si ya tienes uno):
   ```bash
   mkdocs new .
   ```
3. **Configura el tema base** en `mkdocs.yml`:
   ```yaml
   site_name: Mi portal con Material
   theme:
     name: material
   ```
4. **Arranca el servidor de desarrollo**:
   ```bash
   mkdocs serve
   ```
   El sitio estará disponible en [http://127.0.0.1:8000/](http://127.0.0.1:8000/).

## Validación del esquema de configuración

1. **Instala la extensión YAML de Red Hat** en Visual Studio Code.
2. **Agrega el esquema de MkDocs Material** a la configuración de usuario (`settings.json`):
   ```json
   "yaml.schemas": {
     "https://squidfunk.github.io/mkdocs-material/schema.json": [
       "mkdocs.yml"
     ]
   }
   ```
3. Al editar `mkdocs.yml`, VS Code validará claves y valores, mostrando errores en tiempo real.

## Personalización del tema

### Esquema de color dinámico

```yaml
palette:
  - scheme: default
    primary: indigo
    accent: deep orange
    toggle:
      icon: material/weather-night
      name: Cambiar a modo oscuro
  - scheme: slate
    primary: green
    accent: deep purple
    toggle:
      icon: material/weather-sunny
      name: Cambiar a modo claro
```

- Añade el bloque `palette` al archivo `mkdocs.yml`.
- El interruptor de modo claro/oscuro aparecerá automáticamente en la barra superior.

### Fuentes personalizadas

Material for MkDocs integra Google Fonts por defecto:

```yaml
font:
  text: "Merriweather Sans"
  code: "Red Hat Mono"
```

## Fuentes, emojis, iconos y logotipos

### Emojis

1. Habilita las extensiones Markdown en `mkdocs.yml`:
   ```yaml
   markdown_extensions:
     - attr_list
     - md_in_html
     - pymdownx.emoji:
         emoji_index: !!python/name:materialx.emoji.twemoji
         emoji_generator: !!python/name:materialx.emoji.to_svg
   ```
2. Usa emojis directamente en Markdown: `I like to drink :beer: after playing :soccer:`

### Iconos y logotipos

- Para usar un icono como logotipo:
  ```yaml
  theme:
    logo: fontawesome/solid/w
  ```
- Para usar un archivo de imagen:
  1. Copia tu logotipo a `docs/assets/logo.png`.
  2. Configura la ruta:
     ```yaml
     theme:
       logo: assets/logo.png
     ```
- Cambia el favicon añadiendo el archivo a `docs/assets/favicon.ico` y actualizando:
  ```yaml
  theme:
    favicon: assets/favicon.ico
  ```

## Bloques de código avanzados

Material amplía la sintaxis estándar de Markdown.

1. **Activa extensiones adicionales**:
   ```yaml
   markdown_extensions:
     - pymdownx.superfences
     - pymdownx.highlight
     - pymdownx.inlinehilite
     - pymdownx.snippets
     - pymdownx.tabbed
   ```
2. **Especifica el lenguaje** con Pigments (por ejemplo, `py`, `js`, `yaml`).
3. **Ejemplo completo**:
   ```markdown
   ```py title="add_numbers.py" linenums="1"
   def add_numbers(a, b):
       return a + b
   ```
   ```
4. **Resalta líneas concretas**:
   ```markdown
   ```js title="app.js" linenums="1" hl_lines="2-4"
   const a = 2;
   const b = 3;
   const result = a + b;
   console.log(result);
   ```
   ```

## Pestañas de contenido

Las pestañas permiten mostrar alternativas (por ejemplo, varios lenguajes) sin saturar la página.

```markdown
=== "Texto"

    Documentación en texto plano.

=== "Lista"

    - Elemento A
    - Elemento B

=== "Código Python"

    ```py
    print("Hola, Material")
    ```
```

Asegúrate de mantener habilitada la extensión `pymdownx.tabbed`.

## Admoniciones (callouts)

1. Activa `admonition` y `pymdownx.details` en `markdown_extensions`.
2. Usa el siguiente formato en tus páginas Markdown:
   ```markdown
   !!! note "Nota"
       Este es un recordatorio visible.

   ??? info "Más información"
       Contenido colapsable para detalles adicionales.
   ```
3. Tipos disponibles: `note`, `info`, `abstract`, `tip`, `success`, `warning`, `danger`, entre otros.

## Diagramas con Mermaid

1. Extiende la configuración de `pymdownx.superfences` para registrar Mermaid:
   ```yaml
   markdown_extensions:
     - pymdownx.superfences:
         custom_fences:
           - name: mermaid
             class: mermaid
             format: !!python/name:pymdownx.superfences.fence_code_format
   ```
2. Inserta diagramas directamente en Markdown:
   ```markdown
   ```mermaid
   flowchart TD
       Start --> Stop
   ```
   ```
3. Mermaid soporta diagramas de flujo, secuencia, clases, estados y más.

## Pie de página y enlaces sociales

1. Activa el pie de página global:
   ```yaml
   theme:
     features:
       - navigation.footer
   ```
2. Añade enlaces sociales:
   ```yaml
   extra:
     social:
       - icon: fontawesome/brands/youtube
         link: https://youtube.com/tu-canal
         name: YouTube
       - icon: fontawesome/brands/linkedin
         link: https://www.linkedin.com/in/tu-perfil/
         name: LinkedIn
   ```
3. Define un mensaje de copyright:
   ```yaml
   extra:
     copyright: "© 2024 Tu Nombre"
   ```

## Publicación con GitHub Pages

1. **Crea el flujo de trabajo** en `.github/workflows/ci.yml`:
   ```yaml
   name: Deploy MkDocs site

   on:
     push:
       branches:
         - main

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-python@v5
           with:
             python-version: "3.x"
         - run: pip install mkdocs-material
         - run: mkdocs build --config-file docs/mkdocs.yml
         - uses: peaceiris/actions-gh-pages@v3
           with:
             github_token: ${{ secrets.GITHUB_TOKEN }}
             publish_dir: ./site
   ```
2. **Inicializa el repositorio Git** y sube el código a GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin git@github.com:usuario/proyecto.git
   git push -u origin main
   ```
3. **Activa GitHub Pages** en la pestaña *Settings → Pages*, seleccionando la rama `gh-pages` generada por el flujo de trabajo.
4. GitHub Actions desplegará automáticamente cada cambio enviado a `main`.

---

Con estas tareas completas tendrás un portal de documentación robusto, personalizable y listo para producción usando Material for MkDocs.
