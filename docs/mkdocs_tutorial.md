# MkDocs Tutorial for VPN Proxy Agent

This guide adapts the official *Getting Started with MkDocs* walkthrough to the VPN Proxy Agent repository so that every contributor can preview and publish documentation consistently.

## Prerequisites

1. **Check your Python runtime**
   ```bash
   python --version
   ```
   MkDocs requires Python 3.8+.
2. **Verify `pip` availability**
   ```bash
   pip --version
   ```
   Upgrade if necessary:
   ```bash
   pip install --upgrade pip
   ```

### Installing Python (if needed)
- Use your platform package manager or download an installer from [python.org](https://www.python.org/downloads/).
- On Windows, ensure the *Add Python to PATH* option is enabled during installation.

### Installing `pip` manually
If `pip` is missing, download `get-pip.py` and run:
```bash
python get-pip.py
```

## Installing MkDocs

Install MkDocs globally or within a virtual environment:
```bash
pip install mkdocs
```
Confirm the installation:
```bash
mkdocs --version
```
Optionally generate man pages with [click-man](https://github.com/click-contrib/click-man):
```bash
pip install click-man
click-man --target path/to/man/pages mkdocs
```
Windows users can prefix commands with `python -m` if shell shims are unavailable:
```powershell
python -m pip install mkdocs
python -m mkdocs --version
```
For a persistent fix, add the Python `Scripts` directory to your `PATH` (run `win_add2path.py` under `Tools/Scripts` in the Python installation directory).

## Working with This Repository

The project already contains a MkDocs site:

- Configuration lives in `docs/mkdocs.yml`.
- Source content resides in the `docs/` directory (custom pages plus this tutorial).
- Static builds output to `site/` (ignored by `.gitignore`).

If you need to bootstrap a new documentation site elsewhere, run:
```bash
mkdocs new my-project
cd my-project
```

### Live Preview
From the repository root (using the configuration in `docs/mkdocs.yml`), start the dev server:
```bash
mkdocs serve -f docs/mkdocs.yml
```
Expected output:
```
INFO    -  Building documentation...
INFO    -  Cleaning site directory
INFO    -  Documentation built in 0.22 seconds
INFO    -  [15:50:43] Watching paths for changes: 'docs', 'docs/mkdocs.yml'
INFO    -  [15:50:43] Serving on http://127.0.0.1:8000/
```
Visit [http://127.0.0.1:8000/](http://127.0.0.1:8000/) to view the site. The server auto-reloads whenever you edit content or configuration.

### Editing Content
- Update `docs/index.md` to change the landing page heading (try switching it to `MkLorum` while testing the tutorial).
- Modify `docs/mkdocs.yml` and set the site name:
  ```yaml
  site_name: MkLorum
  ```
  The browser reloads automatically when the config changes.

### Navigation
Add additional pages under `docs/` (for example, pull sample markdown):
```bash
curl 'https://jaspervdj.be/lorem-markdownum/markdown.txt' > docs/about.md
```
Declare navigation order in `docs/mkdocs.yml`:
```yaml
site_name: MkLorum
nav:
  - Home: index.md
  - About: about.md
```
The default theme provides *Home*, *About*, and a search box without extra configuration.

### Theming
Switch to the Read the Docs theme (already used in this repository) by adding:
```yaml
theme: readthedocs
```
MkDocs immediately updates the layout after you save the file.

### Favicons
Place `favicon.ico` inside `docs/img/`. MkDocs automatically detects the icon and bundles it into the site build.

## Building the Site

Produce a production-ready static site:
```bash
mkdocs build
```
Inspect the generated artifacts in the `site/` directory:
```
ls site
about  fonts  index.html  license  search.html
css    img    js          mkdocs   sitemap.xml
```
Ensure `site/` remains ignored (already listed in `.gitignore`). If you replicate the tutorial in another project, append `site/` manually:
```bash
echo "site/" >> .gitignore
```

## Additional Commands

- `mkdocs --help` – list global options.
- `mkdocs build --help` – display build-specific flags.

## Deployment

MkDocs outputs static files that can be hosted on any static site provider (GitHub Pages, GitLab Pages, Netlify, etc.). Upload the contents of `site/` to your hosting platform following its deployment instructions.

## Getting Help

Consult the [MkDocs User Guide](https://www.mkdocs.org/user-guide/) for advanced features. For troubleshooting, search or open discussions on the [MkDocs GitHub repository](https://github.com/mkdocs/mkdocs).
