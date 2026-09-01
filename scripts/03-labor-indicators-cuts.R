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

indicadores_con_cortes <- c("TPEA", "TIL1", "TIL2", "TOSI1", "TOSI2", "TD", "TDAMPL", "SUBUTIL")

# Lista blanca de cortes, no solo de indicadores. Sin ella, cualquier corte
# nuevo del pipeline privado se publica solo en la siguiente corrida, y eso ya
# fallo una vez: el corte cruzado `sexo_edad` entro con 1020 renglones que
# ademas quedaban corruptos, porque el transmute de abajo no arrastra
# `categoria_destino` y los seis grupos de edad caian todos etiquetados
# "Hombre" o "Mujer", indistinguibles entre si.
#
# Publicar un corte cruzado requiere decidirlo a proposito: agregarlo aqui, y
# agregar `categoria_destino` al transmute y a las paginas que lo consuman.
# "nacional" va incluido: seis paginas lo leen de ESTE archivo como linea de
# referencia detras de cada corte (data-participation.qmd:28 y equivalentes).
# Quitarlo no da error, solo desaparece esa linea de las seis paginas.
cortes_publicados <- c("nacional", "sexo", "edad", "nivel_educativo", "entidad")

tabla <- arrow::read_parquet(ruta_indicadores) |>
  filter(indicador %in% indicadores_con_cortes, corte %in% cortes_publicados) |>
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
