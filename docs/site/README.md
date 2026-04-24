# GitHub Pages Setup

This folder contains a minimal static site for App Store submission links.

## Files

- `index.html`: suggested Marketing URL landing page
- `support.html`: suggested Support URL page
- `privacy.html`: privacy summary page
- `styles.css`: shared styling

## Fastest GitHub Pages Publish Path

1. Push this repository to GitHub.
2. In the GitHub repository, open `Settings` -> `Pages`.
3. Under `Build and deployment`, choose:
   - `Source`: `Deploy from a branch`
   - `Branch`: your main branch
   - `Folder`: `/docs`
4. Move or copy these site files to the published docs root if needed so Pages serves:
   - `/docs/site/index.html`
   - `/docs/site/support.html`
   - `/docs/site/privacy.html`
   - `/docs/site/styles.css`

## Expected URL Pattern

- Marketing URL: `https://<github-username>.github.io/<repo-name>/site/`
- Support URL: `https://<github-username>.github.io/<repo-name>/site/support.html`

## Required Replacements Before Submission

- Replace `replace-this-with-your-support-email@example.com`
- Replace `<github-username>`
- Replace `<repo-name>`
