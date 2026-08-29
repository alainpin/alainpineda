# ---------------------------------------------------------------------------
# Produce data/informality-example.csv para la grafica de data.qmd
#
# Se corre A MANO, no durante el render del sitio. El sitio se queda sin motor
# de computo: compila en cualquier maquina aunque no tenga R instalado.
#
#   Rscript scripts/01-informality-by-state.R
# ---------------------------------------------------------------------------

# install.packages(c("tidyverse", "haven", "srvyr", "here"))
library(tidyverse)
library(here)

# --- Opcion A: partir de un .dta que ya tengas ------------------------------
# library(haven)
# enoe <- read_dta(here("raw", "enoe_sdemt.dta"))

# --- Opcion B: ENOE con diseno muestral -------------------------------------
# La ENOE es una encuesta con diseno complejo. Para cualquier estimacion que
# vaya a publicarse hay que usar los factores de expansion y los estratos,
# no un promedio simple.
#
# library(srvyr)
# dsg <- enoe |>
#   as_survey_design(ids = upm, strata = est_d_tri, weights = fac_tri,
#                    nest = TRUE)
#
# tabla <- dsg |>
#   filter(eda >= 15, clase1 == 1) |>
#   group_by(ent, year) |>
#   summarise(informality_rate = survey_mean(informal == 1, na.rm = TRUE) * 100)

# --- Placeholder: datos sinteticos, se borra cuando lleguen los reales ------
set.seed(7)
base <- tibble::tribble(
  ~state,             ~start,
  "Oaxaca",            79.0,
  "Chiapas",           76.5,
  "Guerrero",          77.5,
  "Puebla",            71.0,
  "Hidalgo",           68.0,
  "Jalisco",           49.0,
  "Nuevo Le\u00f3n",   37.0,
  "Coahuila",          35.5,
  "Baja California",   39.0,
  "Ciudad de M\u00e9xico", 47.5
)

tabla <- base |>
  crossing(year = 2015:2025) |>
  arrange(state, year) |>
  group_by(state) |>
  mutate(
    drift = cumsum(runif(n(), -0.9, 0.35)),
    covid = if_else(year == 2020, 2.2, 0) + if_else(year == 2021, -1.0, 0),
    informality_rate = round(start + drift + cumsum(covid), 2)
  ) |>
  ungroup() |>
  select(state, year, informality_rate)

# --- Salida ----------------------------------------------------------------
readr::write_csv(tabla, here("data", "informality-example.csv"))
message("Escrito: data/informality-example.csv (", nrow(tabla), " renglones)")

# --- Opcional: figura estatica para usar dentro de un paper ----------------
# p <- ggplot(tabla, aes(year, informality_rate, colour = state)) +
#   geom_line(linewidth = 0.7) +
#   labs(x = NULL, y = "Tasa de informalidad (%)", colour = NULL) +
#   theme_minimal(base_family = "IBM Plex Sans", base_size = 12) +
#   theme(panel.grid.minor = element_blank())
# ggsave(here("images", "informality-by-state.svg"), p, width = 8, height = 4.5)
