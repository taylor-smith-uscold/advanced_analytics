# Advanced Analytics — Course Reader

A single-file, fully self-contained course reader. All CSS, JavaScript (marked + KaTeX),
web fonts, and course content are inlined into `index.html` — there are no external
requests, so it works offline and needs no build step.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The entire site. |
| `.nojekyll` | Tells GitHub Pages to serve files as-is instead of running Jekyll. **Required** — see below. |
| `README.md` | This file. Not served as a page; safe to keep or delete. |

### Why `.nojekyll` matters here

GitHub Pages runs every push through Jekyll by default, and Jekyll treats `{{ ... }}` as
Liquid template syntax. The bundled KaTeX source contains several literal `{{` sequences
inside its LaTeX macro definitions. Without `.nojekyll`, the build will either fail or
silently mangle those macros, breaking math rendering. The empty `.nojekyll` file at the
repository root disables Jekyll entirely.

## Publishing

### Option A — command line

```bash
cd path/to/this/folder
git init -b main
git add -A                      # -A so the dotfile .nojekyll is included
git commit -m "Publish course reader"
git remote add origin https://github.com/USERNAME/REPO.git
git push -u origin main
```

Then in the repository on GitHub: **Settings → Pages → Build and deployment**, set
*Source* to **Deploy from a branch**, *Branch* to **main** and folder to **/ (root)**, and
save. The first deploy takes a minute or two.

### Option B — web upload

Create a new repository, choose **uploading an existing file**, and drag in `index.html`
and `README.md`. The browser uploader will not accept a dotfile, so add `.nojekyll`
separately: **Add file → Create new file**, name it `.nojekyll`, leave the body empty, and
commit. Then configure Settings → Pages as above.

## Your URL

- Normal repository: `https://USERNAME.github.io/REPO/`
- Repository named exactly `USERNAME.github.io`: `https://USERNAME.github.io/`

Because everything is inlined and no links are absolute, the page works at either address,
in a subdirectory, or opened straight from disk — no path changes needed.

## Notes

- **Public vs. private.** On a free plan, Pages only publishes from public repositories.
  Private-repository Pages requires a paid plan.
- **Saved state.** Theme and register preferences are stored in `localStorage` under the
  `aa:` prefix. This is scoped per origin, so every project site under
  `USERNAME.github.io` shares one store — a concern only if you publish another app that
  writes the same keys.
- **Updating.** Commit a new `index.html` and push; the site rebuilds automatically. Do a
  hard refresh (Cmd/Ctrl+Shift+R) if you still see the old version — Pages sets a short
  cache on HTML, and browsers hold onto a 1.2 MB document eagerly.
- **Custom domain.** Add a file named `CNAME` at the root containing only your domain
  (e.g. `reader.example.com`), then point a CNAME DNS record at `USERNAME.github.io`.
