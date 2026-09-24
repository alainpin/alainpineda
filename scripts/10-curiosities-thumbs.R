# 10-curiosities-thumbs.R
#
# Miniaturas para las tarjetas del listado de Curiosidades. Cada una sale de los
# datos reales de su propia nota, no de un esquema: la tarjeta no puede llevar
# una nota al pie que aclare que algo es ilustrativo, así que no se dibuja nada
# que no sea el dato.
#
# No llevan texto, así que a diferencia del resto de las figuras del sitio no
# necesitan variante por idioma: solo por tema (claro y oscuro), con el mismo
# mecanismo .chart-img-light / .chart-img-dark de theme.scss.
#
#   Rscript scripts/10-curiosities-thumbs.R

if (!isTRUE(l10n_info()[["UTF-8"]])) {
  stop("Corre con LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 (ver CLAUDE.md §5).")
}

suppressPackageStartupMessages({library(ggplot2); library(svglite); library(here); library(grid)})

# Tokens del sitio, copiados a mano: son SVG estáticos, no derivan del SCSS.
paleta <- list(
  light = list(ink = "#171513", rule = "#e0d8c5", teal = "#0f5757", ochre = "#b25a26"),
  dark  = list(ink = "#e3ddd0", rule = "#332c26", teal = "#63b0b0", ochre = "#be8d74")
)

base_thumb <- function(p) {
  p + theme_void() +
    theme(
      plot.background  = element_blank(),
      panel.background = element_blank(),
      plot.margin      = margin(2, 2, 2, 2),
      legend.position  = "none",
      strip.text       = element_blank(),
      panel.spacing    = unit(7, "pt")
    )
}

guarda <- function(p, nombre, modo) {
  ggsave(here::here("images", sprintf("%s-thumb-%s.svg", nombre, modo)),
         base_thumb(p), width = 2.6, height = 0.62, bg = "transparent")
}

# --- 1. weighted-averages ----------------------------------------------------
# El argumento de la nota en miniatura: la masa de municipios, la mediana entre
# ellos y el dato nacional, que queda muy a la derecha de casi todos.
mun <- read.csv(here::here("data", "prestaciones-municipios.csv"))
nac <- read.csv(here::here("data", "prestaciones-nacional.csv"))
v   <- mun$aguinaldo[!is.na(mun$aguinaldo)]
mediana  <- median(v)
nacional <- nac$nacional[nac$prestacion == "aguinaldo"] / 100

for (modo in names(paleta)) {
  col <- paleta[[modo]]
  p <- ggplot(data.frame(v = v), aes(v)) +
    geom_histogram(bins = 46, fill = col$ink, alpha = 0.32, colour = NA) +
    geom_vline(xintercept = mediana,  colour = col$ink,   linewidth = 0.5) +
    geom_vline(xintercept = nacional, colour = col$ochre, linewidth = 0.8) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05)))
  guarda(p, "weighted-averages", modo)
}

# --- 2. ecological-fallacy ---------------------------------------------------
# La miniatura tiene que llevar LAS DOS mitades, porque el mensaje de la nota es
# la inversión: entre las 32 entidades la relación es negativa (correlación
# -0.39) y entre hogares agrupados por activos es positiva. Con una sola mitad
# la tarjeta muestra una tendencia cualquiera, no la paradoja.
edo <- read.csv(here::here("data", "pets-estados.csv"))
gr  <- read.csv(here::here("data", "pets-gradiente.csv"))

paneles <- rbind(
  data.frame(panel = "1_entidades", x = edo$activos, y = edo$mascota),
  data.frame(panel = "2_hogares",   x = gr$activos,  y = gr$mascota)
)

for (modo in names(paleta)) {
  col <- paleta[[modo]]
  p <- ggplot(paneles, aes(x, y)) +
    # Ocre la relación entre entidades (la que engaña), teal la de hogares.
    geom_smooth(aes(colour = panel), method = "lm", se = FALSE, linewidth = 0.7) +
    geom_point(aes(colour = panel), size = 0.9, alpha = 0.85) +
    scale_colour_manual(values = c("1_entidades" = col$ochre, "2_hogares" = col$teal)) +
    facet_wrap(~panel, scales = "free_x")
  guarda(p, "ecological-fallacy", modo)
}

for (f in list.files(here::here("images"), "-thumb-(light|dark)\\.svg$", full.names = TRUE)) {
  message(sprintf("  %-42s %5.1f KB", basename(f), file.size(f) / 1024))
}
