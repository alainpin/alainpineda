# ---------------------------------------------------------------------------
# Produce data/labor-indicators-cuts.csv para data-participacion.qmd,
# data-informalidad.qmd, data-desocupacion.qmd (y sus versiones es/) -- los
# cortes por sexo, edad, nivel educativo y entidad que la propia INEGI no
# publica en su sitio.
#
# No recalcula nada: lee la misma tabla larga validada del proyecto privado
# "ENOE Dashboard" que ya usa 02-labor-indicators.R, pero sin el filtro
# corte == "nacional" -- solo para los indicadores que ya tienen esos cortes
# calculados. Es pura recombinacion de categorias que la ENOE ya distingue
# por separado (sexo, grupo de edad, nivel de instruccion, entidad) -- nada
# institucionalmente sensible, mismo criterio que ya aplica
# 02-labor-indicators.R.
#
# TD/TDAMPL/SUBUTIL solo tendran filas reales una vez que termine el
# backfill de desocupacion_por_cortes() en el proyecto privado (ver
# agregar_lote_historico(calcular_desocupacion_periodo, ...) en
# construir_tabla_indicadores.R) -- hasta entonces este script simplemente
# no encuentra esas filas y las omite, sin error.
#
# Se corre A MANO, no durante el render del sitio:
#   Rscript scripts/03-labor-indicators-cuts.R
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
library(arrow)
library(here)

ruta_indicadores <- paste0(
  "/Users/alainpineda/Library/CloudStorage/GoogleDrive-alainpp25@gmail.com/",
  "My Drive/PhD/Projects/ENOE/Dashboard/data/processed/indicadores.parquet"
)

indicadores_con_cortes <- c("TPEA", "TIL1", "TIL2", "TOSI1", "TOSI2", "TD", "TDAMPL", "SUBUTIL")

tabla <- arrow::read_parquet(ruta_indicadores) |>
  filter(indicador %in% indicadores_con_cortes) |>
  transmute(
    anio, trimestre, indicador, regimen, corte, categoria_origen,
    valor = round(valor, 2),
    ee = round(ee, 3),
    n_obs
  ) |>
  arrange(indicador, corte, categoria_origen, anio, trimestre)

readr::write_csv(tabla, here("data", "labor-indicators-cuts.csv"))
message("Escrito: data/labor-indicators-cuts.csv (", nrow(tabla), " renglones, ",
        length(unique(tabla$indicador)), " indicadores, ",
        length(unique(tabla$corte)), " cortes)")
