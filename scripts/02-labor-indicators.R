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

# La carpeta del proyecto Dashboard se lee de la variable de entorno
# ENOE_DASHBOARD_DIR. No va escrita aqui a proposito: la ruta de Google Drive
# incluye la cuenta personal del owner, y este repo es publico. Ponla en
# ~/.Renviron:
#   ENOE_DASHBOARD_DIR=/ruta/a/PhD/Projects/ENOE/Dashboard
dir_dashboard <- Sys.getenv("ENOE_DASHBOARD_DIR", unset = "")
if (!nzchar(dir_dashboard)) {
  stop("Falta ENOE_DASHBOARD_DIR. Ponla en ~/.Renviron apuntando a la carpeta ",
       "del proyecto Dashboard y reinicia R.", call. = FALSE)
}

ruta_indicadores <- file.path(dir_dashboard, "data/processed/indicadores.parquet")

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
