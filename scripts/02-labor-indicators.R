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

# Lista blanca de indicadores, igual que en 03-labor-indicators-cuts.R. El
# parquet privado ya trae, con corte "nacional", los niveles en personas, los
# salarios y los salarios imputados (SALARIO_IMP*), y sin esta lista salen
# publicados en este CSV aunque ninguna pagina los lea: el archivo es publico
# (alainpineda.com/data/labor-indicators.csv). Las series imputadas se quedan
# en el proyecto privado por decision del owner (2026-10-19). Publicar un
# indicador nuevo exige agregarlo aqui a proposito.
indicadores_publicados <- c("TPEA", "TIL1", "TIL2", "TOSI1", "TOSI2",
                            "TD", "TDAMPL", "SUBUTIL", "TSUB", "TCCO")

tabla <- arrow::read_parquet(ruta_indicadores) |>
  filter(corte == "nacional", indicador %in% indicadores_publicados) |>
  transmute(
    anio, trimestre, indicador, regimen,
    valor = round(valor, 2),
    ee = round(ee, 3),
    n_obs
  ) |>
  arrange(indicador, anio, trimestre)

faltan <- setdiff(indicadores_publicados, unique(tabla$indicador))
if (length(faltan)) {
  stop("Faltan indicadores publicados en el parquet: ", paste(faltan, collapse = ", "),
       call. = FALSE)
}

readr::write_csv(tabla, here("data", "labor-indicators.csv"))
message("Escrito: data/labor-indicators.csv (", nrow(tabla), " renglones, ",
        length(unique(tabla$indicador)), " indicadores)")
