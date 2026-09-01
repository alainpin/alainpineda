# CLAUDE.md

Context for Claude Code working on `alainpineda.com`. Read this fully before
editing anything. It is written to be sufficient on its own: you should not need
to ask the owner how the site works.

---

## 0. This repository is public. Standing rule, effective 2026-08-31

**Everything committed here must be consistent with what is already published
on the website — this file and `README.md` included.** They are not private
notes. They ship with the repo and anyone can read them.

The test for any line is simple: *is this already on alainpineda.com?* If not,
it does not belong in the repo. That covers:

- **Personal information** not on the site. His Banco de México address
  (`alain.pineda@banxico.org.mx`) is published, so it is fine. His personal
  Gmail is not, so it must never appear — including inside a filesystem path,
  which is how it leaked into four `scripts/` files before being caught.
  Absolute paths that embed an account name go in an environment variable
  (`ENOE_DASHBOARD_DIR`), never in a committed file.
- **Detail about his role at Banco de México beyond what the site states.**
  His division and title are published and can be referenced. Internal
  process, pending consultations with his area, or the reasoning behind an
  institutional-neutrality decision are not.
- **Third parties.** Never name a private individual, and never describe
  material that involves one.
- **Editorial decisions framed as admissions.** Record the rule to follow, not
  the deliberation that produced it. "These slides were cut deliberately;
  carry the cut forward" is useful to a future session. Explaining *why* each
  one was cut turns an internal judgment call into a public statement.
- **Anything about unpublished or internal work**, which section 8 already
  prohibits on the site itself and which applies equally to these files.

**Do this proactively, not on request.** Before any commit, and whenever a
section of this file or the README grows, re-read what you are about to commit
against the test above. A useful sweep: search tracked files for email
addresses, absolute paths containing a username, and credentials, then confirm
each hit is something the site already publishes.

This rule exists because the README had accumulated a stale to-do list stating
that his teaching slides had contained internal Banxico figures, and this file
had accumulated several decisions of the kind described above. Both were
written as working notes, which is exactly how it happens.

---

## 1. Who this is for

**Owner:** Alain Pineda. PhD in Economics (Stanford, 2024, Knight-Hennessy
Scholar). Research Economist in the Real Sector Research Division at Banco de
México. Lecturer at ITAM in the Master in Applied Economics.

**Research area:** labor markets in developing countries. Informal employment,
social insurance expansion, labor market trajectories, equality of opportunity.
Empirical microeconomics using Mexican administrative and survey microdata
(ENOE, IMSS records, employer-employee matched data).

**Tooling, important:** write **R**, not Python. The deciding factor is that
ENOE is a complex survey and `survey`/`srvyr` handle strata and expansion
factors properly, which Python still does not. Use `haven` to read `.dta`
files, `fixest` for panel fixed effects (it maps cleanly onto `reghdfe`),
`srvyr` for survey means, `modelsummary` for tables, `ggplot2` for static
figures. Never propose a solution that requires a JavaScript toolchain, `npm`,
or ongoing build dependencies.

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
teaching.qmd           EN teaching page. Hand-written, no listing.

research/
  working-papers/<slug>/index.qmd
  in-progress/<slug>/index.qmd
  published/<slug>/index.qmd

