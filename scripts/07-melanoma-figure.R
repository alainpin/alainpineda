# ---------------------------------------------------------------------------
# Figura para research/other/melanoma-utilization/ (y su version es/)
#
# Reconstruye, en el estilo del sitio, la comparacion central del paper:
# costo total de atencion medica por paciente por mes en cada uno de los
# cuatro esquemas de primera linea para melanoma metastasico, separando el
# costo del tratamiento (el medicamento) del resto de la atencion.
#
# Fuente: Qian, Betancourt, Pineda et al., "Health Care Utilization and Costs
# in Systemic Therapies for Metastatic Melanoma from 2016 to 2020", The
# Oncologist 2023;28(3):268-275, Tabla 2, columnas "Mean". Dolares reales de
# 2020, en miles, por paciente por mes. "Otra atencion" es total menos
# tratamiento: una resta directa de dos cifras publicadas, no una estimacion.
#
# El articulo es acceso abierto CC BY-NC, asi que reproducir su figura seria
# licito; se reconstruye de todos modos para que siga los temas claro/oscuro
# del sitio y porque la figura del paper es de tendencias de uso, no de
# costos. Esta muestra lo que un lector no especialista quiere ver primero:
# cuanto cuesta cada opcion y de que esta hecho ese costo.
#
# Se corre A MANO, con locale UTF-8. La herramienta que invoca Rscript no
# siempre hereda LANG, y sin UTF-8 svglite escribe los acentos de las
# etiquetas en espanol como bytes sueltos ("atenci..n m..dica"), sin error
# ni aviso. Ya paso una vez. Por eso el script se detiene si no esta en UTF-8:
#   LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 Rscript scripts/07-melanoma-figure.R
# ---------------------------------------------------------------------------

if (!isTRUE(l10n_info()[["UTF-8"]])) {
  stop("La sesion no esta en UTF-8 y las etiquetas en espanol saldrian ",
       "corruptas. Corre: LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 Rscript ",
       "scripts/07-melanoma-figure.R", call. = FALSE)
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(svglite)
  library(here)
})

# Tokens copiados a mano de theme.scss / theme-dark.scss (seccion 9 del
# CLAUDE.md): un SVG estatico no puede leer el SCSS.
paleta <- list(
  light = list(ink = "#171513", ink_soft = "#6b6660", rule = "#e0d8c5",
               teal = "#0f5757", ochre = "#b25a26"),
  dark  = list(ink = "#e3ddd0", ink_soft = "#9a948b", rule = "#332c26",
               teal = "#63b0b0", ochre = "#be8d74")
)

# Tabla 2 del paper: medias por paciente por mes, miles de USD de 2020.
COSTOS <- data.frame(
  clave       = c("nivo", "pembro", "brafmek", "combo"),
  tratamiento = c(17.2, 21.2, 22.3, 59.2),
  total       = c(25.4, 30.5, 32.5, 74.5),
  n           = c(811, 670, 173, 364)
)
COSTOS$otra <- COSTOS$total - COSTOS$tratamiento

nombres <- list(
  en = c(nivo = "Nivolumab", pembro = "Pembrolizumab",
         brafmek = "BRAF + MEK inhibitors", combo = "Ipilimumab + nivolumab"),
  es = c(nivo = "Nivolumab", pembro = "Pembrolizumab",
         brafmek = "Inhibidores BRAF + MEK", combo = "Ipilimumab + nivolumab")
)
leyenda <- list(
  en = c(tratamiento = "Drug cost", otra = "Other health care"),
  es = c(tratamiento = "Costo del medicamento", otra = "Otra atención médica")
)

fig <- function(lang, mode) {
  p <- paleta[[mode]]
  d <- COSTOS
  d$etiqueta <- nombres[[lang]][d$clave]
  # Ordenadas por costo total, de menor a mayor: asi la que se sale de la
  # escala queda abajo y a la vista, que es el punto de la figura.
  d$etiqueta <- factor(d$etiqueta, levels = rev(d$etiqueta[order(d$total)]))
  largo <- rbind(
    data.frame(etiqueta = d$etiqueta, parte = "tratamiento", valor = d$tratamiento),
    data.frame(etiqueta = d$etiqueta, parte = "otra",        valor = d$otra)
  )
  largo$parte <- factor(largo$parte, levels = c("otra", "tratamiento"))
  colores <- c(tratamiento = p$teal, otra = p$ink_soft)
  texto_total <- sprintf(if (lang == "en") "$%.1fK / month" else "%.1f mil USD / mes", d$total)

  ggplot(largo, aes(y = etiqueta, x = valor, fill = parte)) +
    geom_col(width = 0.62) +
    geom_text(data = d, aes(y = etiqueta, x = total, label = texto_total),
              inherit.aes = FALSE, hjust = -0.08, size = 3.1, colour = p$ink) +
    scale_fill_manual(values = colores, breaks = c("tratamiento", "otra"),
                      labels = leyenda[[lang]][c("tratamiento", "otra")], name = NULL) +
    scale_x_continuous(limits = c(0, 92), expand = expansion(mult = c(0, 0.02))) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_size = 11, base_family = "sans") +
    theme(
      plot.background  = element_blank(),
      panel.background = element_blank(),
      panel.grid       = element_blank(),
      axis.title       = element_blank(),
      axis.ticks       = element_blank(),
      axis.text.x      = element_blank(),
      axis.text.y      = element_text(colour = p$ink, size = 9.2, hjust = 1),
      legend.position  = "top",
      legend.justification = "left",
      legend.text      = element_text(colour = p$ink_soft, size = 8.6),
      legend.key.size  = unit(9, "pt"),
      legend.margin    = margin(0, 0, 4, 0),
      plot.margin      = margin(2, 8, 2, 4),
      text             = element_text(colour = p$ink)
    )
}

for (lang in c("en", "es")) for (mode in c("light", "dark")) {
  ruta <- here("images", sprintf("melanoma-cost-%s-%s.svg", lang, mode))
  svglite::svglite(ruta, width = 6.6, height = 2.6, bg = "transparent")
  print(fig(lang, mode)); invisible(grDevices::dev.off())
  message("  ", basename(ruta))
}
