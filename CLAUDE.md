# CLAUDE.md

Context for Claude Code working on `alainpineda.com`. Read this fully before
editing anything. It is written to be sufficient on its own: you should not need
to ask the owner how the site works.

---

## 1. Who this is for

**Owner:** Alain Pineda. PhD in Economics (Stanford, 2024, Knight-Hennessy
Scholar). Research Economist in the Real Sector Research Division at Banco de
México. Lecturer at ITAM in the Master in Applied Economics.

**Research area:** labor markets in developing countries. Informal employment,
social insurance expansion, labor market trajectories, equality of opportunity.
Empirical microeconomics using Mexican administrative and survey microdata
(ENOE, IMSS records, employer-employee matched data).

**Tooling reality, important:** he comes from **Stata** and is migrating to **R**
on his personal machine. Write R, not Python: the deciding factor is that ENOE is
a complex survey and `survey`/`srvyr` handle strata and expansion factors
properly, which Python still does not. Use `haven` to read legacy `.dta` files,
`fixest` for panel fixed effects (it maps cleanly onto `reghdfe`), `srvyr` for
survey means, `modelsummary` for tables, `ggplot2` for static figures. He reads
code comfortably but is not a web developer. Never propose a solution that
requires a JavaScript toolchain, `npm`, or ongoing build dependencies.

**Audiences the site serves, in priority order:**

1. Policy staff at Banco de México, Hacienda, IMSS, STPS, state labor ministries,
   and multilaterals (IDB, World Bank). They will not open a PDF. They read the
   one-line finding and maybe the "why it matters" paragraph.
2. Academic economists — referees, seminar hosts, coauthors, hiring committees.
   They want papers, slides, replication packages, and current status.
3. Mexican general and student audiences, mostly through the Spanish site.
4. Journalists looking for a quotable, accurate summary.

The previous site was a Hugo Academic (Source Themes 4.8.0) template and read as
a pure job-market page. The redesign exists to add a real policy presence and to
get off an unmaintained theme.

---

## 2. Stack and hard constraints

- **Quarto** static site. Plain Markdown, no computational engine in the render
  path.
- **R runs in `scripts/`, never inside a `.qmd`.** Scripts are executed by hand
  and write CSVs into `data/` and SVGs into `images/`. Keeping R out of the render
  means the site compiles on any machine and CI needs nothing but Quarto. Do not
  move R code into page chunks casually.
- If inline R chunks ever become necessary, `execute: freeze: auto` is already set
  in `_quarto.yml`. In that case the `_freeze/` directory **must be committed to
  git**, or CI will fail because GitHub Actions has no R installed. Say this out
  loud to the owner before making the change.
- Interactivity is **Observable JS (`{ojs}`)** only, which ships inside Quarto and
  runs in the reader's browser. Data arrives as CSV produced by an R script.
- Styling is **two SCSS files**: `theme.scss` (tokens + every rule) and
  `theme-dark.scss` (dark tokens only, no rules). No Tailwind, no CSS framework
  beyond the Bootstrap that Quarto's `cosmo` and `darkly` themes provide.
- **Light and dark themes.** `_quarto.yml` declares
  `theme: {light: [cosmo, theme.scss], dark: [darkly, theme.scss, theme-dark.scss]}`
  plus `respect-user-color-scheme: true`, so a first-time visitor gets whatever
  their OS is set to and Quarto's navbar toggle overrides it from there. The dark
  list repeats `theme.scss` on purpose: the rules are compiled twice with
  different token values, so the two themes can never drift apart. This is why
  the palette and font tokens in `theme.scss` carry `!default` — Quarto puts the
  later file's defaults first, and without `!default` the dark values would be
  overwritten. Never remove those `!default` flags.
- **No color literals in the rules.** Anything below the token block must derive
  from `$ink`, `$paper`, `$rule`, `$teal`, `$ochre` (`rgba($teal, 0.06)`, not
  `rgba(11, 93, 99, 0.05)`), or it will be wrong in one of the two themes.
- Hosting: GitHub Actions renders and pushes to the `gh-pages` branch. Netlify
  serves that branch. Netlify is only used for the domain and CDN; **do not add a
  Netlify build command** and do not migrate hosting without being asked.

---

## 3. Repository map

