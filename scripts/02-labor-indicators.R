# ---------------------------------------------------------------------------
# Produce data/labor-indicators.csv para data.qmd / es/data.qmd
#
# No recalcula nada: lee la tabla larga ya validada del proyecto privado
# "ENOE Dashboard" (capa pesada con diseno muestral complejo, contrastada
# contra el boletin oficial de INEGI 2024-T1, diferencia maxima 0.05 pp) y
# publica el subconjunto de indicadores nacionales de Capa 1 -- los que ya
# publica el propio INEGI, asi que no hay nada institucionalmente sensible.
#
# Se corre A MANO, no durante el render del sitio:
#   Rscript scripts/02-labor-indicators.R
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(arrow)
library(here)

# Ruta al parquet del proyecto Dashboard (repo/carpeta distinta a este sitio).
# Si esa carpeta se mueve, este es el unico lugar que hay que actualizar.
ruta_indicadores <- paste0(
  "/Users/alainpineda/Library/CloudStorage/GoogleDrive-alainpp25@gmail.com/",
  "My Drive/PhD/Projects/ENOE/Dashboard/data/processed/indicadores.parquet"
)

tabla <- arrow::read_parquet(ruta_indicadores) |>
  filter(corte == "nacional") |>
  transmute(
    anio, trimestre, indicador, regimen,
    valor = round(valor, 2),
    ee = round(ee, 3),
    n_obs
  ) |>
  arrange(indicador, anio, trimestre)

readr::write_csv(tabla, here("data", "labor-indicators.csv"))
message("Escrito: data/labor-indicators.csv (", nrow(tabla), " renglones, ",
        length(unique(tabla$indicador)), " indicadores)")
