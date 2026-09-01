# ---------------------------------------------------------------------------
# Figuras para las dos paginas de research/in-progress/
#
# Estas dos paginas no tienen un `.finding` (ver seccion 6 del CLAUDE.md: no
# hay resultado publico que enunciar todavia). Estas figuras existen para dar
# un ancla visual SIN insinuar un resultado, que es la restriccion que define
# ambas.
#
# La regla que siguen: la figura hace vivida la PREGUNTA, no la respuesta.
# En la practica eso significa magnitudes, no series de tiempo. Una serie con
# la fecha de la reforma marcada se lee como una diferencia de medias aunque
# se etiquete "descriptiva", y eso equivaldria a reponer el `.finding` que se
# quito a proposito.
#
#   1. domestic-workers-coverage: cuantas personas trabajadoras del hogar hay
#      y que fraccion tiene seguridad social. Un solo corte transversal, sin
#      eje temporal. La serie historica de esta misma tasa SI muestra un
#      escalon en 2019 y por eso queda deliberadamente fuera.
#
#   2. usmca-rules: el contenido de las reglas de origen automotrices, TLCAN
#      contra T-MEC, tal como estan escritas. Cero calculo propio y cero
#      lectura causal: es el texto del tratado, no un resultado.
#
# Se corre A MANO:
#   Rscript scripts/06-in-progress-figures.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
  library(here)
})

# Tokens del sitio, copiados a mano de theme.scss / theme-dark.scss. Son SVG
# estaticos fuera del render de Quarto, asi que no pueden leer el SCSS: si esos
# valores cambian, hay que actualizarlos aqui tambien (seccion 9 del CLAUDE.md).
paleta <- list(
  light = list(ink = "#171513", ink_soft = "#6b6660", rule = "#e0d8c5",
               teal = "#0f5757", ochre = "#b25a26"),
  dark  = list(ink = "#e3ddd0", ink_soft = "#9a948b", rule = "#332c26",
               teal = "#63b0b0", ochre = "#be8d74")
)

tema_base <- function(p) {
  theme_minimal(base_size = 11, base_family = "sans") +
    theme(
      plot.background  = element_blank(),
      panel.background = element_blank(),
      panel.grid       = element_blank(),
      axis.title       = element_blank(),
      axis.ticks       = element_blank(),
      plot.margin      = margin(4, 6, 2, 6),
      text             = element_text(colour = p$ink),
      axis.text        = element_text(colour = p$ink_soft, size = 9),
      legend.position  = "none"
    )
}

guardar <- function(g, nombre, lang, mode, ancho, alto) {
  ruta <- here("images", sprintf("%s-%s-%s.svg", nombre, lang, mode))
  svglite::svglite(ruta, width = ancho, height = alto, bg = "transparent")
  print(g); invisible(grDevices::dev.off())
  message("  ", basename(ruta))
}

# --- 1. Trabajadoras del hogar: tamano de la brecha de cobertura -----------
# Cifras de ENOE 2026-T2, calculadas con el diseno muestral complejo en el
# proyecto privado de este paper. Mismo estatus que las series de Labor Market
# MX que el sitio ya publica: fuente publica, calculo propio, descriptivo.
PTH <- list(universo = 2300268, cubiertas = 94541, trimestre = "2026-T2",
            pct = 4.11, mujeres = 90.9)

