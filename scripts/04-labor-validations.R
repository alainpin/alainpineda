# ---------------------------------------------------------------------------
# Produce data/validations.csv para data-quarterly-update.qmd
# y es/data-actualizacion-trimestral.qmd
#
# No valida nada aqui: lee el resultado de la validacion que ya corre en el
# proyecto privado "ENOE Dashboard" (R/validar_contra_bie.R), que compara el
# pipeline contra las series originales que INEGI publica en el BIE.
#
# Por que cambio la fuente: hasta 2026-08-31 este archivo se llenaba A MANO
# copiando el boletin trimestral. El boletin solo trae el trimestre mas
# reciente, asi que ese cotejo comparaba nuestra publicacion contra nuestra
# publicacion anterior y no podia detectar deriva frente a INEGI en ningun
# trimestre pasado. El BIE trae la serie completa y se actualiza el mismo dia.
#
# El cambio ya corrigio un error visible en la pagina publica: la fila de TCCO
# reportaba una diferencia de 0.30 pp (boletin 38.0 contra pipeline 37.7) que
# la pagina atribuia a un rebase del umbral de salario minimo. La serie propia
# de INEGI en el BIE da 37.698. El pipeline siempre estuvo bien y el numero
# anomalo era el del boletin.
#
# Se corre A MANO, no durante el render del sitio:
#   Rscript scripts/04-labor-validations.R
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

ruta_validaciones <- file.path(dir_dashboard, "site/data/validaciones.csv")

if (!file.exists(ruta_validaciones)) {
  stop("No se encontro ", ruta_validaciones,
       ". Corre primero R/validar_contra_bie.R en el proyecto Dashboard.",
       call. = FALSE)
}

# Tolerancia usada por la validacion en el proyecto privado. Se repite aqui
# solo para derivar la clave de nota; la fuente de verdad es TOLERANCIA_PP en
# R/validar_contra_bie.R.
TOLERANCIA_PP <- 0.25

tabla <- readr::read_csv(ruta_validaciones, show_col_types = FALSE) |>
  transmute(
    anio, trimestre, indicador,
    oficial, pipeline, diferencia_pp,
    # Clave de nota, no prosa. El sitio es bilingue y una sola columna de texto
    # solo puede estar en un idioma: cada pagina traduce esta clave. Antes la
    # nota estaba escrita a mano dentro del .qmd, en los dos idiomas, y ahi se
    # quedo cuando el diagnostico que describia resulto ser falso.
    nota_clave = case_when(
      is.na(oficial) ~ "sin_bie",
      diferencia_pp > TOLERANCIA_PP ~ "excede",
      TRUE ~ ""
    )
  ) |>
  arrange(anio, trimestre, indicador)

readr::write_csv(tabla, here("data", "validations.csv"), na = "")

ultimo <- tabla |> filter(anio == max(anio)) |> filter(trimestre == max(trimestre))
sin_validar <- ultimo |> filter(is.na(oficial)) |> pull(indicador)

message("Escrito: data/validations.csv (", nrow(tabla), " renglones, ",
        length(unique(tabla$anio)) , " anios)")
message("Ultimo periodo: ", ultimo$anio[1], "-T", ultimo$trimestre[1],
        " (", nrow(ultimo), " indicadores)")
if (length(sin_validar)) {
  message("Sin serie equivalente en el BIE, se publican como no validados: ",
          paste(sin_validar, collapse = ", "))
}
