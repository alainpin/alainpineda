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
research.qmd           EN research page. Three folder-driven listings
                       (working-papers, in-progress, health) plus two
                       hand-written lists (Banco de México, Other writing).
teaching.qmd           EN teaching page. Hand-written, no listing. Short cover
                       for the two ITAM courses; one pill out to the course
                       page below, plus the Spotify playlist.
storytelling-in-economics.qmd
                       EN page for the ITAM course: what it is, two Observable
                       exercises, the session index linking files/storytelling/,
                       how it is graded, and the bibliography. Same slug in ES
                       (es/storytelling-in-economics.qmd). See §12.

research/
  working-papers/<slug>/index.qmd
  in-progress/<slug>/index.qmd
  other/<slug>/index.qmd          Pages linked from the hand-written "Other
                                  work" list (melanoma paper, breastfeeding
                                  post). Not a listing.
  published/<slug>/index.qmd      Empty since 2026-09-01; comes back on the page
                                  when an economics paper is published. See §5.
policy/<slug>/index.qmd           Mini-pages for the Banxico box and the thesis.

curiosities.qmd        EN landing for the Curiosities section: one folder-driven
                       listing, same custom template as research.qmd. Same slug
                       in ES (es/curiosities.qmd). See §14.
curiosities/<slug>/index.qmd      One curiosity each, with its ES mirror at
                       es/curiosities/<slug>/index.qmd. Same slug both languages.