```
_quarto.yml            Shared config. Project type, resources, format, theme.
                       Sets `profile: default: en`.
_quarto-en.yml         English profile: navbar, footer, output-dir _site,
                       render list (everything except es/).
_quarto-es.yml         Spanish profile: navbar, footer, output-dir _site-es,
                       render list (es/ only).
build.sh               Renders both profiles and merges Spanish into _site/es.
theme.scss             All design tokens and custom classes.

index.qmd              EN landing (Quarto `about: trestles`).
research.qmd           EN research page. Three folder-driven listings PLUS a
                       hand-written "Policy and other writing" subsection.
data.qmd               EN interactive figures (Observable). In the navbar.
teaching.qmd           EN teaching page. Hand-written, no listing.

research/
  working-papers/<slug>/index.qmd
  in-progress/<slug>/index.qmd
  published/<slug>/index.qmd

es/                    Full Spanish mirror: index, research, data, teaching,
                       and es/research/** with the same slugs.

scripts/               R scripts that produce everything in data/ and images/.
                       Run by hand: `Rscript scripts/01-....R`
data/                  CSVs produced by scripts/, consumed by OJS blocks.
files/                 PDFs: CV, papers, slides, briefs.
images/                Photo and static figures.
CNAME                  www.alainpineda.com. Harmless on Netlify, needed if the
                       site ever moves to GitHub Pages.
.github/workflows/publish.yml   CI.
```

---

## 4. Bilingual architecture — read carefully

This is the part most likely to be broken by a careless edit.

The site is rendered **twice**, using Quarto profiles, because the navbar and
footer must be in different languages and Quarto has no per-page navbar.

```
quarto render                  # profile "en" (default) -> _site/
quarto render --profile es     # profile "es"           -> _site-es/es/...
```

`build.sh` then copies `_site-es/es/` into `_site/es/` and merges `site_libs`.
Final published tree:

```
_site/            English site at https://www.alainpineda.com/
_site/es/         Spanish site at https://www.alainpineda.com/es/
```

### Invariants — do not break these

1. **`_site-es` is an intermediate build directory.** Never publish it, never
   commit it. It is in `.gitignore`.
2. **Every EN page has an ES counterpart at the same slug**, and vice versa. The
   slugs are identical across languages (`gender-earnings-gap-box` in both). Only
   the prose is translated. This is what makes the language switch predictable.
3. **The language switcher uses absolute paths** (`/` and `/es/`), not relative
   ones, because Quarto navbar hrefs would otherwise point at files outside the
   active profile's render list and error.
4. **Cross-language links inside page content also use absolute paths**
   (`/es/policy/gender-earnings-gap-box/`). Same reason.
5. **Relative depth differs between the trees.** From
   `research/working-papers/x/index.qmd` the project root is `../../../`. From
   `es/research/working-papers/x/index.qmd` it is `../../../../`. Getting this
   wrong is the single most common bug when copying a page between languages.
6. Both profiles share `theme.scss`. A style change applies to both languages.
7. **The Spanish profile sets `lang: es-MX`, not `lang: es`.** Quarto rewrites
   project metadata values that look like relative paths, and a directory named
   `es/` exists, so `lang: es` came out as `lang="../es"` on every Spanish page.
   `es-MX` matches no directory and renders correctly. Do not "simplify" it.

### If the two-profile build ever fails

The fallback is a single render with one navbar. It is worse but it works: merge
`_quarto-en.yml` back into `_quarto.yml`, delete the `profile:` key and
`_quarto-es.yml`, remove the `render:` restriction so `es/` is included, and run
plain `quarto render`. Tell the owner what you did and why, because the Spanish
navbar labels will revert to English.

---

## 5. Content model

### Research, three buckets, folder-driven

`research.qmd` and `es/research.qmd` contain **no hand-written list of papers**.
Three Quarto listings read three directories:

| Directory | Heading (EN / ES) | Meaning |
|---|---|---|
| `research/working-papers/` | Working papers / Documentos de trabajo | Circulating draft exists |
| `research/in-progress/` | Work in progress / En proceso | No public draft yet |
| `research/published/` | Other publications / Otras publicaciones | Peer-reviewed, published |

**Every English listing must exclude the Spanish mirror.** Quarto's `contents`
globs are not anchored to the page's directory, so `research/working-papers/*`
also matched `es/research/working-papers/*` and the English page listed every
paper twice, the Spanish copy first. Each listing in `research.qmd` therefore
reads:

```yaml
    contents:
      - "research/working-papers/*/index.qmd"
      - "!es/**"
```

`es/research.qmd` needs no exclusion: from inside `es/` the glob only matches the
Spanish tree.

### Policy: a subsection, not a section — deliberate

There is **no `policy.qmd` and no `policy/` directory**. Policy pieces live as a
hand-written markdown list at the bottom of `research.qmd` and `es/research.qmd`,
under "Policy and other writing" / "Política pública y otros textos". Format:

```markdown
- **Title.** Publisher, *Series*, date. [PDF](url)
```

One line per piece. **No summary, no `.finding`, no internal page.** This is a
deliberate choice by the owner, made because Banco de México Quarterly Report
boxes are institutional and unsigned, and a prominent standalone page would
overstate personal authorship. Do not "improve" these entries by expanding them,
and do not recreate a top-level Policy nav item. If a future piece genuinely
needs its own page, create `policy/<slug>/index.qmd`, add `"policy/"` back to the
render list in `_quarto-en.yml`, and link to it from this same list — but keep
the section where it is.

**To promote a paper, move the folder.** Working paper accepted at a journal:
`git mv research/working-papers/x research/published/x`, update `subtitle` to the
journal and year, do the same under `es/`. The listings re-sort automatically.

### Front matter schema for a research or policy page

```yaml
---
title: "Title as it should appear"
subtitle: "Status line: 'Working paper', 'R&R at AEJ: Applied',
           'The Oncologist, 2022', 'Banco de México · Quarterly Report ...'"
description: "One sentence. This is the only text shown in the listing.
              Make it say the result, not the topic."
date: 2026-08-20        # controls listing order, newest first
date-modified: last-modified
author: "Alain Pineda"  # omit on coauthored institutional pieces
categories: [Banxico, Gender]   # policy pages only; research listings hide them
---
```

`description` is not a teaser. Someone scanning the listing should learn the
finding from it. "México dio cobertura médica a seis millones de estudiantes... el
empleo formal subió" is right. "This paper studies social insurance" is wrong.

---

## 6. The custom classes in `theme.scss`

Three CSS classes carry the whole editorial structure. Use them; do not invent
new ones without a reason.

### `.eyebrow`

```markdown
::: {.eyebrow}
Working paper · Latest draft August 2026
:::
```

Mono, uppercase, letterspaced, muted. For **metadata only**: status, venue, date,
journal. Never for prose. One per page, at the top.

### `.finding` — the signature element

```markdown
::: {.finding}
Delinking health coverage from a formal contract did not push young workers
toward informality.
:::
```

Serif, larger than body, ochre rule on the left. **This is the most important
element on the site.** It states what was found and what it implies, in one or two
sentences, in plain language, before the abstract. It is what a director at IMSS
reads and remembers.

Rules for writing a `.finding`:

- State the result, not the question. "X did not happen" beats "I examine whether
  X happens."
- No hedging stack. One qualifier maximum.
- No jargon: no "extensive margin", no "identification", no "TWFE".
- Two lines maximum. If it needs three, it is not sharp enough yet.
- Every research and policy page gets exactly one. Never two.

### `.paper-links`

```markdown
::: {.paper-links}
- [Paper (PDF)](../../../files/x.pdf)
- [Slides](../../../files/x-slides.pdf)
- [Replication](https://github.com/...)
- [Spanish version](/es/research/working-papers/x/)
:::
```

Renders as a horizontal row of bordered pills. Order: paper, slides, replication,
related brief, other language. Omit rows that do not exist rather than linking to
a missing file.

### Listings use `.quarto-post`, not `.listing-item`

Quarto renders each listing entry as `div.quarto-post` inside a flex row that
reserves a column for a thumbnail. There are no thumbnails on this site, so
`theme.scss` collapses that row to a single column and hides `.thumbnail` and
`.metadata`. If a listing ever starts showing a wide empty gutter again, that
rule is what broke.

### Collapsible abstract

Raw HTML, styled by `details.abstract`:

```html
<details class="abstract">
<summary>Full abstract</summary>

Text of the abstract.

</details>
```

Summary text is "Full abstract" in EN, "Resumen completo" in ES. Blank lines
inside the `<details>` block are required for Markdown to render.

---

## 7. Editorial voice

The prose on this site should read like a well-edited central bank note, not like
a personal blog and not like marketing copy.

- Short declarative sentences. Active voice.
- No em-dash asides, no "not X but Y" constructions, no rhetorical questions as
  headings.
- Never oversell a result. If a decomposition is accounting, say it is
  accounting. If estimates are conditional correlations, say so. The owner works
  at a central bank and reputational precision matters more than punch.
- Structure for each research page: `.eyebrow`, `.finding`,
  "What the paper does", "Why it matters for policy", `.paper-links`, collapsed
  abstract.
- Spanish is **Mexican Spanish for an educated general audience**, not a literal
  translation. Use "empleo formal", "informalidad", "seguridad social",
  "trabajadoras del hogar", "brecha de ocupación". Keep institution names in
  Spanish (IMSS, ENOE, STPS, ITAM). Do not translate paper titles that circulate
  in English inside academia — give the Spanish title and let the English page
  carry the English one.
