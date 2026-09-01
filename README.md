# alainpineda.com

Sitio personal bilingüe en [Quarto](https://quarto.org). Markdown plano. Los
datos se preparan en **R** con scripts que se corren a mano; el sitio en sí no
ejecuta código, así que compila en cualquier máquina con solo Quarto.

- Inglés: `https://www.alainpineda.com/`
- Español: `https://www.alainpineda.com/es/`

> `CLAUDE.md` es el archivo de contexto para Claude Code y tiene el detalle
> largo de cada convención. Este README es el resumen operativo.

---

## 1. Requisitos

1. [Quarto](https://quarto.org/docs/get-started/)
2. [R](https://cran.r-project.org/) y
   [Positron](https://positron.posit.co/) o
   [RStudio](https://posit.co/download/rstudio-desktop/), solo si vas a
   regenerar datos. Para compilar el sitio basta Quarto.
3. Paquetes, una vez:

```r
install.packages(c("tidyverse", "haven", "srvyr", "arrow", "here"))
```

`haven` lee `.dta` de Stata directo. `srvyr` maneja el diseño muestral de la
ENOE. `arrow` lee el parquet del pipeline externo.

## 2. Compilar

```bash
quarto preview                 # inglés, se actualiza al guardar
quarto preview --profile es    # español
```

Para ver las dos versiones juntas, como quedan publicadas:

```bash
./build.sh
python3 -m http.server 8080 --directory _site
```

En Windows corre los tres comandos de `build.sh` a mano, o usa Git Bash.

**Nunca corras `quarto publish`.** Solo compila un perfil y publicaría el sitio
sin la parte en español.

---

## 3. Cómo está armado

```
_quarto.yml        Config compartida por los dos idiomas.
_quarto-en.yml     Navbar y footer en inglés.  Sale a _site/
_quarto-es.yml     Navbar y footer en español. Sale a _site-es/
build.sh           Compila los dos y mete el español en _site/es
theme.scss         Colores y tipografías. Bloque de tokens hasta arriba.
theme-dark.scss    Solo los tokens del tema oscuro.

index.qmd          Landing en inglés
research.qmd       Tres listas automáticas + la subsección de policy
data.qmd           Panorama del mercado laboral (Observable)
data-*.qmd         Páginas por tema y la actualización trimestral
teaching.qmd
research/working-papers/<slug>/index.qmd
research/in-progress/<slug>/index.qmd
research/published/<slug>/index.qmd
policy/<slug>/index.qmd

es/                Espejo completo en español

scripts/           Scripts de R que generan lo que hay en data/ e images/
data/              CSVs generados por scripts/
files/             PDFs y explicadores en HTML
images/            Foto y figuras
```

**Por qué se compila dos veces.** Quarto tiene un solo navbar por sitio. Para
que el menú diga "Investigación" y no "Research" en la versión en español, hay
que renderizar cada idioma con su propia configuración. Eso hace `build.sh`.

**Cuidado con los `../`.** Desde una carpeta de paper en inglés hay tres
niveles hasta la raíz; desde la versión en español hay cuatro. Es el error más
común al copiar una página de un idioma al otro.

---

## 4. Agregar un paper

```bash
cp -r research/in-progress/domestic-workers research/in-progress/mi-paper
cp -r es/research/in-progress/domestic-workers es/research/in-progress/mi-paper
```

Edita los dos `index.qmd`. El front matter controla el listado:

```yaml
---
title: "Título del paper"
subtitle: "Work in progress"          # o "R&R at AEJ: Applied", etc.
description: "Una frase. Es lo único que se lee en la lista."
date: 2026-03-01                       # ordena, más reciente arriba
---
```

`description` no es un teaser: quien pasa la vista por la lista debe salir
sabiendo el resultado.

Cuando un working paper se publica, mueve las dos carpetas a `published/` y
cambia el `subtitle` a la revista. Los listados se reacomodan solos.

### Los tres bloques de estilo

```markdown
::: {.eyebrow}
Working paper · Borrador de agosto de 2026
:::
```
Metadata: estatus, revista, fecha. Nunca prosa.

```markdown
::: {.finding}
Una o dos líneas con el resultado y lo que implica.
:::
```
**El bloque más importante del sitio.** Va antes del resumen y es lo que lee
alguien del IMSS o de Hacienda que nunca va a abrir el PDF. Sin jerga, sin
"margen extensivo", máximo dos líneas, uno por página.

```markdown
::: {.paper-links}
- [Paper (PDF)](../../../files/mi-paper.pdf)
- [Slides](../../../files/mis-slides.pdf)
- [Replication](https://github.com/usuario/repo)
- [Versión en español](/es/research/working-papers/mi-paper/)
:::
```

El resumen completo va colapsado, en `<details class="abstract">`.

---

## 5. Datos y gráficas

El flujo es: script de R → CSV en `data/` → gráfica en un `.qmd`.

Los scripts **no recalculan nada desde microdatos**: leen un pipeline de R
externo que ya aplicó el diseño muestral complejo de la ENOE, y publican de ahí
el subconjunto que va al sitio.

```bash
Rscript scripts/02-labor-indicators.R     # series nacionales
Rscript scripts/03-labor-indicators-cuts.R # cortes por sexo, edad, escolaridad, entidad
Rscript scripts/04-labor-validations.R    # cotejo contra el BIE de INEGI
Rscript scripts/05-labor-seasonal.R       # series ajustadas de INEGI
```

Se corren a mano, una vez por trimestre, cuando INEGI libera datos nuevos.
Usa `scripts/02-labor-indicators.R` como modelo para uno nuevo.

Para figuras estáticas, hazlas con `ggplot2` en el mismo script, guárdalas como
SVG en `images/` y úsalas con markdown normal. Cada gráfica hecha desde cero va
en dos variantes de color, clara y oscura, dentro de un bloque `.chart-figure`.
Lo interactivo solo cuando el lector gane algo con elegir estado, cohorte o año.

**Ojo con las rutas.** En la página en inglés es `data/x.csv`; en la de español
es `../data/x.csv`. Una ruta mal puesta da una gráfica vacía sin error.

**Nunca publiques una estimación de la ENOE como promedio simple.** Si un
número del sitio viene de microdatos de encuesta, tuvo que pasar por el diseño
muestral.

**Por qué R corre fuera del sitio.** Si los chunks de R vivieran dentro de los
`.qmd`, GitHub Actions necesitaría R instalado para compilar. Manteniéndolo en
`scripts/`, el sitio se publica con Quarto y nada más.

---

## 6. Publicar

Cada `git push` a `main` dispara `.github/workflows/publish.yml`, que compila
los dos idiomas y empuja el resultado a la rama `gh-pages`. Netlify sirve esa
rama con el build command vacío, y se encarga del dominio y el CDN.

Netlify lee `netlify.toml` desde la raíz de lo que publica, o sea `gh-pages`.
Por eso el archivo está listado en `resources:` de `_quarto.yml`: sin eso nunca
llega a producción y sus reglas no aplican, sin ningún error visible. Un
redirect se verifica contra el sitio en vivo con `curl -I`, nunca contra una
compilación local.

---

## 7. Cambiar el diseño

Todo está en el bloque de tokens de las primeras líneas de `theme.scss`, y sus
equivalentes oscuros en `theme-dark.scss`. Cambias esos valores y cambia el
sitio completo, en los dos idiomas y en los dos temas. La estructura de abajo
no se toca, y no lleva colores literales: todo deriva de los tokens.

---

## 8. Nota sobre policy

No hay sección de Policy en el menú. Los textos de política pública viven en
una subsección de `research.qmd` (y de `es/research.qmd`), como lista de una
línea:

```markdown
- **Título.** Publicación, *Serie*, fecha. [PDF](url)
```

Los recuadros del Informe Trimestral de Banco de México son institucionales y
no van firmados, así que se quedan en una línea, sin resumen y sin página
propia. Los textos de autoría personal sí pueden tener su propia mini-página
bajo `policy/<slug>/`, con su espejo en `es/policy/<slug>/`.