fig_pth <- function(lang, mode) {
  p <- paleta[[mode]]
  cubiertas_txt <- format(PTH$cubiertas, big.mark = if (lang == "es") "," else ",")
  universo_txt  <- format(PTH$universo,  big.mark = ",")
  # "Cubiertas" a secas no dice cubiertas de que. El indicador es afiliacion a
  # IMSS o ISSSTE, y el nombre completo es lo que hace legible la cifra.
  etiqueta_cub <- if (lang == "en")
    sprintf("%s with social security\n(IMSS or ISSSTE) — %.1f%%", cubiertas_txt, PTH$pct)
  else
    sprintf("%s con seguridad social\n(IMSS o ISSSTE) — %.1f%%", cubiertas_txt, PTH$pct)
  etiqueta_uni <- if (lang == "en")
    sprintf("%s domestic workers · %.0f%% women", universo_txt, PTH$mujeres)
  else
    sprintf("%s personas trabajadoras del hogar · %.0f%% mujeres", universo_txt, PTH$mujeres)

  d <- data.frame(x = 1, w = PTH$universo)
  ggplot(d) +
    # Universo completo
    geom_rect(aes(xmin = 0, xmax = PTH$universo, ymin = 0, ymax = 1),
              fill = NA, colour = p$rule, linewidth = 0.7) +
    # Porcion cubierta. Es una franja delgadisima, y ese es exactamente el
    # mensaje: la barra casi no se ve porque la cobertura casi no existe.
    geom_rect(aes(xmin = 0, xmax = PTH$cubiertas, ymin = 0, ymax = 1),
              fill = p$teal, colour = NA) +
    annotate("text", x = PTH$universo, y = 1.30, label = etiqueta_uni,
             hjust = 1, vjust = 0, size = 3.5, colour = p$ink) +
    annotate("segment", x = PTH$cubiertas, xend = PTH$cubiertas,
             y = -0.08, yend = -0.40, colour = p$ochre, linewidth = 0.5) +
    annotate("text", x = PTH$cubiertas * 1.05, y = -0.46, label = etiqueta_cub,
             hjust = 0, vjust = 1, size = 3.2, colour = p$ochre, lineheight = 1.15) +
    scale_x_continuous(expand = expansion(mult = c(0.01, 0.01))) +
    scale_y_continuous(limits = c(-1.15, 1.95), expand = c(0, 0)) +
    coord_cartesian(clip = "off") +
    tema_base(p) +
    theme(axis.text = element_blank())
}

# --- 2. T-MEC: las reglas de origen, tal como estan escritas ---------------
# Fuente: Congressional Research Service, "USMCA: Automotive Rules of Origin",
# IF12082, actualizado 8 dic 2023, Tabla 1 (CRS con base en el texto del TLCAN
# y del T-MEC). Numeros del tratado, no estimaciones.
REGLAS <- data.frame(
  orden  = c(1, 1, 2, 2, 3, 3),
  regimen = rep(c("NAFTA", "USMCA"), 3),
  valor   = c(62.5, 75, 0, 40, 0, 70)
)

fig_usmca <- function(lang, mode) {
  p <- paleta[[mode]]
  etiquetas <- if (lang == "en") c(
    "Regional content\nrequired",
    "Content made by workers\nearning at least US$16/hour",
    "North American steel\nand aluminium"
  ) else c(
    "Contenido regional\nexigido",
    "Contenido hecho por trabajadores\nque ganan al menos 16 USD/hora",
    "Acero y aluminio\nnorteamericano"
  )
  sin_regla <- if (lang == "en") "no rule" else "sin regla"

  d <- REGLAS
  d$grupo <- factor(d$orden, levels = 3:1, labels = rev(etiquetas))
  d$regimen <- factor(d$regimen, levels = c("NAFTA", "USMCA"))
  d$col <- ifelse(d$regimen == "USMCA", p$teal, p$ink_soft)
  d$txt <- ifelse(d$valor == 0, sin_regla, sprintf("%.4g%%", d$valor))

  ggplot(d, aes(x = valor, y = grupo, group = regimen)) +
    geom_col(aes(fill = I(col)), position = position_dodge(width = 0.72),
             width = 0.6) +
    geom_text(aes(label = txt, colour = I(col)),
              position = position_dodge(width = 0.72),
              hjust = -0.12, size = 3.1) +
    geom_text(aes(x = 0, label = as.character(regimen), colour = I(col)),
              position = position_dodge(width = 0.72),
              hjust = 1.15, size = 2.9) +
    scale_x_continuous(limits = c(0, 100), expand = expansion(mult = c(0.30, 0.06))) +
    coord_cartesian(clip = "off") +
    tema_base(p) +
    theme(axis.text.x = element_blank(),
          axis.text.y = element_text(colour = p$ink, size = 8.6, hjust = 0,
                                     lineheight = 1.1),
          plot.margin = margin(4, 10, 2, 6))
}

# --- salida -----------------------------------------------------------------
message("Trabajadoras del hogar (ENOE ", PTH$trimestre, "):")
for (lang in c("en", "es")) for (mode in c("light", "dark"))
  guardar(fig_pth(lang, mode), "domestic-workers-coverage", lang, mode, 6.6, 1.7)

message("T-MEC (CRS IF12082):")
for (lang in c("en", "es")) for (mode in c("light", "dark"))
  guardar(fig_usmca(lang, mode), "usmca-rules", lang, mode, 6.6, 3.0)
