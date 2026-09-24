# 09-curiosities-prestaciones.R
#
# Publica los datos de la curiosidad "promedios ponderados" a partir del
# pipeline ya validado del proyecto de la Encuesta Intercensal 2025, siguiendo el
# modelo de 02-labor-indicators.R: este script NO recalcula nada desde los
# microdatos, solo reencuadra para la web lo que ese proyecto ya estimó con el
# diseño muestral de la encuesta.
#
# El proyecto de origen vive fuera de este repo y pesa ~740 MB de microdatos, así
# que su ruta va en una variable de entorno y nunca en un archivo versionado:
#
#   export EIC2025_DIR=/ruta/al/proyecto/eic2025
#   Rscript scripts/09-curiosities-prestaciones.R
#
# Ahí, el orden es 00_descarga.R -> 01_prestaciones.R -> 03_mapa_datos.R ->
# 05_geometria.R -> geo_topojson.py -> 06_reparto.R.

suppressPackageStartupMessages({library(data.table); library(here)})

ORIGEN <- Sys.getenv("EIC2025_DIR")
if (ORIGEN == "" || !dir.exists(ORIGEN)) {
  stop("Define EIC2025_DIR con la ruta al proyecto de la Encuesta Intercensal 2025.")
}
fuente <- function(...) file.path(ORIGEN, ...)
destino <- function(x) here::here("data", x)

PN <- c("aguinaldo", "vacaciones", "servicio_medico", "incap_sueldo",
        "sar_afore", "credito_vivienda", "utilidades")

# ---- 1. Nacional: las siete prestaciones, con la mediana municipal ------------
# La mediana se calcula sobre TODOS los municipios con estimación, no solo sobre
# los precisos. Filtrar por coeficiente de variación no quita ruido al azar:
# como el CV lleva la estimación en el denominador, quita justo los municipios
# de cobertura más baja y sube la mediana entre 5 y 9 puntos.
nac <- fread(fuente("output", "prestaciones_nacional.csv"))
mun <- fread(fuente("output", "mapa_prestaciones.csv"), encoding = "UTF-8")

resumen <- mun[, .(mediana_municipal = round(100 * median(prevalencia), 1),
                   municipios = .N), by = prestacion]
resumen <- merge(resumen, nac[, .(prestacion, nacional = round(100 * prevalencia, 1),
                                  ee = round(100 * ee, 3))], by = "prestacion")
resumen <- merge(resumen, mun[, .(pct_debajo = round(100 * mean(
  prevalencia < nac[prestacion == .BY$prestacion, prevalencia]))), by = prestacion],
  by = "prestacion")
setcolorder(resumen, c("prestacion", "nacional", "ee", "mediana_municipal",
                       "pct_debajo", "municipios"))
setorder(resumen, -nacional)
fwrite(resumen, destino("prestaciones-nacional.csv"))

# ---- 2. Municipios: ancho, una fila por municipio -----------------------------
# p_<prestacion> = 1 cuando la estimación es precisa (CV <= 15% y no degenerada).
# Las imprecisas se publican igual: se dibujan rayadas, no se esconden.
mun[, cvegeo := sprintf("%05d", state_code * 1000 + mun_code)]
w  <- dcast(mun, cvegeo + entidad + municipio ~ prestacion, value.var = "prevalencia")
wp <- dcast(mun, cvegeo ~ prestacion, value.var = "publicable")
setnames(wp, PN, paste0("p_", PN))
w <- merge(w, wp, by = "cvegeo")
for (p in PN) w[, (p) := round(get(p), 3)]
for (p in PN) w[, (paste0("p_", p)) := as.integer(get(paste0("p_", p)))]
setcolorder(w, c("cvegeo", "entidad", "municipio", PN, paste0("p_", PN)))
fwrite(w, destino("prestaciones-municipios.csv"))

# ---- 3. Reparto: cuántas de las siete tiene cada persona ----------------------
rep <- fread(fuente("output", "reparto_prestaciones.csv"))
fwrite(rep[, .(k, share)], destino("prestaciones-reparto.csv"))

# ---- 4. Geometría municipal --------------------------------------------------
# Marco Geoestadístico de la propia Encuesta Intercensal 2025: los 2,478
# municipios vigentes al levantamiento, así que la unión con los datos es exacta.
file.copy(fuente("data", "geo", "mx_municipios_2025_tj.json"),
          destino("mx-municipios-2025.json"), overwrite = TRUE)

for (f in c("prestaciones-nacional.csv", "prestaciones-municipios.csv",
            "prestaciones-reparto.csv", "mx-municipios-2025.json")) {
  message(sprintf("  %-32s %7.0f KB", f, file.size(destino(f)) / 1024))
}