- Use "usted"-free, non-colloquial register. Address the reader as little as
  possible.

---

## 8. Institutional constraints (Banco de México)

- The footer carries a disclaimer in both languages stating that views are
  personal and do not necessarily reflect those of Banco de México. **Do not
  remove it** and do not weaken its wording.
- **Quarterly Report boxes ("recuadros") are institutional publications and are
  not individually signed.** This is why policy items are a one-line list rather
  than full pages. Never add an author line, a `.finding`, or a summary to a
  Banxico box entry, and never upgrade the attribution on your own. If the owner
  later confirms with his area how staff may attribute boxes, he will say so
  explicitly.
- Never host a copy of a Banxico PDF in `files/`. Always link to the canonical
  banxico.org.mx URL.
- Do not publish results, figures, or numbers from unpublished internal work.
  Everything on the site must already be public.

---

## 9. Recipes

### Add a new working paper

```bash
mkdir -p research/working-papers/my-new-paper
mkdir -p es/research/working-papers/my-new-paper
```

Copy `research/working-papers/social-insurance-without-a-job/index.qmd` as the
model. Fix the `../` depth (three levels from EN, four from ES). Write the
`.finding` first, then the rest. Add the cross-language links in both files.

### Add a policy item

Append one line to the "Policy and other writing" list in `research.qmd` and the
matching list in `es/research.qmd`. Title in bold, publisher and date in plain
text, one link out. Nothing else. Only list pieces that are already public, and
always link to the publisher's canonical URL rather than hosting a copy.

### Add an interactive chart

`data.qmd` and `es/data.qmd` are the charts page. The pattern is:

```r
library(tidyverse); library(srvyr)
tabla <- enoe |>
  as_survey_design(ids = upm, strata = est_d_tri, weights = fac_tri, nest = TRUE) |>
  group_by(ent, year) |>
  summarise(outcome = survey_mean(x, na.rm = TRUE))
write_csv(tabla, here::here("data", "my-series.csv"))
```

Put that in a new numbered file under `scripts/`, following
`scripts/01-informality-by-state.R` as the model. Then in the page:

then an `{ojs}` block with `FileAttachment("data/my-series.csv").csv({typed: true})`
and Observable Plot. `Plot`, `d3`, and `Inputs` are available without imports.
**Paths inside `FileAttachment` are relative to the `.qmd` file**, so the English
page uses `data/x.csv` and the Spanish page uses `../data/x.csv`. This is a
frequent source of a silently empty chart.

Default to **static** figures: `ggplot2` in the script, `ggsave()` an SVG into
`images/`, plain markdown on the page. Reach for an interactive chart only when
the reader gains something from choosing a state, a cohort, or a year.

Never publish an ENOE estimate computed as an unweighted mean. If a number on
this site comes from survey microdata, it must have gone through the survey
design.

### Change the visual identity

Two token blocks, no rules: `theme.scss` (light, with `!default`) and
`theme-dark.scss` (dark). Change those values only. The rules below the light
token block derive from them and are compiled once per theme.

A dark palette is not an inversion. Keep the same identity and raise the accents'
luminance so they hold contrast on the dark ground, and stop the text short of
pure white. Current dark values: `$paper #171513`, `$ink #e3ddd0`,
`$ink-soft #9a948b`, `$rule #332c26`, `$teal #63b0b0`, `$teal-deep #8dcdcb`,
`$ochre #be8d74`.

The palette and type now come from the owner's Claude Design export
(`design-system/colors_and_type.css`, gitignored, reference-only): light values
are the export's hex codes verbatim (`$ink`, `$paper`, `$rule`, `$teal`,
`$teal-deep` from its `--ink`, `--paper`, `--paper-3`, `--accent`, `--accent-2`;
`$ochre` from its `--clay`, the export's secondary accent). The export ships no
dark tokens, so the dark values above were calibrated from it by hand using the
method in the paragraph above — hue preserved, accent luminance raised, `$ink`
kept short of the export's own near-white `--paper`. If a newer export arrives,
extract its palette and type the same way and do not restructure the SCSS to
match the export's own class names.

---

## 10. Build, preview, deploy

```bash
quarto preview                    # English, live reload
quarto preview --profile es       # Spanish, live reload
./build.sh                        # both, merged into _site/
python3 -m http.server 8080 --directory _site   # check the merged result
```