data.qmd               EN interactive figures (Observable). In the navbar.
es/                    Full Spanish mirror: index, research, data, teaching,
                       and es/research/** with the same slugs.

scripts/               R scripts that produce everything in data/ and images/.
                       Run by hand: `Rscript scripts/01-....R`,
                       `Rscript scripts/02-labor-indicators.R`
data/                  CSVs produced by scripts/, consumed by OJS blocks.
files/                 PDFs: CV, papers, briefs, and the two explainer HTML
                       files.
files/storytelling/    Per-session slide PDFs for the ITAM course,
                       `clase-01.pdf`–`clase-14.pdf` with no 07 or 12. Linked
                       one by one from the course page. See §12.
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
| `research/other/` | (no listing; linked from "Other work") | Pages for one-line entries that need a summary |
| `research/published/` | (not on the page while empty) | Peer-reviewed economics publications |

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

**Superseded in part on 2026-09-01 — read this first.** The single
"Policy and other writing" / "Política pública y otros textos" list was split
into two sections, in this order after "Work in progress" (a third, "Health
and work", existed for two revisions and was folded into "Other work" on the
owner's call: with the melanoma paper gone it held one blog post, and he did
not expect it to keep filling):

1. **Banco de México** — one line per Quarterly Report box, no summary, no
   voice, linking to the box's mini-page or canonical URL. The sober
   treatment below still governs every entry here.
2. **Other work / Otros trabajos** — hand-written one-liners, in this order:
   the melanoma paper, the IDB breastfeeding post, the ITAM thesis. The
   thesis line names its two prizes (Premio Citibanamex de Economía 2017,
   Premio Ex-ITAM 2018) on the research page itself, because that is what
   justifies an undergraduate thesis being there at all; use the exact
   spelling from the thesis page's own subtitle. The melanoma paper first sat
   as a listing card under "Health and work" and the owner said it still felt
   out of place; it did, because that section fit a piece about work and the
   paper is not about work, and because a card gives it the same visual weight
   as the job market paper. The melanoma line says "a collaboration with
   dermatologists and oncologists at Stanford that began through
   Knight-Hennessy": the affiliations are what the paper prints, and the
   Knight-Hennessy origin is the owner's own account of it, which is also what
   makes an economist's presence on an oncology paper legible in one clause.
   Do not add anything about the coauthors beyond what the paper itself
   prints — their programs, roles, or how the owner knows them are third-party
   detail and stay out (section 0). The
   melanoma and breastfeeding pages live under `research/other/`, a folder
   with no listing, so a one-liner can still point at a summary page.

**Every one-liner links to the thing itself first, then to the summary.**
The owner asked for this on the Banxico entry (link the box directly, do not
route readers through the summary page) and it is the rule for all three
lists: box PDF · summary; article · summary; post · summary; thesis PDF ·
summary. A one-liner that links only to a summary page is wrong.

**A page under Other work states its result in plain text, never in a
`.finding`.** The melanoma page (2026-09-01) opens with a one-paragraph
result and carries a `.chart-figure` rebuilt from the paper's Table 2, plus
"What the paper does", "What it found", and "How to read it" sections written
for a reader who is not an oncologist: a non-academic, or an economist who
wants to know what was done. It has a public result, so the section 6 rule
would allow a `.finding`; it does not get one because that device is the
signature of the owner's economics and policy work, and using it here would
undo the weight distinction the one-liner exists to make. The chart is
rebuilt in the site's style rather than reproduced from the PDF even though
the article is CC BY-NC: a rebuilt figure follows the light/dark themes and
the numbers are the paper's own (Table 2, total and treatment-related cost
per patient per month; "other care" is the difference).

**Weight is carried by format.** Listing cards (title, subtitle, description,
pills) are for the economics research and for pieces in the owner's own voice.
Anything that should be present but not compete with the research gets a
one-liner. Do not promote a one-liner to a card to "give it more presence";
that was the original problem.

Why: the old list mixed two registers (unsigned institutional boxes next to
personally-authored pieces), and "Other publications" held a single medical
paper, which read either as the owner's only publication or as an oddity.
Classifying by venue was the problem; these sections classify by what the
work is. The `research/published/` bucket stays in the repo and returns to
the page when an economics paper is published — a listing on an empty folder
is not rendered, so do not add it back before then.

The four moved pages carry `aliases:` for their old URLs and `netlify.toml`
has matching 301s (all point at `research/other/` directly; the intermediate
`research/health/` location was never published, so there is no redirect
chain). Folder URLs use the splat form
(`from = "/old/path/*"`, `to = "/new/path/:splat"`), which covers both
`/path/` and `/path/index.html` in one rule. The breastfeeding pages also
changed depth (2→3 levels EN, 3→4 ES), so their image paths were rewritten;
that is the trap in §4 invariant 5, and it is why a moved page must be
re-verified for resolved images, not just for rendering.

The paragraphs below describe the pre-2026-09-01 layout and remain accurate
about how a Banxico box entry must be written.


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

**Run every figure script under a UTF-8 locale, and make the script insist
on it.** The tool that invokes `Rscript` does not always inherit `LANG`.
Without UTF-8, `svglite` writes accented characters in Spanish labels as
stray bytes, with no error and no warning: `07-melanoma-figure.R` first
produced a legend reading "Otra atenci..n m..dica", and it was only caught by
looking at the rendered SVG. Both figure scripts now open with
`if (!isTRUE(l10n_info()[["UTF-8"]])) stop(...)` so the failure is loud, and
their run line is `LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 Rscript scripts/...`.
Copy both into any new figure script. The same trap, on the data side, is
documented at length in the private ENOE dashboard's own CLAUDE.md.

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

### Teaching links the explainer (2026-09-01)

`teaching.qmd` / `es/teaching.qmd` now carry one sentence under Storytelling in
Economics pointing at the job-market-paper explainer as "the same craft applied
to my own work". This is the one cross-link that makes the site's throughline
visible — an economist whose distinguishing trait is caring about being
understood — without stating it anywhere as a slogan. Keep it as a sentence
with an inline link, not a pill: the pill row is for course materials.

A second sentence, added 2026-09-02, does the same for Labor Market MX ("the
same craft applied to public data"), with an absolute path — `/data.html` on
the English page, `/es/data.html` on the Spanish one. Same rule: a sentence
with an inline link, never a pill, and the throughline is never named. The
pill row on these two pages is now a single pill out to the course page.

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

**Resource globs in `_quarto.yml` carry a leading `/`, and must keep it.**
Quarto resolves a `resources:` entry at any depth, the same way it resolves
listing globs (section 5), so a bare `data/` also matched `_site-es/data/`.
Because each profile leaves the other's output directory sitting in the
project root, every local build copied it in again one level deeper: found
on 2026-09-01 at 16 levels and 2 GB per side. Quarto does not clean an
output directory between renders, so if that nest ever reappears, delete
`_site/_site-es` and `_site-es/_site` by hand; CI is unaffected because it
renders from a clean checkout. Verified against a minimal project: `/data/`
copies only the root directory, `data/` copies every directory of that name.

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

**How to run the mobile check on a page with Observable charts (2026-09-01).**
Two tools each fail in a way that looks like a result, and both were caught
the same day:

- The Claude Code browser pane executes the OJS runtime **only while the pane
  is actually painting**. Observable's runtime advances on
  `requestAnimationFrame`, which never fires in a hidden pane, so the page sits
  at *zero* resolved variables and no chart SVGs indefinitely — not slowly,
  never. **Take a screenshot first**: it forces a paint and the whole runtime
  starts. (This entry previously claimed the pane cannot run OJS at all; that
  was wrong, and on 2026-09-02 it cost an hour and a false alarm that the live
  public site was down. It was not — it just needed a paint.) Two readings
  that look like diagnoses and are not: the
  `ojs-in-a-box-waiting-for-module-import` class stays in the DOM even after a
  cell renders, so counting it means nothing — count `svg[class*="plot"]`
  instead; and `FileAttachment` showing `_reachable: false` is just Quarto's
  shadow variable, not a fault. Beware also that `await connector.value(name)`
  on an unresolved variable never returns and kills the call with "renderer may
  be frozen" — inspect `window._ojs.ojsConnector.mainModule._scope`
  synchronously instead.
- Headless Chrome **clamps the window to a 500px minimum and crops the
  screenshot**. A `--window-size=390` capture is pixel-identical to the left
  390px of a 500px render (verified: mean difference 0.00, while 500 vs 600
  differ). It shows the title cut mid-word and the search icon missing, which
  reads exactly like a page that is too wide. It is not evidence of anything.

What actually settles it for a chart or an input: the container. Every Plot
figure on these pages sits inside `.data-panel`, whose `overflow-x: auto` is
what keeps a 640–680px figure scrolling within the panel instead of widening
the body — Plot ships `style="max-width: initial"` on its figure, so a chart
placed *outside* that panel will widen the page. `Inputs.select` forms are
constrained by the `form[class^="oi-"]` rules in `theme.scss` (wrap, select
`max-width: 100%`). So for a new chart: put it in `.data-panel`, then run the
pane's static scrollWidth check. For a new kind of OJS output, verify the
container rule the same way rather than trusting either screenshot method.

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

**Teaching materials — done.** The Storytelling in Economics course has its own
page, `storytelling-in-economics.qmd` and `es/storytelling-in-economics.qmd`,
and `teaching.qmd` / `es/teaching.qmd` link to it with a single pill. The
syllabus lives on that page as prose, not as a PDF. The slides are 12
per-session PDFs sitting loose in `files/storytelling/`
(`clase-01.pdf`–`clase-14.pdf`, skipping 07 and 12 — those sessions were
student presentations and never had slides), one link per session on the
course page. There is no syllabus PDF and no slides ZIP; `netlify.toml` 301s
their old paths to the course page.

The decks were compiled from the owner's Overleaf source with
MacTeX/`pdflatex` (two passes each, for correct bookmarks). Two things are
deliberately absent from the published set and must stay absent if any deck is
ever recompiled from a newer Overleaf export: every `\date{}` is blank, and a
number of individual frames were cut at the owner's request. Carry those cuts
forward rather than restoring what the published set leaves out, and ask the
owner before changing what any deck includes. Clase 15
(grad-school-abroad advice, off-topic for a storytelling course) is excluded
from the set entirely, never compiled and never published.

**No published deck carries a logistics frame, of any kind.** The rule is the
one the course-page conventions below state for the page, and it governs the
PDFs just as strictly: no room, no schedule, no course code, no attendance
rule, no incentive line, no office-hours frame, no assignment preview, no due
date, no student name. "Next class" frames are one shape of this; a
course-structure or housekeeping frame anywhere in a deck is another, and the
rule covers both. A replacement deck is swept before it is published, not
assumed clean.

Sweep a deck with `pypdf`, normalising accents first: text extraction splits
words at accented characters (`salón` comes out as `sal on`, `pequeños` as
`peque nos`), so a naive substring search misses exactly the frames that
matter. Strip combining marks and whitespace, then search. Vocabulary hits are
normal — "incentivos" and "asistencia escolar" are subject matter in several
decks — so read every hit rather than counting them.

There is no LaTeX source in this repo, so a frame is removed from a published
deck by dropping the page with `pypdf` (a fresh `PdfWriter` and
`append(reader, pages=keep)`, which stays closest to the original file size)
and rebuilding the `/PageLabels` `/Nums` ranges so each remaining page keeps
the frame number its own footer prints. The printed footer sequence then skips
the removed frame and its total no longer matches the count of frames present.
That is expected and stays; do not recompile a deck to tidy it.

On 2026-08-30 the owner asked to embed a Spotify playlist directly on
`teaching.qmd` / `es/teaching.qmd`, under the Storytelling in Economics
section, as a raw ```{=html}<iframe>...``` block (Spotify's own embed code,
`width="100%"`, `height="352"`). The playlist comes out of a class assignment
that asked students for their favorite stories told in songs, and the page
says so in one sentence above it. It is a current decision of the owner's:
keep it on the teaching page, exactly where it is, and do not repeat it on
the course page.

A Quarto `revealjs` conversion was prototyped on Clase 13 and rejected by the
owner ("needs a lot more work") in favor of PDFs — don't revisit that path
without being asked.

**Conventions for the course page, fixed 2026-09-02.**

- The slug is `storytelling-in-economics` in **both** languages, so the
  switcher's default prepend/strip logic works and it needs no entry in
  `js/lang-toggle.html`'s `MAPA_SLUGS_ESPECIALES` (section 4). It sits at the
  repo root, not in a `teaching/` folder.
- Section order, both languages: `.eyebrow` with the institutional metadata
  (ITAM · programme · term), "What it is" / "De qué trata", "The craft in two
  exercises" / "El oficio en dos ejercicios", "The sessions" / "Las sesiones",
  "How it is graded" / "Cómo se evalúa", "Readings" / "Lecturas".
- The session index is one entry per session: number and title, a one-sentence
  description, a method label where the session teaches one, the readings, and
  a link to that session's PDF with its size in MB. Sessions 7 and 12 are
  covered by one line after the list.
- **Never quote a slide count.** The decks are beamer with overlays, so a PDF
  page is not a slide. Sizes in MB are safe; page counts are not.
- **A reading is cited only as far as the source supports.** Give the venue,
  volume, issue, or document type when the deck or the syllabus prints it, or
  when it has been checked against the publisher's own record. Where the deck
  gives only author, title, and year, the page gives only author, title, and
  year — session 5's Ortega Hesles entry is the worked example. Naming an
  institution or a document type that no source states is the failure mode to
  avoid.
- Nothing internal to the course reaches the page: no student names, no room,
  no schedule, no course code, no attendance rule, no grading percentages, no
  due dates.
- The decks contain third-party figures, magazine and press material, and
  charts carrying institutional branding. That is fine inside a PDF. The site
  neither reproduces nor recreates any of it, and does not restate in its own
  voice the political, historical, or personal material a deck cites as
  evidence — the index says what a session covers and stops there.
- Two Observable exercises, both inside `.data-panel`: the count-the-3s grid
  (`.digit-grid` in `theme.scss`, which is also why the font `@import` asks for
  IBM Plex Mono 600) and a chart rebuilt in six steps. The six steps are the
  course's own decluttering order from Clase 09, not invented; the last step
  additionally moves the chart into this site's data-page style, which is the
  only part that is not from the course.
- The Spanish page reads `FileAttachment("../data/labor-indicators.csv")` and
  links slides as `../files/storytelling/...`. Both depend on the page sitting
  directly in `es/` (section 4, invariant 5).

**Everything else, current state and open gaps.**

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
- **The repo (`alainpin/alainpineda`) is public.** Confirmed 2026-09-01 with
  `gh repo view --json visibility`. This entry said "currently private" for
  several days after that stopped being true, which is worse than saying
  nothing: section 0's rule is only as urgent as this line makes it sound.
  Verify visibility with that command rather than trusting this sentence, and
  never flip it unprompted in either direction.
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

0. **A display cell that is just the name of a chart cell shows the
   inspector, not the chart.** Define `grafica = { ... return Plot.plot(...) }`
   and then write a cell containing only `grafica`, and the page renders
   `▶ SVGSVGElement {value: null, scale: ƒ, legend: ƒ}` where the chart should
   be, while the real SVG sits inside the hidden definition cell. Every chart
   on these pages is therefore a **function** called from the display cell
   (`graficaSerieMultiple(...)`, `graficaBrechaEdad()`); the private dashboard
   gets the same effect by interpolating into an `html\`...\`` template. Two
   consequences for verification: a text search of the served HTML finds the
   chart's labels inside an `<svg>` even when the visible cell shows the
   inspector, because the hidden cell holds the node, so strip
   `class="cell hidden"` blocks before searching; and a headless DOM check is
   not a substitute for looking at a screenshot of the section at least once.
   Caught on 2026-09-01 on the participation-gap charts, after the DOM check
   had passed.
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

### The overview page opens with questions, not indicators (2026-09-01)

`data.qmd` / `es/data.qmd` carry a short "Start from a question" list right
after the intro: four reader questions, each routing to the page whose data
answers it. The owner's diagnosis was that the section informed but did not
invite; a dashboard of ten rates gives a general reader nothing to hold on
to, while a question does. This is framing, not opinion: every question has
a factual answer at its link, and none implies what that answer is.

Section 7 bans rhetorical questions as headings. These are neither headings
nor rhetorical, and that is the line to hold if the list grows: a question
goes in only if a page answers it with data, and it is phrased so that it
does not lean toward an answer ("How much of the workforce is unemployed,
discouraged, or working fewer hours than it wants?", never "Is unemployment
really as low as it looks?").

### The participation gap by age is on the Participation page (2026-09-01)

`data-participation.qmd` / `es/data-participacion.qmd` end with "The gap
between women and men, by age": two Observable charts and five paragraphs.
It was ported from the private dashboard, where it is the most-read section,
as the test case for the site's rule on these pages: describe what the
series show, never why.

- **Data.** The crossed cut `sexo_edad` (TPEA by sex × age group) is now in
  `data/labor-indicators-cuts.csv`, published by
  `scripts/03-labor-indicators-cuts.R`, which carries `categoria_destino`
  (the age group) for that cut. It is the only cut that uses that column.
  Every other page filters by `corte` before reading rows, so the extra rows
  and column are invisible to them; this was verified, not assumed.
- **Colors.** Six ordered tokens `$edad-1..6` in `theme.scss` (light,
  `!default`) and `theme-dark.scss`, exposed as `--edad-1..6` on `:root`
  for OJS. Cool-to-warm hue progression rather than a single-hue ramp: age
  is ordered, but six lines that cross are not separable by lightness. Values
  and the >=3:1 contrast check come from the private dashboard's own review.
- **Charts.** Gap as (men − women) / men, unitless so six age groups plus the
  national line share one chart; then women's participation levels by age on
  its own, because a gap that closes from women entering looks identical to
  one that closes from men leaving. Both fix their y-domain; the end-of-line
  label separator converts pixels back to data units and cannot without one.
  Ink for the national line, the age palette for the groups.
- **Text.** Every number in the five paragraphs was recomputed from the CSV
  before writing, and two earlier session claims did not survive that check:
  men's participation fell since the women's peak in five of six groups (it
  rose 0.4 pp in 30–39), and the 60+ women's peak was 2020-Q1, not 2023–25.
  The page says "five of the six" and limits the 2023-Q4–2025-Q4 claim to
  ages 20–59. Recompute before editing any of these sentences.
- **What it does not say.** The private version reads the 14–19 pattern as
  school enrollment. That is an interpretation and it stays off the public
  page. The public text stops at what the series show.

**The youngest age group is "15 a 19" / "15 to 19", not "14 a 19".** ENOE's
precoded `eda7c` band is named "14 a 19", but every rate on the site is
computed on ages 15 and over, so the band only ever contains 15–19. The owner
decided on 2026-09-01 that labels follow the data. The fix was made at the
source (`mapa_edad` in the private pipeline, with the parquet relabelled in
place), so the exported CSVs carry "15 a 19"; the page-side maps
(`etiquetaEn`, the `edad` order arrays) and prose were updated to match. If
"14 a 19" ever reappears in a CSV, the private export was run from a stale
parquet — do not patch it on the page side.

**A `Plot.tip` bound to one series silently answers for another.** The gap
chart draws seven lines but its tip was bound only to `datosEdad`, the six
age groups. Plot's pointer transform still resolves a hover anywhere in the
frame to its nearest point *in that dataset*, so hovering the national line
returned a nearby age group's numbers under that group's name — no error, a
plausible tooltip, the wrong series. It survived a DOM check and a
screenshot because a tip only exists while the pointer is over the figure.
Caught on 2026-09-01, on the same day the page started promising an interval
"for every series". Rule: a tip's data must be the union of every series the
chart draws, and its title has to name the series it is describing.

**The gap chart carries 95% intervals.** The gap (men − women) / men gets a
standard error by the delta method from the two survey estimates, treating
men and women as independent domains (the same independence approximation
the quarterly-update page makes). The band is drawn only on the national
line — six overlapping bands would hide the lines — and every series shows
its interval in the tooltip. The women's-levels chart uses the `ee` column
directly in its tooltip.

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
---

## 14. Curiosities — the section that is explicitly not research

`curiosities.qmd` / `es/curiosities.qmd` ("Curiosities" / "Curiosidades") is a
folder-driven listing over `curiosities/<slug>/index.qmd`, added 2026-09-02. It
reuses `listing-templates/research-listing.ejs.md` rather than a new template,
per the note in §6: a listing that wants the same card shape points at the same
file. Neither page sets `pdf:` or `explainer:`, and the template renders no
pills when both are absent.

**What the section is for.** Short pieces built from public microdata, each one
using a dataset that happens to be in circulation to explain one idea in
statistics or economics. The dataset is the occasion; the idea is the point.
The blurb on both landing pages says outright that none of it is research, that
it is descriptive and exploratory, and that it has nothing to do with the
owner's work at Banco de México — and then claims the one thing it does share
with the rest of the site: every number goes through the survey's own design.

**Do not rename the section toward anything that reads like a publication
series.** It was called "Notes" for about an hour and the owner changed it. The
name should say plainly that the section is for fun.

**Topic boundary, applied before starting a new curiosity:** could this topic
appear in a report from the owner's own division? If yes, it does not go here.
Public microdata on pets passes the test; labour-market and monetary topics do
not. §8 governs everything else.

**Same slug in both languages, and keep it that way.** `curiosities` is the
folder in both trees, so the switcher's default prepend/strip logic works and
no `MAPA_SLUGS_ESPECIALES` entry is needed (§4). This is a deliberate departure
from the Labor Market MX precedent of translated slugs: that section is four
flat pages, so four map entries are a fixed cost, while this one grows, and a
diverging folder would need a new entry for *every* note forever — with the
documented failure mode that a missing or stale key 404s the switcher silently.
English slugs under `/es/` are the site's norm everywhere except those four
pages anyway.

**No `.finding`.** A curiosity has a public result, so the §6 rule would allow
one, and it still does not get one — same reasoning as the melanoma page: the
device is the signature of the economics and policy work, and using it here
would undo the weight distinction the section exists to make. Open with a plain
paragraph instead.

**One note, one concept, and name the concept early.** The first version of the
ecological-fallacy page demonstrated the idea for three sections and only then
named it, which asks a reader who has never met it to hold a pattern in their
head with no label for it. It now opens with the idea in plain language before
any Mexican data, uses Robinson's 1930-census example as the illustration, and
closes with the full citation. The page's own figures then read as recognition
rather than introduction. Two other findings from the same microdata (a null on
subjective wellbeing, a rural/urban gap) were cut or demoted to one sentence
for the same reason: a second lesson dilutes the first.

**Voice is §7, not the explainer's.** The explainer under `files/` is a
standalone HTML file outside the Quarto render, and it narrates. These are
Quarto pages and the site's editorial voice governs them. Didactic does not
mean chatty: short declarative sentences still apply.

### `curiosities/ecological-fallacy/` — the first one

- **Data.** INEGI's ENBIARE 2025, whose housing section carries six pet items
  (P1.8.1.1–P1.8.3.2) between the household assets and the resident count.
  `scripts/08-curiosities-pets.R` downloads the open-microdata zip to a temp
  directory on every run and versions none of it: 6 MB of CSV that INEGI
  already publishes at a stable URL. Everything goes through `svydesign` with
  the declared `upm_dis` / `est_dis` / `fac_viv`, the same standard §9 imposes
  on ENOE. The national figures reproduce INEGI's own release exactly, which is
  the cheapest available check that the pipeline is right.
- **Outputs.** `data/pets-{nacional,estados,gradiente}.csv` and two figures in
  four variants each (`pets-aggregation-*`, `pets-ranking-*`). Data files are
  named by content, not by section, like the rest of `data/` — if the section is
  ever renamed again the filenames do not move.
- **The map is Observable, everything else is static.** The interactive form is
  earned here: the reader switches between any pet, dog and cat, and the tooltip
  carries the confidence interval. It reuses `data/mx-estados.json` and the
  choropleth conventions already settled in §13, including coercing both sides
  of the state-code join to numbers.
- **Each measure gets its own colour ramp** (`BuGn` for any pet, `OrRd` for
  dog, `Purples` for cat), set from an `esquema` field on the `medidas` object
  and threaded through a named `esquemaMapa` cell. The owner asked for this:
  with one shared ramp, switching measures only changed the shading and the
  change was easy to miss. Each ramp is single-hue light-to-dark, as a
  sequential scale should be; the three hues are far apart, and two of them sit
  in the site's own `$teal` and `$ochre` families while purple already exists
  in the age ramp.
- **The chart function must not read the selector.** `graficaMapa` takes rows,
  a label and a scheme; the selector feeds named cells (`filasMapa`,
  `etiquetaMapa`, `esquemaMapa`) that the display cell passes in. This mirrors
  `data-informality.qmd` and is the shape to copy for the next interactive
  curiosity.

**A verification gap worth knowing about.** The Claude Code browser pane cannot
drive a native `<select>`: a synthetic `input` event, the `form_input` tool and
a real keypress all fail to move the Observable variable. The same test fails
on `data-informality.html`, which is shipped and works, so this is a limitation
of the tooling and not evidence of a bug — but it does mean the reactivity of
any `Inputs.select` on this site has to be confirmed by a human click. Do not
report a selector as verified from an automated check; say which check you
could not run, as §11 expects.