data.qmd               EN interactive figures (Observable). In the navbar.
es/                    Full Spanish mirror: index, research, data, teaching,
                       and es/research/** with the same slugs.

scripts/               R scripts that produce everything in data/ and images/.
                       Run by hand: `Rscript scripts/01-....R`,
                       `Rscript scripts/02-labor-indicators.R`
data/                  CSVs produced by scripts/, consumed by OJS blocks.
files/                 PDFs: CV, papers, slides, briefs.
images/                Photo and static figures.
listing-templates/     Custom ejs template for the research.qmd listings
                       (the PDF-pill feature). See section 6.
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
   **The four Labor Market MX data pages are the one deliberate exception** —
   their Spanish slugs are real Spanish words (`data-participacion`, not
   `data-participation`; also `data-informalidad`, `data-desocupacion`,
   `data-actualizacion-trimestral`), which reads far better for the Spanish
   audience than an
   English word sitting under `/es/`. `js/lang-toggle.html`'s
   `MAPA_SLUGS_ESPECIALES` is what makes the ES/EN navbar switcher still work
   for these four — its default logic just prepends/strips `/es`, which 404s
   the moment a slug diverges. This broke silently on all four pages until
   2026-08-30 (caught only when the owner tried the switcher on the then-new
   Findings page, renamed to Quarterly Update on 2026-08-31). **Any future
   page whose EN and ES slugs differ needs a new entry in that map**, in
   either direction — don't introduce a diverging slug pair without adding
   one, and don't "fix" this by renaming the Spanish slug to match English;
   the translated slug is the point. When you *change* an existing slug,
   update its key in that map too — a stale key silently reverts the switcher
   on that page to its default prepend/strip logic, which 404s.

   **Renaming a published slug needs redirects in two places, on purpose.**
   Add an `aliases:` front-matter entry on the renamed page pointing at the
   old URL — Quarto renders a JS redirect stub there — *and* a `301` in
   `netlify.toml`. The 301 is the one that matters for search: it's a real
   server redirect, so Google passes the old URL's ranking to the new one,
   which a JavaScript stub does not do reliably. The stub is the safety net
   for the failure mode described just below. Add both, plus a variant of
   each 301 without the `.html`, since Netlify resolves pretty URLs to the
   file rather than through the redirect table.

   Each of those 301s **must** carry `force = true`. Without it Netlify
   serves the static file whenever one exists at that path — and one does,
   the alias stub — so the rule never fires. The 2026-08-31 Findings →
   Quarterly Update rename is the worked example, in both languages.

   **`netlify.toml` only works because it is listed in `_quarto.yml`'s
   `resources:`.** Netlify reads it from the root of what it publishes,
   which is `gh-pages` (i.e. `_site/`), not `main`. Sitting only at the repo
   root it never reached production: its `/index.es.html → /es/` redirect
   had been quietly 404ing since the day it was written, found on
   2026-08-31. If anyone drops it from `resources:`, every rule in that file
   stops applying with no error anywhere — so **verify a redirect against
   the live site (`curl -I`), never against a local build**, which cannot
   exercise Netlify's rules at all.
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

There is **no `policy.qmd`** — the section still lives inside `research.qmd`
and `es/research.qmd`, not as its own top-level nav item. (A `policy/`
*directory* does exist now, for the mini-pages described below; what's
deliberately absent is a standalone Policy page/nav entry.) Policy pieces are
a hand-written markdown list under "Policy and other writing" / "Política
pública y otros textos". Since 2026-08-30 this section sits **above** "Other
publications" / "Otras publicaciones" (it used to sit below it) — the owner
asked to move it up "to give them more prominence," so keep it as the
second-to-last section on the page, right after "Work in progress" and
before "Other publications," in both languages. Format:

```markdown
- **Title.** Publisher, *Series*, date. [PDF](url)
```

One line per piece. **No summary, no `.finding`, no internal page**, unless the
owner asks for one for that specific piece. The one-line default is a
deliberate choice by the owner, made because Banco de México Quarterly Report
boxes are institutional and unsigned, and a prominent standalone page would
overstate personal authorship. Do not "improve" a Banxico box entry by
expanding it, and do not recreate a top-level Policy nav item. Pieces the owner
personally authored (not an institutional box) can get their own page if he
asks: create `policy/<slug>/index.qmd` **and its `es/policy/<slug>/index.qmd`
mirror**, add `"policy/"` back to the render list in `_quarto-en.yml` (`es/`
already covers `es/policy/` since its render entry is just `"es/"`), reuse the
normal research-page structure (`.eyebrow`, `.finding`, body sections,
`.paper-links`, collapsed abstract — see the front matter schema and section 6
below), and link to it from this same list with a single line, same one-link-
out convention, just pointing at the new page instead of a PDF. This happened
first on 2026-08-30 for the owner's ITAM undergraduate thesis
(`policy/thesis-informality-duration/`): it started as a one-line entry, then
the owner asked for a bilingual mini-page "so it looks nicer," including a
chart. **Mind the relative-path depth**: `policy/<slug>/index.qmd` is 2
directories deep (`../../` reaches project root), `es/policy/<slug>/index.qmd`
is 3 (`../../../`) — getting this wrong silently drops the page's own figure
image (Quarto only copies images it can actually resolve, so a wrong depth
just produces a broken `<img>` with no build error) exactly the way a wrong
depth breaks images on any other page under `es/`, see the bilingual
invariants above. The thesis page's chart was generated with the R script
approach in "Add an interactive chart" below (ggplot2 + `svglite`, teal for
formal employment and ochre for informal, hand-copied token hex values since
these are static SVGs, not SCSS-derived), exported once per language since the
category labels are prose (`thesis-informality-duration-en.svg` /
`-es.svg`), not from a script committed under `scripts/` since the underlying
numbers are hand-transcribed from a table in the (non-machine-readable) thesis
PDF, not from a survey-microdata pipeline.

A second personally-authored piece got the same treatment the same day:
`policy/breastfeeding-workplace-policy/` (the IDB Gender and Diversity blog
post, "Lactancia es desarrollo"). No chart there — the source numbers are
country counts (`19 of 24 countries...`) simple enough to state inline, so
don't force a chart onto every policy mini-page; only build one when a
comparison genuinely needs it, as the thesis's duration gap did. This entry
also fixed a stale date in the one-line list version (it said "January
2023"; the post's own byline says "Ago 3, 2022") — worth double-checking
against the source whenever you touch an old one-line policy entry, since
these were hand-typed and can drift.

**The Banxico-box exception, confirmed 2026-08-30.** The owner explicitly
approved a *sober* version of this same treatment for an institutional,
unsigned Banxico Quarterly Report box
(`policy/gender-earnings-gap-box/` — the slug this file already used above
as the bilingual-invariants example, before the page existed). This does
NOT reopen the door to treating Banxico boxes like personally-authored
pieces in general — it is a one-time confirmed exception for this specific
box, done a specific way. If asked to do this for a *different* Banxico box,
re-confirm with the owner first; don't assume blanket permission. The sober
recipe, distinct from the personally-authored template above:
- **No `author:` field** — no attribution row renders.
- **No `.eyebrow` personal framing** — the eyebrow is pure institutional
  metadata (publication, box number, date), not a status line about the
  owner's own work.
- **No `.finding` block.** That device is an editorial claim ("here's what
  I found and why it matters") and isn't appropriate for unsigned
  institutional content even when factually accurate.
- **No "why it matters" / policy-implication section in the owner's own
  voice.** Restate only what the box itself already concludes, attributed
  to the box ("El Recuadro señala que..."), never as a first-person claim.
- **No collapsed "Full summary" `<details>` block** — the personally-authored
  template's abstract is a personal-voice device; skip it here to keep the
  page as compact and neutral as the one-line entry it replaced.
- **Never host the PDF locally** — the existing site-wide rule (section 8)
  still applies; `.paper-links` points only at the canonical banxico.org.mx
  URL, same as the one-line entry did.
- Numbers reported on the page must be numbers the box states explicitly
  (or a direct arithmetic restatement, like "47 cents for every peso" from a
  stated 53% gap) — never interpolated, estimated, or extended beyond what's
  printed in the box.

**Charts on a sober Banxico-box page are fine, if they clear the same bar as
the numbers above: exact published data, no Banxico branding.** Added
2026-08-30 to `gender-earnings-gap-box/`: two charts
(`gender-gap-decomposition-*`, `gender-gap-trends-*`, recreating the box's
Gráfica 3 and Gráfica 1), sourced from the box's own **linked data tables**
rather than eyeballing the PDF's rendered chart. Banxico Quarterly Report
PDFs embed a clickable-graphic convention (the box's own note says so:
"dando clic sobre [las gráficas]... se puede obtener la información") — each
graphic/table has a `/Annots` link annotation pointing to a
`banxico.org.mx/TablasWeb/...html` page with the exact underlying series.
Extract those with `pypdf`:
```python
import pypdf
r = pypdf.PdfReader("recuadro.pdf")
for i, page in enumerate(r.pages):
    for a in (page.get("/Annots") or []):
        obj = a.get_object()
        if obj.get("/Subtype") == "/Link" and obj.get("/A", {}).get("/URI"):
            print(i + 1, obj["/A"]["/URI"])
```
Then `WebFetch` the resulting URL to get the table itself. This is strictly
better than reading numbers off the rendered chart (which is often lossy —
Gráfica 1's line chart only labels its 2005/2025 endpoints, not the 20 years
between): it gave the exact full 2005–2025 series for both charts, sourced
straight from Banxico, with zero risk of misreading a pixel position as a
data point. These `TablasWeb` URLs are also now linked directly from the
page's `.paper-links` ("Datos: ..." / "Data: ...") per the owner's request —
a natural complement to the "Read the full box" link, and something to do
for any future sober-box page that has one of these embedded links. Do not
extract or host the box's own rendered PNG/chart image — that would be
Banxico's actual branded graphic, a different (and not yet confirmed) thing
from a from-scratch recreation using the site's own chart style.

A personally-authored page can get a chart too when the source data is a
genuine comparison (see the thesis and, added the same day, the breastfeeding
post's `breastfeeding-policy-coverage-*` — a stacked-bar count of
UNICEF-reviewed countries by policy coverage, built from country counts
already stated in the post's own text, not from any external data-table
link).

### `.chart-figure` — theme-aware charts, not `.site-figure`

The three charts above went through two more rounds of owner feedback the
same day, worth internalizing before building the next one:

1. **Distinguishable categorical colors.** The decomposition chart first
   colored its three components `$teal`/`$teal-deep`/`$ochre` — the two
   teals read as near-identical at a glance. Reach for `$ink` as a third,
   clearly-distinct categorical color whenever teal/ochre alone isn't
   enough (`$teal`/`$ink`/`$ochre` now).
2. **Actually theme-aware, not just a transparent PNG in a fixed card.**
   `.site-figure` (section 6 above) is for Stata/PDF-derived images that
   bake in their own colors and can never adapt — hence its fixed `#fbfbf9`
   light card, deliberately not `$paper`. The first fix here made the
   R-generated SVGs transparent (`plot.background`/`panel.background =
   element_blank()`, `ggsave(..., bg = "transparent")`) but still wrapped
   them in that same fixed-`#fbfbf9` `.site-figure` card — which the owner
   correctly called out as still showing a white box, because `#fbfbf9` is
   visually indistinguishable from white and doesn't match `$paper`
   (`#f6f1e7` light / `#171513` dark), so the "card" never disappeared and
   never adapted to dark mode.

   The real fix, since these charts genuinely *can* adapt (we author them,
   unlike a Stata export): a new class, `.chart-figure` (`theme.scss`), used
   instead of `.site-figure` for any from-scratch chart. It has no fixed
   color — `background: $paper; border: 1px solid $rule;` — so it
   disappears into the page in both themes. Each chart ships **two color
   variants**, light and dark, using this site's actual light/dark token
   values (`$teal`/`$ink`/`$ochre`/`$rule` for light;
   `#63b0b0`/`#e3ddd0`/`#be8d74`/`#332c26` for dark — the same values
   documented in section 9's "Change the visual identity"), and both
   `<img>`s are emitted on the page with `{.chart-img-light}` /
   `{.chart-img-dark}` pandoc attributes:
   ```markdown
   ::: {.chart-figure}
   ![](../../images/my-chart-en-light.svg){.chart-img-light}
   ![](../../images/my-chart-en-dark.svg){.chart-img-dark}

   Caption text.
   :::
   ```
   Which one is visible is pure CSS, not JS, and recompiles per theme bundle
   exactly like every other token in this file: `theme.scss` declares
   `$chart-light-display: block !default; $chart-dark-display: none
   !default;` and rules `.chart-img-light { display: $chart-light-display;
   }` / `.chart-img-dark { display: $chart-dark-display; }`;
   `theme-dark.scss` simply flips both values (no `!default`, same pattern
   as every other token there). This works because Quarto's dark-mode toggle
   swaps between two *entirely separate* compiled stylesheets (inspect a
   built page's `<head>`: `id="quarto-bootstrap"` appears twice, once
   `data-mode="light"` once `data-mode="dark"`, and the inactive one is
   disabled) rather than flipping a single runtime attribute — so a plain
   SCSS variable recompiled per bundle is sufficient; there's no need for a
   `[data-bs-theme="dark"]` selector trick.

   File naming convention: `<name>-<lang>-<light|dark>.svg`, one R function
   taking both `lang` and `mode` args and picking from a `palette <-
   list(light = list(...), dark = list(...))` table (see any of the three
   chart scripts' history for the pattern) — do this from the start rather
   than retrofitting it, since it doubles every chart's file count (2 langs
   × 2 modes = 4 files per chart).

**When to use which:** `.site-figure` for Stata/PDF-derived static images
that can't be regenerated (JMP maps, anything sourced from a screenshot or a
non-reproducible export) — fixed light card, intentional. `.chart-figure`
for anything built from scratch with R/ggplot2 in this repo — theme-aware,
two variants, no fixed card. Don't use `.site-figure` for a new from-scratch
chart going forward; it will visibly fail in dark mode the same way this one
did.

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
new ones without a reason. (A fourth, `.chart-note`, exists for technical
captions under the data-page charts — see section 13.)

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
- Never two on a page.
- **A page gets one only when it has a public result to state.** The device
  promises a finding, so a page with nothing to report cannot have one: the
  rule above forbids stating the question, and section 8 forbids publishing a
  result from work that is not public yet. Those two constraints leave no
  wording that satisfies both, which is exactly how the two `in-progress`
  pages ended up opening with "This project asks..." for months.
  Where there is no public result, open with a plain paragraph instead — the
  same two sentences, without the wrapper. `published/melanoma-utilization`
  and both `in-progress/` pages do this; `working-papers/social-insurance-
  without-a-job` has a real one, because its PDF is public.
  When a draft becomes public, that page earns a `.finding` and should get one.

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

### The auto-rendered "Published" row is suppressed on purpose

Every research/policy page with `date:` set gets an automatic "Published"
row from Quarto's own `title-metadata.html` partial — there's no metadata
flag to turn it off, and it duplicated the `.eyebrow` date. `theme.scss` hides
it structurally with `.quarto-title-meta > div:has(> .quarto-title-meta-contents
> p.date) { display: none; }`, keyed off the `p.date` marker so it doesn't
touch the Author row (`p.author`) on pages that have one. Don't try to fix
this by removing `date:` from front matter — that field still drives listing
sort order.

### The research listing's custom template — a real gotcha

`research.qmd` and `es/research.qmd` point their three listings at
`listing-templates/research-listing.ejs.md` (path is `../listing-templates/...`
from `es/`) instead of Quarto's built-in `type: default` renderer. It exists so
a paper can show a "PDF" pill directly on the listing card — set `pdf:
files/whatever.pdf` in that page's front matter (relative to the *listing*
page, not the item's own page: root-relative for the EN listing, `../` for the
ES one) and the pill appears automatically. Omit `pdf:` and no pill renders.
The pill reuses `.paper-links` — see the CSS note below.

Since 2026-08-30 the same template also supports an `explainer:` field, same
convention (path relative to the *listing* page), rendering a second pill next
to "PDF" — see `research/working-papers/social-insurance-without-a-job/index.qmd`
for the live example. The template has no `lang`/locale param in this custom
context, so the EN/ES label ("Explainer" vs "Explicador") is derived cheaply
from whether `item.path` starts with `/es/` — that variable is already present
on every item (it's what the title link uses), so this needed no new
frontmatter field. If a listing item ever needs a differently-worded pill
label per language for some *other* field, this path-sniffing trick is the
established pattern here; don't add a `lang:` param to `templateParams` for it
unless the path trick genuinely stops working.

**The trap, if you ever touch this template:** setting `template:` on a
listing makes Quarto treat `listing.type` as `"custom"` internally, no matter
what you put in `type:`. Custom-type templates get a *different* ejs parameter
shape than default/grid/table: there is no `listing` object at all, only
`items`, a flat `metadataAttrs(item)` function, and `templateParams`. Quarto's
own shipped templates (`/Applications/quarto/share/projects/website/listing/
listing-default.ejs.md` and `item-default.ejs.md`) reference `listing.fields`
and `listing.utilities.metadataAttrs(item)` — copy that pattern into a custom
template and it throws `ReferenceError: listing is not defined`, because that
API is only for non-custom types. Reference `items`/`metadataAttrs` directly
instead, as `research-listing.ejs.md` does.

Also: Quarto evaluates every listing template a second time, in a dependency-
scanning pass, with `items`/`metadataAttrs` unbound. Guard the whole template
body behind `typeof items !== 'undefined'` or that pass throws too.

If a fourth listing needs the same PDF-pill treatment, point it at the same
template file rather than writing a new one.

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
- Structure for each research page: `.eyebrow`, then `.finding` if the page has
  a public result to state (see section 6) or a plain opening paragraph if it
  does not, "What the paper does", "Why it matters for policy", `.paper-links`,
  collapsed abstract.
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
  Banxico box entry, and never upgrade the attribution on your own. If the
  attribution convention ever changes, the owner will say so explicitly.
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

`data.qmd` / `es/data.qmd` came back on 2026-08-29 with real ENOE series (three
headline indicators as small multiples, six more behind a select) once a
validated pipeline existed to back them — see `scripts/02-labor-indicators.R`
for the model of a script that publishes from an already-validated external
pipeline rather than recomputing from raw microdata. `informality-example.csv`
and `01-informality-by-state.R` are the earlier synthetic-data scaffold; they
stay unused until a real by-state cut is built the same way. Follow this
pattern for the next chart:

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

**HIGH PRIORITY, standing rule, effective 2026-08-30: every push to `main`
gets a minucious (thorough, not spot-check) verification pass, in a real
browser, before it's reported done — not just `./build.sh` succeeding.**
The owner asked for this explicitly after the ES/EN switcher 404ed on the
then-new Findings page, now Quarterly Update (and, it turned out, silently
on three other pages too —
see section 4's Labor Market MX slug exception). Three things are
mandatory on every push that touches a page, not just the page(s) changed:

1. **Language switcher, from the actual page(s) touched, not just from
   home.** Home always round-trips because its slug happens to match — that
   proved nothing about the pages that broke. Click ES/EN from each changed
   page and confirm it lands on the real counterpart (not a 404, not the
   homepage as a silent fallback). Any page whose EN/ES slugs diverge needs
   an entry in `js/lang-toggle.html`'s `MAPA_SLUGS_ESPECIALES` (see section
   4) — check that map is current whenever a page's slug changes or a new
   page is added.
2. **Translation completeness, both directions.** Open both language
   versions of every touched page and read them — not just render without
   erroring. Confirm no leftover English string on the ES page (or vice
   versa), no stale/copy-pasted figure that should have been translated,
   and that OJS-computed text (dynamic strings built in `{ojs}` cells, not
   just static Markdown) is actually localized, not just the surrounding
   prose.
3. **Mobile viewport**, on every touched page, in both languages. Resize
   the browser (or use the mobile emulation) to a phone width and confirm
   no horizontal overflow, no clipped table/chart, no navbar breakage. This
   was already standing guidance for layout changes (see
   `feedback_website_mobile_check` in memory) — this directive makes it
   apply to *any* pushed change, not only ones that look layout-related.

This is not optional polish — treat a push that skips these three checks as
incomplete, the same way an unrun `./build.sh` would be.

- [ ] `./build.sh` completes without errors
- [ ] `_site/index.html` and `_site/es/index.html` both exist
- [ ] The ES navbar shows Spanish labels, the EN navbar English ones
- [ ] The language switcher round-trips from **every page touched this
      change**, not only from home — EN page → ES page → EN page, landing on
      the true counterpart each time
- [ ] Every changed page's translation is read end-to-end in both languages,
      including any OJS-generated text, not just skimmed for render errors
- [ ] Every changed page is checked at a phone viewport width, in both
      languages
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

**Teaching materials — done.** The Storytelling in Economics course materials
are public: `files/storytelling-syllabus.pdf` and `files/storytelling-slides.zip`
are both linked from `teaching.qmd` and `es/teaching.qmd`.

The zip holds 12 per-class PDFs (`Clase 01.pdf`–`Clase 14.pdf`, skipping 07 and
12 — those sessions never had slides), compiled from the owner's Overleaf
source with MacTeX/`pdflatex` (two passes each, for correct bookmarks). Before
compiling, three things were deliberately cut from the LaTeX source across all
13 original decks, and should stay cut if this ever gets recompiled from a
newer Overleaf export: every `\date{}` was blanked, every "next class"
logistics frame was removed (assignment previews, presentation logistics,
sometimes a specific due date), and two things were cut for reasons beyond
just being logistics — Clase 1's grading-percentage frame, and Clase 2's
personal thank-you frame that linked the owner's own Spotify playlist and a
private Google Sheet. That cut still stands for the slide deck itself — don't
reintroduce it there. Separately, on 2026-08-30 the owner asked to embed that
same Spotify playlist (a different link surfaced from a different context: a
class assignment asking students for their favorite stories told in songs,
not the personal thank-you frame) directly on the public `teaching.qmd` /
`es/teaching.qmd` page, under the Storytelling in Economics section, as a raw
```{=html}<iframe>...``` block (Spotify's own embed code, `width="100%"`,
`height="352"`). This is a deliberate, current decision, not a reversal of
the slide-deck cut above — the two are different surfaces (the LaTeX deck vs.
the site page) and different framings (a personal aside vs. a described class
exercise). A few slides were also cut from individual decks at the owner's
request. Those cuts are deliberate and already reviewed: if a deck is ever
recompiled from a newer Overleaf export, carry them forward rather than
restoring what the current published set leaves out, and ask the owner before
changing what any deck includes. Clase 15 (grad-school-abroad advice,
off-topic for a storytelling course) is excluded from the set entirely, never
compiled and never zipped.

A Quarto `revealjs` conversion was prototyped on Clase 13 and rejected by the
owner ("needs a lot more work") in favor of PDFs — don't revisit that path
without being asked.

- `images/profile.jpg` and `files/CV_Alain_Pineda.pdf` are the owner's real
  files now, not placeholders.
- The job market paper (`files/social-insurance-without-a-job.pdf`) has landed.
  **An "Explainer" was added 2026-08-30**, reversing the earlier "deliberately
  not included" decision at the owner's explicit request; it was called
  "Slides" for about a day and renamed to "Explainer"/"Explicador" the same
  day at the owner's request, since "Slides" reads as a standard academic
  deck. Do not rename it back without being asked. It is two self-contained
  static HTML files (no build step, no JS toolchain — a single file with
  inline CSS/JS and base64-embedded images, under `files/`):
  `files/social-insurance-without-a-job-slides.html` (EN) and
  `files/social-insurance-without-a-job-slides-es.html` (ES, full translation,
  not just a language-switcher wrapper — the filenames keep the historical
  "-slides" name even though the visible label is now "Explainer"; don't
  rename the files themselves, every link below points at these exact paths).
  Both reuse this site's actual `theme.scss` tokens
  ($ink/$paper/$rule/$teal/$teal-deep/$ochre, Source Serif 4 / IBM Plex)
  hand-copied as CSS custom properties inside the HTML file, since a static
  file outside the Quarto render can't `@use` the SCSS directly — if the
  site's token values in `theme.scss` ever change, these two files need the
  same values pasted in by hand, they will not pick it up automatically. Both
  files start with `<!DOCTYPE html><meta charset="utf-8">` — added after the
  first version shipped without it and a bare `python3 -m http.server` (no
  charset in its Content-Type header) mis-rendered every curly quote, em dash,
  arrow, and accented character as mojibake. The production host does send
  `charset=UTF-8`, so this never affected real visitors, but keep the meta tag
  regardless; it's what makes the file correct on its own, not dependent on
  whatever serves it. The deck is a general-audience narrative walkthrough of
  the paper (13 full-viewport scroll-snap sections) that includes a didactic
  explainer of the Rambachan & Roth (2023) breakdown-value sensitivity check
  (the "How sure?" section, `#s-honestdid`), aimed at readers learning the
  method, not just this paper's result. That section had a real bug worth
  knowing about if you ever touch its hand-rolled SVG: the shaded confidence
  band is built from an `upperY(f)`/`lowerY(f)` pair that must stay monotonic
  and non-crossing for all `f` in [0,1], or the polygon self-intersects into a
  visible overlapping mess — the first version's two curves shared the same
  end-of-range value and crossed. `breakAt` (where the vertical marker line
  sits) is now solved algebraically from `lowerY(breakAt)=yZero` rather than
  hardcoded, so the two can never drift out of sync again. Keep any text label
  positioned near the chart's top-left title label
  ("robust confidence set for the effect" / "conjunto de confianza robusto
  para el efecto") well clear of it vertically — they collided once too.
  Linked from three places, each independently: (1) `.paper-links` on both
  language versions of `research/working-papers/social-insurance-without-a-job/index.qmd`,
  paper → explainer → replication order, plus one linking sentence above the
  pills (not a new heading — kept inside the existing page structure); (2) a
  sentence in the "Current work" / "En qué estoy" paragraph on `index.qmd` and
  `es/index.qmd`; (3) an "Explainer"/"Explicador" pill on the `research.qmd` /
  `es/research.qmd` listing card itself, next to the "PDF" pill — see the
  `explainer:` frontmatter field note in section 6 below. If asked to update
  the deck's content, the owner's Claude scratchpad history from the session
  that built it is gone by the next session — treat the two `files/*.html` as
  the only source of truth and hand-edit them directly (plain HTML/CSS/JS, no
  build step, no source template elsewhere).
- All `REEMPLAZAR` placeholders are filled in: the Google Scholar URL is set in
  `_quarto-en.yml`, `_quarto-es.yml`, `index.qmd`, and `es/index.qmd`. The
  `Replication` row on the job market paper page now points to a real Zenodo
  record (`https://zenodo.org/records/22168219`) in both languages — the
  earlier "no replication package" gap is closed.
- **The repo (`alainpin/alainpineda`) is currently private.** When the Data
  page comes back (see "Add an interactive chart" above), it will link to this
  repo as the source of its CSVs, and that link 404s for a visitor until the
  repo is public. The owner has said he'll make it public at launch. Confirm
  that as part of the pre-launch checklist; don't flip visibility unprompted
  since it's a one-way change on a shared GitHub resource.
- The policy brief PDF is linked but not yet in `files/`.
- **Resolved 2026-09-01.** The `.finding` blocks on `domestic-workers` and
  `nafta-to-usmca` stated the question rather than a result, which rule 1 in
  section 6 forbids. Rewriting them was not possible: neither draft is public,
  so section 8 blocks stating a result. Both pages now open with the same two
  sentences as a plain paragraph, with no `.finding` wrapper, following
  `published/melanoma-utilization`. Each earns a real `.finding` when its draft
  becomes public. Both then got a figure instead, as the page's visual anchor —
  see the rule below.
- `data.qmd`/`es/data.qmd` are live again (2026-08-29) with real ENOE national
  indicators, sourced via `scripts/02-labor-indicators.R` from a validated
  external R pipeline (not recomputed here). Still no by-state cut — that
  needs its own script and its own real series before the informality-by-state
  placeholder can be replaced.
- The interactive chart pulls Observable Plot and d3 from **cdn.jsdelivr.net at
  page load** (this was already true of the placeholder chart; the new one
  doesn't add a second CDN dependency — no database engine, plain CSV). A
  reader on a network that blocks that CDN sees an OJS runtime error instead
  of the figure. Since policy staff are the first audience, prefer a static
  `ggplot2` SVG for any figure that must be seen, and keep Observable for
  figures where choosing an indicator or a year actually helps.
- No RSS feed, no Google Analytics, no Plausible. Add only if asked.
- The site was first built end to end with Quarto 1.7.32 on 2026-08-28:
  `./build.sh` completes clean, with no warnings, and produces `_site/` and
  `_site/es/`. That run is what surfaced the `lang`, duplicate-listing, and
  listing-gutter bugs, all fixed. It has still never been rendered on the owner's
  own machine.

## 13. Labor Market MX pages — a ported mirror, not authored here

The "Labor Market MX" / "Mercado Laboral MX" navbar section
(`data.qmd`/`es/data.qmd` and everything under it: `data-participation.qmd`,
`data-informality.qmd`, `data-unemployment.qmd`,
`data-quarterly-update.qmd` (called `data-findings.qmd` until 2026-08-31),
and their `es/` counterparts) is a public mirror of a separate, private Quarto +
Observable dashboard project the owner maintains elsewhere. That project has
its own codebase, its own `CLAUDE.md`, and its own much longer history of
design review — this repo only receives the finished, "safe for a general
audience" version of each page, ported over once a page is done on the
private side. **Do not assume this repo's git history tells the whole story
for these pages** — commits touching them may originate from sessions
working in that other project, pushing to this repo's `main` as their
publish step. That's expected, not a conflict; see the standing
fetch-before-push discipline elsewhere in this file.

Design conventions already settled (through several rounds of the owner's
own review) and shipped in this repo's code — follow them for any further
work on these pages rather than re-deriving a different answer:

- **Maps/choropleths follow the theme, they don't get a fixed canvas.** Use
  `style: {background: "transparent", color: "var(--ink)"}` on the Plot
  config and `stroke: "var(--ink)"` on the geo mark, the same
  `--ink`/`--rule` custom properties `theme.scss` already exposes on `:root`
  for exactly this purpose (see section 6's OJS-tooltip note for the
  pattern). A fixed light canvas behind a dark-mode page reads as a bug even
  when every individual color is technically correct — don't reach for that
  as a fallback.
- **Bar charts keep each cut's natural category order** (chronological for
  age, increasing schooling for education level), never sorted by value —
  the x-axis is a real ordered scale, and sorting by value would
  misrepresent it as a ranking. A cut with no natural order (state/entidad)
  gets a map instead of a bar chart, not a value-sorted bar chart.
- **Multi-category time series plot every category together on one chart**
  (one line per category), except for a cut with too many categories to read
  that way (state/entidad), which stays one-at-a-time behind a selector.
- **Every per-cut view names its own latest quarter explicitly**
  (a "Latest quarter: YYYY-TQ" caption computed from the data actually shown,
  not assumed to match other cuts/indicators on the same page).
- **Quarterly Update / change tables color only the up/down arrow glyph, never the
  whole value**, and use pale tones, not saturated red/green — a strong
  color across the whole number reads as a normative "good/bad" judgment,
  which this site avoids everywhere (see `$up`/`$down` in `theme.scss`).

Known bugs already hit once on this class of page — worth knowing before you
reintroduce one of them:

1. **An Observable JS module can hang forever, with no console error, if a
   single object literal contains two `color-mix(...)` string values.**
   Define fixed color tokens instead of computing more than one
   `color-mix()` inline in the same `{ojs}` cell.
2. **Observable Plot's continuous-scale legend ships its own hardcoded
   white background** in a scoped `<style>` inside its own SVG, unreachable
   via `Plot.plot()`'s `style:{background:"transparent"}` option (the legend
   is a separate figure the main plot config never touches). This repo's own
   fix is already in `theme.scss`: `svg[class*="-ramp"] { background:
   transparent !important; }` — matched by attribute rather than the exact
   class, since Plot assigns it a content hash that changes across
   versions.
3. **A geo/topoJSON `id` used as a join key can silently drop marks with no
   error and no visibly-wrong shape** if the two sides' key format doesn't
   match exactly (e.g. zero-padded state codes on one side, unpadded on the
   other) — a JS object key access re-stringifies a numeric key without
   padding. This looks like "some regions are missing a border," not "some
   regions are missing," because the mark is dropped entirely rather than
   rendered wrong. If a future map join ever looks subtly incomplete, verify
   the actual rendered feature count (`svg.querySelectorAll('path').length`)
   against the expected count rather than eyeballing the map.

When porting a new page or section from the private dashboard, hold it to
this repo's own general-audience framing (section 1's audience list, section
7's editorial voice) rather than assuming the private version's framing
carries over unchanged.

### Validation now comes from INEGI's BIE, not the press bulletin (2026-08-31)

`data/validations.csv` used to be filled in by hand each quarter from INEGI's
quarterly press release. It is now generated by
`scripts/04-labor-validations.R` from the private project's own BIE check
(`R/validar_contra_bie.R` there), and covers the full history rather than only
the latest quarter.

**Why this mattered, concretely.** The bulletin only publishes the most recent
quarter, so checking against it compared this site's publication against its
own previous publication and could not detect drift from INEGI in any past
quarter. It also carried a wrong claim for months: the TCCO row reported a
0.30 pp gap (bulletin 38.0 against pipeline 37.7) that three pages attributed
to INEGI rebasing its minimum-wage threshold. INEGI's own BIE series reports
37.698. The pipeline was right and the bulletin figure was the outlier. That
claim appeared on `data.qmd`, `data-quarterly-update.qmd` and their Spanish
counterparts, and all six were corrected.

Two conventions came out of that fix, worth keeping:

- **Notes travel in the data as keys, not as prose in the `.qmd`.** The old
  note was hand-written into a `notas` object in both languages, so it
  outlived the condition it described. `04-labor-validations.R` now emits a
  `nota_clave` column (`sin_bie`, `excede`, or empty) and each page maps that
  key to its own localized string. A single prose column cannot work here
  anyway: the site is bilingual and one CSV can only hold one language.
- **Indicators with no BIE counterpart are published as unvalidated, not
  omitted.** Broader unemployment (TDAMPL) and labor underutilization
  (SUBUTIL) have no quarterly series in the BIE. They appear in the table with
  em-dashes and an explicit note. Dropping them would read as full coverage.
  The OJS table therefore has to null-guard every numeric cell —
  `v.diferencia_pp.toFixed(2)` throws on those rows.

`scripts/05-labor-seasonal.R` publishes `data/labor-seasonal.csv`, INEGI's own
seasonally adjusted and trend-cycle series for the six indicators that have
them. `data.qmd`/`es/data.qmd` draw the **trend-cycle** as a faint line behind
each original series. Three things about that line:

- It is **INEGI's**, not computed here, which is only defensible because the
  validation above establishes that this pipeline reproduces INEGI's original
  series (median gap 0.013 pp).
- The quarterly adjusted series are in **percent**; the monthly ones in the
  same catalogue are index numbers. No rescaling is needed, but don't assume
  that if a monthly series is ever added.
- Trend-cycle is **revised backward**, so the figure quoted on each card comes
  from the original series and never from this line. Both pages say so.

While adding that line, `data.qmd`/`es/data.qmd` also gained the 2020-Q2 break
(`conHuecos`) that the private dashboard already had. These pages had been
drawing a straight line across the ETOE gap, which reads a change of method as
a gradual transition.

**All the Labor Market MX pages now state that their series are original,
without seasonal adjustment.** Nothing said so before.

### Figures on an in-progress page make the question vivid, never the answer

`scripts/06-in-progress-figures.R` builds the figure on each `in-progress`
page. The constraint that shapes both is the same one that removed their
`.finding`: there is no public result to show, so the figure has to motivate
the question without implying an answer.

In practice that means **magnitudes, not time series.** A series with the
reform date marked reads as a difference in means no matter how the caption
labels it, and that would put the finding back in through the side door.

This is not hypothetical. The ENOE coverage rate for domestic workers sits
near 2% for 2005–2019 and then steps to roughly 4% and stays there. That
series is the best-looking chart available and it is deliberately not used;
the page shows a single cross-section instead.

- `domestic-workers-coverage`: how many domestic workers there are and what
  share has social security, one quarter, no time axis. ENOE microdata via the
  paper's own pipeline — same standing as the Labor Market MX series the site
  already publishes: public source, own calculation, descriptive.
- `usmca-rules`: NAFTA against USMCA on the automotive rules of origin, as
  written. Source is CRS IF12082, Table 1. No computation at all, so no
  causal read is available to the reader. A wage-level comparison was
  considered and rejected: it would need an exchange rate and an hours
  assumption, which is a derived number on a research page.

Both follow section 5's `.chart-figure` pattern: four SVGs each (two languages
× two themes), tokens hand-copied from the SCSS, transparent background. Mind
the path depth — `../../../images/` from EN, `../../../../` from ES.

### Technical notes go below the charts, not above (2026-09-01)

The original-series and trend-cycle explanation first went in the page intro,
and the owner moved it. His reasoning is the rule to follow for anything
similar: there was already too much text before the reader reaches the
interesting part, and the trend-cycle line is a detail for a reader who knows
what seasonal adjustment is, not something a general audience needs in order
to read the chart.

So: **the intro says what the page is; the technical caveat goes after the
last chart**, in a `.chart-note` block, just above the "How this is built"
fold. `.chart-note` (`theme.scss`) is the fourth custom class on the site,
added for this — muted, smaller than body, capped at 620px. It exists because
plain body text was too loud for something explicitly not aimed at the general
reader. All five Labor Market MX pages use it, in both languages.

### The validation table follows the site's themes, not the CSV's sort order

`ultimasValidaciones` sorts by an explicit `ordenTemas` array before
rendering: participation, then informality, then unemployment, matching the
navbar. The CSV arrives sorted by indicator code, which interleaved the three.
Display order is a presentation choice, so it lives in the `.qmd`, not in
`scripts/04-labor-validations.R`.

Two details in that array worth keeping: `TSUB` sits next to `SUBUTIL`,
because underemployment is one of the components `SUBUTIL` aggregates, and
`TCCO` goes last because it belongs to none of the three themes and has no
page of its own. **Anything not in the array is appended, never dropped** — a
new indicator upstream must not vanish from this table, which is the same
failure mode the "not validated" rows exist to prevent.

The "Changes this quarter" table on the same page is deliberately left alone:
the reader sorts it by clicking a column header, so its order is UI state
rather than an editorial choice.