CI (`.github/workflows/publish.yml`) runs `build.sh` on every push to `main` and
pushes `_site/` to the `gh-pages` branch. Netlify is configured to serve
`gh-pages` with an empty build command. DNS lives at Netlify and is not managed
from this repo.

**Never run `quarto publish`.** It re-renders with a single profile and would
publish an English-only site, silently dropping `/es/`.

---

## 11. Verification checklist before saying a change is done

- [ ] `./build.sh` completes without errors
- [ ] `_site/index.html` and `_site/es/index.html` both exist
- [ ] The ES navbar shows Spanish labels, the EN navbar English ones
- [ ] The language switcher round-trips: EN home → ES home → EN home
- [ ] Every new page appears in the right listing, in the right position
- [ ] The charts on `/data/` and `/es/data/` both actually render (an empty chart
      usually means a wrong `FileAttachment` path)
- [ ] No `../` path is off by one level (check ES pages especially)
- [ ] No link points to a PDF that does not exist in `files/`
- [ ] The footer disclaimer is present in both languages
- [ ] Both themes render: load a page with the OS in dark mode, then click the
      navbar toggle and confirm the light theme takes over
- [ ] No English listing shows a Spanish entry (the `!es/**` exclusion)
- [ ] `<html lang>` is `en` on English pages and `es-MX` on Spanish ones

---

## 12. Known gaps and open TODOs

**Highest priority — teaching materials.** The owner wants the Storytelling in
Economics course materials public and treats this as important, not
nice-to-have. `files/storytelling-syllabus.pdf` has landed and is linked from
`teaching.qmd` and `es/teaching.qmd`. **The slides are intentionally not
linked yet** — the owner has the deck but it needs a public version made first,
stripping any Banxico-internal figures or unpublished results, which he is
doing with Claude Code's help as a separate task. Do not add a `Slides` row to
either page's `.paper-links` until that adapted deck exists at
`files/storytelling-slides.pdf` (or, if he decides to go that route instead, a
Quarto `revealjs` deck at `teaching/storytelling/slides.qmd`).

- `images/profile.jpg` and `files/CV_Alain_Pineda.pdf` are the owner's real
  files now, not placeholders.
- The job market paper (`files/social-insurance-without-a-job.pdf`) has landed.
  **Its slides are deliberately not included** — the owner chose to omit them,
  not a pending task — so the `Slides` row was removed from the `.paper-links`
  block in both `research/working-papers/social-insurance-without-a-job/index.qmd`
  and its `es/` counterpart. Do not re-add it without being asked.
- All `REEMPLAZAR` placeholders are filled in: the Google Scholar URL is set in
  `_quarto-en.yml`, `_quarto-es.yml`, `index.qmd`, and `es/index.qmd`. The
  `Replication` row on the job market paper page was removed (both languages)
  rather than filled in — there is no replication package. `data.qmd` and
  `es/data.qmd` link to `github.com/alainpin/alainpineda` as the source of the
  CSVs behind the charts.
- **That repo is currently private.** The owner has said he'll make it public
  at launch. Until then, the "site's repository" link on `/data/` and
  `/es/data/` 404s for a visitor. Confirm the repo is public as part of the
  pre-launch checklist; don't do it unprompted since it's a one-way visibility
  change on a shared GitHub resource.
- The policy brief PDF is linked but not yet in `files/`.
- The `.finding` lines for `domestic-workers` and `nafta-to-usmca` are drafts
  written from project descriptions, not from results. The owner must confirm or
  rewrite them.
- `data.qmd` uses **synthetic placeholder data**, generated by the placeholder
  block in `scripts/01-informality-by-state.R` and labeled in a callout. Replace
  with real series before launch and delete that block.
- The interactive chart pulls Observable Plot and d3 from **cdn.jsdelivr.net at
  page load**. A reader on a network that blocks that CDN sees an OJS runtime
  error instead of the figure. Since policy staff are the first audience, prefer
  a static `ggplot2` SVG for any figure that must be seen, and keep Observable
  for figures where choosing a state or a year actually helps.
- R is not yet installed on the owner's personal machine as of this writing. The
  suggested setup is R plus Positron or RStudio, and
  `install.packages(c("tidyverse","haven","srvyr","fixest","modelsummary","here"))`.
- No RSS feed, no Google Analytics, no Plausible. Add only if asked.
- The site was first built end to end with Quarto 1.7.32 on 2026-08-28:
  `./build.sh` completes clean, with no warnings, and produces `_site/` and
  `_site/es/`. That run is what surfaced the `lang`, duplicate-listing, and
  listing-gutter bugs, all fixed. It has still never been rendered on the owner's
  own machine.
