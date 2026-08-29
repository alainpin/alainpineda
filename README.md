# alainpineda.com

Sitio personal bilingüe en [Quarto](https://quarto.org). Markdown plano. Los
datos se preparan en **R** con scripts que corres a mano; el sitio en sí no
ejecuta código, así que compila en cualquier máquina.

- Inglés: `https://www.alainpineda.com/`
- Español: `https://www.alainpineda.com/es/`

> `CLAUDE.md` es el archivo de contexto para Claude Code. Si le pides ayuda en la
> terminal, ese archivo lo pone al día solo.

---

## 1. Arranque, una sola vez

1. Instala Quarto: <https://quarto.org/docs/get-started/>
2. Instala [R](https://cran.r-project.org/) y
   [Positron](https://positron.posit.co/) o [RStudio](https://posit.co/download/rstudio-desktop/).
   Los dos traen soporte de Quarto integrado.
3. Paquetes, una vez:

```r
install.packages(c("tidyverse", "haven", "srvyr", "fixest", "modelsummary", "here"))
```

`haven` lee tus `.dta` de Stata directo. `srvyr` maneja el diseño muestral de la
ENOE. `fixest` hace paneles con efectos fijos y se parece a `reghdfe`.

4. Abre `alainpineda.Rproj` y corre:

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

---

## 2. Qué reemplazar antes de publicar

Busca `REEMPLAZAR` con `Ctrl+Shift+F`.

| Archivo | Qué cambiar |
|---|---|
| `images/profile.jpg` | Tu foto. Cuadrada, mínimo 800×800 px. |
| `files/CV_Alain_Pineda.pdf` | Tu CV real, mismo nombre de archivo. |
| `_quarto-en.yml`, `_quarto-es.yml` | URL de Google Scholar y de GitHub. |
| `index.qmd`, `es/index.qmd` | El mismo link de Scholar. |
| `research/*/*/index.qmd` | PDFs de papers y slides que subas a `files/`. |
| `data.qmd`, `es/data.qmd` | Datos sintéticos. Reemplázalos por series reales. |

---

## 3. Cómo está armado

```
_quarto.yml        Config compartida por los dos idiomas.
_quarto-en.yml     Navbar y footer en inglés.  Sale a _site/
_quarto-es.yml     Navbar y footer en español. Sale a _site-es/
build.sh           Compila los dos y mete el español en _site/es
theme.scss         Colores y tipografías. Bloque de tokens hasta arriba.

index.qmd          Landing en inglés
research.qmd       Tres listas automáticas + la subsección de policy al final
data.qmd           Gráficas interactivas
teaching.qmd
research/working-papers/<slug>/index.qmd
research/in-progress/<slug>/index.qmd
research/published/<slug>/index.qmd

es/                Espejo completo en español, con los mismos slugs

scripts/           Scripts de R que generan lo que hay en data/ e images/
data/              CSVs generados por scripts/
files/             PDFs
images/            Foto y figuras
```

**Por qué se compila dos veces.** Quarto tiene un solo navbar por sitio. Para que
el menú diga "Investigación" y no "Research" en la versión en español, hay que
renderizar cada idioma con su propia configuración. Eso hace `build.sh`.

**Nunca corras `quarto publish`.** Solo compila un perfil y publicaría el sitio
sin la parte en español.

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

**Cuidado con los `../`.** Desde una carpeta de paper en inglés hay tres niveles
hasta la raíz; desde la versión en español hay cuatro. Es el error más común al
copiar una página de un idioma al otro.

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

El flujo es: script de R → CSV en `data/` → gráfica en `data.qmd`.

```bash
Rscript scripts/01-informality-by-state.R
```

Usa `scripts/01-informality-by-state.R` como modelo. Para estimaciones de la
ENOE que vayan a publicarse, usa el diseño muestral con `srvyr`, no un promedio
simple: los factores de expansión y los estratos cambian el resultado.

Luego cambias el nombre del archivo en el primer bloque `{ojs}` de `data.qmd` y
los nombres de columna. Ojo: en la página en inglés la ruta es `data/x.csv`; en
la de español es `../data/x.csv`.

Para figuras que van en un documento, hazlas con `ggplot2` en el mismo script,
guárdalas como SVG en `images/` con `ggsave()` y úsalas con markdown normal. Lo
interactivo solo cuando el lector gane algo con elegir estado, cohorte o año.

**Por qué R corre fuera del sitio.** Si metiéramos los chunks de R dentro de los
`.qmd`, GitHub Actions necesitaría R instalado para compilar. Manteniéndolo en
`scripts/`, el sitio se publica con Quarto y nada más.

---

## 6. Publicar

### Primera vez

1. Crea un repo en GitHub y sube esta carpeta a la rama `main`.
2. El workflow de `.github/workflows/publish.yml` compila los dos idiomas y
   empuja el resultado a la rama `gh-pages`. No hay que configurar nada más.
3. En Netlify, en el sitio que ya tienes: **Site configuration → Build & deploy**
   - Branch to deploy: `gh-pages`
   - Build command: vacío
   - Publish directory: `/`
4. El dominio y el DNS se quedan como están. No tocas nada ahí.

De ahí en adelante, cada `git push` a `main` actualiza el sitio.

### Por qué quedarse en Netlify

Solo pagas el dominio. El hosting ya es gratis y el DNS ya funciona. Mover a
GitHub Pages te obligaría a editar registros DNS para ahorrar cero pesos. Si algún
día quieres moverte, el archivo `CNAME` ya está listo.

---

## 7. Cambiar el diseño

Todo está en el bloque de tokens de las primeras líneas de `theme.scss`: seis
colores y tres tipografías. Cambias esos valores y cambia el sitio completo, en
los dos idiomas. La estructura de abajo no se toca.

---

## Pendientes

**Prioridad alta: materiales de Storytelling in Economics.** `teaching.qmd` y
`es/teaching.qmd` ya enlazan `files/storytelling-syllabus.pdf` y
`files/storytelling-slides.pdf`. Los dos archivos faltan, así que esos links
están muertos hasta que los subas. Para las slides hace falta una versión
pública, sin figuras internas de Banxico ni resultados no publicados.

- [ ] Subir `files/storytelling-syllabus.pdf`
- [ ] Subir `files/storytelling-slides.pdf` (versión pública)
- [ ] Foto y CV reales
- [ ] Link de Google Scholar
- [ ] Subir PDFs de papers y slides a `files/`
- [ ] Confirmar las líneas `.finding` de `domestic-workers` y `nafta-to-usmca`
- [ ] Reemplazar los datos sintéticos de `data.qmd` por series reales
- [ ] Verificar el disclaimer del footer

---

## Nota sobre policy

No hay sección de Policy en el menú. Los textos de política pública son una lista
de una línea al final de `research.qmd` (y de `es/research.qmd`):

```markdown
- **Título.** Publicación, *Serie*, fecha. [PDF](url)
```

Sin resumen y sin página propia, porque los recuadros del Informe Trimestral son
institucionales y no van firmados. Para agregar uno nuevo, añade un renglón en
los dos archivos.
