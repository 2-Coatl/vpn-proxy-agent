# Documentation Tasks Checklist

This checklist summarizes every action required to keep the MkDocs site aligned with the "Writing your docs" guidance. Work through each task whenever you add or restructure documentation.

## 1. Prepare the Layout

- [ ] Keep the configuration file at `docs/mkdocs.yml`.
- [ ] Store all Markdown sources directly under `docs/` (subdirectories allowed for nested sections).
- [ ] Ensure every directory that should render to a navigable section contains an `index.md` or `README.md`.

## 2. Add or Update Content

- [ ] Write content in Markdown (`.md`, `.markdown`, `.mkdn`, `.mkd`, `.mdown`).
- [ ] Create additional pages with filenames that reflect their URL slug (e.g., `user-guide/getting-started.md`).
- [ ] Include supporting assets (images, media) alongside the Markdown file that references them.

## 3. Wire the Navigation

- [ ] Declare the site navigation in `docs/mkdocs.yml` using paths relative to `docs/`.
- [ ] Group related pages under section headers to mirror the desired menu structure.
- [ ] Confirm every published page appears in the `nav` list or is intentionally hidden.

## 4. Validate Content Links

- [ ] Use relative Markdown links for internal references (e.g., `[About](about.md)`).
- [ ] Link to headings with anchor syntax such as `[License](about.md#license)`.
- [ ] Avoid absolute paths unless you intend to manage them manually.

## 5. Leverage Markdown Enhancements

- [ ] Enable required Markdown extensions (tables, fenced code blocks, `toc`) in `docs/mkdocs.yml` if the content depends on them.
- [ ] Add metadata blocks (`--- ... ---`) when you need custom titles or template overrides.
- [ ] Surround tables and fenced code blocks with blank lines so MkDocs renders them correctly.

## 6. Build and Review

- [ ] Preview the site locally with `mkdocs serve -f docs/mkdocs.yml`.
- [ ] Run `mkdocs build -f docs/mkdocs.yml` to verify the static output.
- [ ] Inspect the generated `site/` directory or deployment preview to confirm URLs follow the intended hierarchy.

Keeping this checklist close ensures every documentation change honors the official MkDocs project layout recommendations.
