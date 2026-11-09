# CLAUDE.md

Context for Claude Code working on `alainpineda.com`: a bilingual (English and
Spanish) personal website built with [Quarto](https://quarto.org). Read it
before editing.

## This repository is public

This file and `README.md` ship with the repo. Everything committed must already
be public on the website. Do not add personal information that is not on the
site, absolute paths that contain an account name (use an environment variable),
credentials, or anything about unpublished or internal work. Before a commit,
re-read what you are about to commit against that rule.

## Stack

- **Quarto static site.** Plain Markdown. No computation in the render path.
- **R runs in `scripts/`, never inside a `.qmd`.** Scripts are run by hand and
  write CSVs to `data/` and SVGs to `images/`. CI has only Quarto installed.
- **Interactivity is Observable JS (`{ojs}`) only.** It runs in the reader's
  browser and reads CSVs from `data/`.
- **Styling is two SCSS files:** `theme.scss` (tokens and every rule) and
  `theme-dark.scss` (dark tokens only). Rules below the token block use the
  tokens, never color literals. Keep the `!default` flags on the tokens.
- **Hosting:** GitHub Actions renders the site and pushes `gh-pages`; Netlify
  serves that branch. Do not add a Netlify build command.

## Layout

```
_quarto.yml        Shared config
_quarto-en.yml     English profile (navbar, footer, output _site/)
_quarto-es.yml     Spanish profile (navbar, footer, output _site-es/)
build.sh           Renders both profiles and merges Spanish into _site/es
theme.scss, theme-dark.scss
*.qmd              English pages
es/                Spanish mirror, same structure and slugs
research/, policy/, curiosities/   One folder per page: <section>/<slug>/index.qmd
scripts/           R scripts that produce data/ and images/
data/, images/, files/
```

## Two languages, two builds

Quarto has one navbar per build, so the site is rendered twice and merged:

```bash
quarto render                 # English  -> _site/
quarto render --profile es    # Spanish  -> _site-es/es/
./build.sh                    # both, merged into _site/
```

Invariants:

1. `_site-es/` is an intermediate directory. Never commit or publish it.
2. Every English page has a Spanish counterpart with the same slug. If a pair
   must differ, add it to `MAPA_SLUGS_ESPECIALES` in `js/lang-toggle.html`, or
   the language switcher will 404 on that page.
3. The switcher and cross-language links use absolute paths (`/` and `/es/`).
4. Relative depth differs between the trees: from `research/x/y/index.qmd` the
   root is `../../../`, and from the same page under `es/` it is `../../../../`.
   This is the most common error when copying a page between languages.
5. The Spanish profile sets `lang: es-MX`, not `es`. Do not change it.
6. `resources:` globs in `_quarto.yml` keep their leading `/`.
7. `netlify.toml` must stay listed in `resources:`, because Netlify reads it
   from `gh-pages`. To rename a published slug, add `aliases:` on the page and a
   `301` with `force = true` in `netlify.toml`. Verify redirects against the live
   site with `curl -I`, never against a local build.
8. Never run `quarto publish`. It builds one profile and drops `/es/`.

## Content

- Research and policy pages are folder-driven: front matter (`title`,
  `subtitle`, `description`, `date`) controls the listing. Add the page in both
  languages.
- Custom classes live in `theme.scss`: `.eyebrow` (status line), `.finding`
  (one or two plain-language lines with the result), `.paper-links`,
  `.chart-figure` (static figures with light and dark variants), `.data-panel`
  (container for interactive charts, which keeps them from widening the page).
- Spanish is Mexican Spanish for a general educated audience, not a literal
  translation. Keep institution names in Spanish.
- Prose: short declarative sentences, active voice, no overstated results.
- Keep the footer disclaimer in both languages.
- Link to the canonical URL of third-party documents instead of hosting copies.

## Data and charts

The flow is: R script in `scripts/`, CSV in `data/`, chart in a `.qmd`.

- Scripts publish an explicit allowlist of indicators and cuts. Adding one to
  the public data is a deliberate edit to that allowlist.
- Never publish an estimate from survey microdata as an unweighted mean.
- Paths differ by language: `data/x.csv` on an English page and `../data/x.csv`
  on a Spanish one. A wrong path gives an empty chart without an error.

## Build and deploy

```bash
quarto preview                 # English, live reload
quarto preview --profile es    # Spanish
./build.sh                     # both, merged
python3 -m http.server 8080 --directory _site
```

Every push to `main` runs `.github/workflows/publish.yml`, which runs
`build.sh` and pushes `_site/` to `gh-pages`.

## Before saying a change is done

Rendering without errors is not enough. Check in a real browser:

- Both `_site/index.html` and `_site/es/index.html` exist, with the right navbar
  language in each.
- The language switcher round-trips from every page you touched, not only from
  home, and lands on the real counterpart.
- Both language versions of each touched page read correctly end to end,
  including text built in `{ojs}` cells.
- Each touched page fits a phone width in both languages, with no horizontal
  overflow.
- Both themes render.
- Charts render (an empty chart usually means a wrong `FileAttachment` path),
  and no `../` path is off by one level.
- The footer disclaimer is present in both languages.

Observable's runtime only advances while the browser pane is painting. In a
hidden pane a page shows no resolved variables and no charts. Take a screenshot
first to force a paint.

## Local notes

Private working notes are not in this repository. If present, they load here:

@~/.claude/alainpineda-site-notes.md
