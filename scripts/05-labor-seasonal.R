# ---------------------------------------------------------------------------
# Produce data/labor-seasonal.csv para data.qmd / es/data.qmd
#
# No calcula nada: publica las series ajustadas que INEGI mismo publica en su
# Banco de Informacion Economica (BIE), descargadas por R/validar_contra_bie.R
# en el proyecto privado "ENOE Dashboard".
#
# Por que se pueden superponer sobre nuestra serie original: el mismo script
# que las descarga confirma que nuestra original reproduce la de INEGI (1700
# comparaciones, mediana 0.013 pp), asi que la ajustada oficial es la ajustada
# de ESTA serie y no de otra parecida.
#
# Dos cosas que no son obvias:
#   - Las ajustadas TRIMESTRALES vienen en porcentaje. Las mensuales del mismo
#     catalogo vienen en indice. Estas se grafican directo, sin reescalar.
#   - Solo existen para 6 indicadores. SUBUTIL y TDAMPL, que este sitio si
#     publica, no tienen version ajustada trimestral en el BIE; esos paneles
#     van sin linea de fondo en vez de con una calculada aqui.
#
# Se corre A MANO, no durante el render del sitio:
#   Rscript scripts/05-labor-seasonal.R
# ---------------------------------------------------------------------------

library(dplyr)
library(readr)
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

ruta_ajustadas <- file.path(dir_dashboard, "site/data/desestacionalizadas.csv")

if (!file.exists(ruta_ajustadas)) {
  stop("No se encontro ", ruta_ajustadas,
       ". Corre primero R/validar_contra_bie.R en el proyecto Dashboard.",
       call. = FALSE)
}

tabla <- readr::read_csv(ruta_ajustadas, show_col_types = FALSE) |>
  # 2020-T2 fuera: el BIE empalma ahi el dato de la ETOE telefonica, que no es
  # comparable con la ENOE y que nuestra serie original deja como hueco.
  # Dibujar la ajustada continua mientras la original se corta sugeriria un
  # dato que no tenemos. Al quitarlo, las dos rompen en el mismo punto.
  filter(!(anio == 2020 & trimestre == 2)) |>
  transmute(anio, trimestre, indicador, tipo, valor = round(valor, 2)) |>
  arrange(indicador, tipo, anio, trimestre)

readr::write_csv(tabla, here("data", "labor-seasonal.csv"))

message("Escrito: data/labor-seasonal.csv (", nrow(tabla), " renglones, ",
        length(unique(tabla$indicador)), " indicadores x ",
        length(unique(tabla$tipo)), " tipos)")
message("Indicadores: ", paste(sort(unique(tabla$indicador)), collapse = ", "))
