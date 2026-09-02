# ---------------------------------------------------------------------------
# Curiosidad: mascotas, ingreso y la falacia ecologica
# (curiosities/ecological-fallacy/)
#
# Fuente: INEGI, Encuesta Nacional de Bienestar Autorreportado (ENBIARE) 2025,
# microdatos abiertos. Las mascotas no son un modulo: son seis reactivos de la
# seccion de vivienda (P1.8.1.1 a P1.8.3.2), entre los activos del hogar y el
# numero de residentes.
#
# El script BAJA el zip de datos abiertos del INEGI a un directorio temporal en
# cada corrida. No se versiona microdato en este repo: 6 MB de CSV que no son
# nuestros y que el INEGI ya publica en una URL estable.
#
# Todo se estima con el diseno muestral declarado (upm_dis, est_dis, fac_viv).
# La regla del sitio aplica igual que a la ENOE: ninguna cifra publicada aqui
# puede venir de una media sin ponderar.
#
# Escribe:
#   data/pets-nacional.csv    una fila, las cifras nacionales
#   data/pets-estados.csv     32 filas, con error estandar
#   data/pets-gradiente.csv   9 filas, por numero de activos del hogar
#   images/pets-aggregation-<lang>-<mode>.svg   la figura de la tesis
#   images/pets-ranking-<lang>-<mode>.svg       el ranking con intervalos
#
# Se corre A MANO, con locale UTF-8. Sin el, svglite escribe los acentos de las
# etiquetas en espanol como bytes sueltos, sin error y sin aviso (paso en
# 07-melanoma-figure.R):
#   LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 Rscript scripts/08-curiosities-pets.R
# ---------------------------------------------------------------------------

if (!isTRUE(l10n_info()[["UTF-8"]])) {
  stop("La sesion no esta en UTF-8. Corre: LANG=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 ",
       "Rscript scripts/08-curiosities-pets.R", call. = FALSE)
}

suppressPackageStartupMessages({
  library(survey)
  library(ggplot2)
  library(svglite)
  library(here)
})
options(survey.lonely.psu = "adjust")

URL_ENBIARE <- paste0(
  "https://www.inegi.org.mx/contenidos/programas/enbiare/2025/",
  "datosabiertos/conjunto_de_datos_enbiare_2025_csv.zip"
)

# --- 1. Descarga y lectura -------------------------------------------------

tmp <- file.path(tempdir(), "enbiare2025")
dir.create(tmp, showWarnings = FALSE)
zip_local <- file.path(tmp, "enbiare2025.zip")

if (!file.exists(zip_local)) {
  message("Bajando microdatos de la ENBIARE 2025 del INEGI...")
  utils::download.file(URL_ENBIARE, zip_local, mode = "wb", quiet = TRUE)
}
utils::unzip(zip_local, exdir = tmp, overwrite = TRUE)

ruta_viv <- file.path(
  tmp, "conjunto_de_datos_tvivienda_enbiare_2025",
  "conjunto_de_datos", "conjunto_de_datos_tvivienda_enbiare_2025.csv"
)
if (!file.exists(ruta_viv)) {
  stop("No se encontro la tabla de vivienda dentro del zip. ",
       "Revisa si el INEGI cambio la estructura del paquete.", call. = FALSE)
}

viv <- utils::read.csv(ruta_viv, colClasses = "character", encoding = "UTF-8")

# --- 2. Construccion de variables -----------------------------------------

# El "cuantos" viene vacio cuando la respuesta al "tienen" fue no.
conteo <- function(x) { y <- suppressWarnings(as.numeric(x)); y[is.na(y)] <- 0; y }

viv$n_perro <- conteo(viv$p1_8_1_2)
viv$n_gato  <- conteo(viv$p1_8_2_2)
viv$n_otra  <- conteo(viv$p1_8_3_2)

viv$perro <- as.integer(viv$p1_8_1_1 == "1")
viv$gato  <- as.integer(viv$p1_8_2_1 == "1")
viv$otra  <- as.integer(viv$p1_8_3_1 == "1")
viv$mascota <- as.integer(viv$perro | viv$gato | viv$otra)

# Indice de activos del hogar, 0 a 8: refrigerador, lavadora, automovil,
# pantalla plana, computadora, consola, internet y servicio de peliculas o
# musica de paga (P1.7.1 a P1.7.8). Es una suma simple, no un indice de
# componentes principales: se lee directo ("un activo mas") y no depende de
# una descomposicion que la nota tendria que explicar.
activos_cols <- paste0("p1_7_", 1:8)
viv$activos <- rowSums(sapply(activos_cols, function(c) as.integer(viv[[c]] == "1")))

# menor10 == 1 son localidades de 1 a 9 999 habitantes.
viv$rural  <- as.integer(viv$menor10 == "1")
viv$npers  <- suppressWarnings(as.numeric(viv$p2_1))
viv$fac    <- as.numeric(viv$fac_viv)
viv$uno    <- 1
viv$cve    <- as.integer(viv$cve_ent)

dis <- svydesign(~upm_dis, strata = ~est_dis, weights = ~fac, data = viv, nest = TRUE)

# --- 3. Cifras nacionales --------------------------------------------------

pct <- function(f) round(100 * as.numeric(coef(svymean(f, dis))), 1)
mill <- function(f) round(as.numeric(coef(svytotal(f, dis))) / 1e6, 1)

nacional <- data.frame(
  viviendas_millones = round(sum(viv$fac) / 1e6, 2),
  n_muestra          = nrow(viv),
  pct_mascota        = pct(~mascota),
  pct_perro          = pct(~perro),
  pct_gato           = pct(~gato),
  pct_otra           = pct(~otra),
  perros_millones    = mill(~n_perro),
  gatos_millones     = mill(~n_gato),
  otras_millones     = mill(~n_otra)
)
ic_nac <- confint(svyciprop(~I(mascota == 1), dis, method = "logit"))
nacional$pct_mascota_ic_bajo <- round(100 * ic_nac[1], 1)
nacional$pct_mascota_ic_alto <- round(100 * ic_nac[2], 1)

# --- 4. Por entidad --------------------------------------------------------

por_ent <- function(f) svyby(f, ~cve, dis, svymean)
m_masc <- por_ent(~mascota); m_perr <- por_ent(~perro); m_gato <- por_ent(~gato)
m_act  <- por_ent(~activos); m_rur  <- por_ent(~rural)
t_viv  <- svyby(~uno, ~cve, dis, svytotal)
t_num  <- svyby(~n_perro + n_gato + n_otra, ~cve, dis, svytotal)

estados <- data.frame(
  cve_ent      = m_masc$cve,
  n_muestra    = as.vector(table(viv$cve)),
  viviendas_millones = round(t_viv$uno / 1e6, 3),
  mascota      = round(100 * m_masc$mascota, 2),
  mascota_ee   = round(100 * m_masc$se, 2),
  perro        = round(100 * m_perr$perro, 2),
  perro_ee     = round(100 * m_perr$se, 2),
  gato         = round(100 * m_gato$gato, 2),
  gato_ee      = round(100 * m_gato$se, 2),
  perros_millones = round(t_num$n_perro / 1e6, 2),
  gatos_millones  = round(t_num$n_gato / 1e6, 2),
  activos      = round(m_act$activos, 2),
  pct_rural    = round(100 * m_rur$rural, 1)
)

# --- 5. Gradiente por numero de activos ------------------------------------

g_med <- svyby(~mascota + perro + gato, ~activos, dis, svymean)
g_tot <- svyby(~uno, ~activos, dis, svytotal)
gradiente <- data.frame(
  activos            = as.integer(as.character(g_med$activos)),
  viviendas_millones = round(g_tot$uno / 1e6, 2),
  mascota            = round(100 * g_med$mascota, 1),
  perro              = round(100 * g_med$perro, 1),
  gato               = round(100 * g_med$gato, 1)
)

# --- 6. Regresion, para las cifras que cita la nota ------------------------
# MCO ponderado con efectos fijos de entidad. Es una correlacion condicional,
# no un efecto; la pagina lo dice con esas palabras.

coefs <- function(dep) {
  f <- stats::as.formula(paste(dep, "~ activos + rural + npers + factor(cve)"))
  s <- summary(svyglm(f, design = dis))$coefficients
  data.frame(dep = dep, term = c("activos", "rural", "npers"),
             b = round(100 * s[c("activos", "rural", "npers"), 1], 2),
             ee = round(100 * s[c("activos", "rural", "npers"), 2], 2))
}
regresion <- do.call(rbind, lapply(c("mascota", "perro", "gato"), coefs))

# Corte rural / urbano, que es el mecanismo que explica la inversion.
rur <- svyby(~mascota + perro + gato + n_perro + n_gato, ~rural, dis, svymean)

utils::write.csv(nacional,  here("data", "pets-nacional.csv"),  row.names = FALSE)
utils::write.csv(estados,   here("data", "pets-estados.csv"),   row.names = FALSE)
utils::write.csv(gradiente, here("data", "pets-gradiente.csv"), row.names = FALSE)

message("\n--- Cifras que cita la nota ---")
print(nacional)
message("\nCorrelacion entre entidades (activos, % con mascota): ",
        round(stats::cor(estados$activos, estados$mascota), 2))
message("Correlacion entre entidades (activos, % con gato):    ",
        round(stats::cor(estados$activos, estados$gato), 2))
message("Gradiente 0 -> 8 activos, % con mascota: ",
        gradiente$mascota[1], " -> ", gradiente$mascota[9],
        "  (", sprintf("%+.1f", gradiente$mascota[9] - gradiente$mascota[1]), " pp)")
message("Error estandar por entidad (pp): mediana ",
        round(stats::median(estados$mascota_ee), 2),
        ", maximo ", round(max(estados$mascota_ee), 2))
message("\n--- Regresion (puntos de probabilidad) ---")
print(regresion)
message("\n--- Rural (1) contra urbano (0) ---")
print(round(rur, 3))

# --- 7. Figuras ------------------------------------------------------------

# Tokens del sitio, copiados a mano de theme.scss / theme-dark.scss. Son SVG
# estaticos fuera del render de Quarto, asi que no pueden leer el SCSS: si esos
# valores cambian hay que actualizarlos aqui (seccion 9 del CLAUDE.md).
paleta <- list(
  light = list(ink = "#171513", ink_soft = "#6b6660", rule = "#e0d8c5",
               teal = "#0f5757", ochre = "#b25a26"),
  dark  = list(ink = "#e3ddd0", ink_soft = "#9a948b", rule = "#332c26",
               teal = "#63b0b0", ochre = "#be8d74")
)

NOMBRE_ENT <- list(
  en = c("Aguascalientes", "Baja California", "Baja California Sur", "Campeche",
         "Coahuila", "Colima", "Chiapas", "Chihuahua", "Mexico City", "Durango",
         "Guanajuato", "Guerrero", "Hidalgo", "Jalisco", "Mexico State",
         "Michoacán", "Morelos", "Nayarit", "Nuevo León", "Oaxaca", "Puebla",
         "Querétaro", "Quintana Roo", "San Luis Potosí", "Sinaloa", "Sonora",
         "Tabasco", "Tamaulipas", "Tlaxcala", "Veracruz", "Yucatán", "Zacatecas"),
  es = c("Aguascalientes", "Baja California", "Baja California Sur", "Campeche",
         "Coahuila", "Colima", "Chiapas", "Chihuahua", "Ciudad de México", "Durango",
         "Guanajuato", "Guerrero", "Hidalgo", "Jalisco", "México",
         "Michoacán", "Morelos", "Nayarit", "Nuevo León", "Oaxaca", "Puebla",
         "Querétaro", "Quintana Roo", "San Luis Potosí", "Sinaloa", "Sonora",
         "Tabasco", "Tamaulipas", "Tlaxcala", "Veracruz", "Yucatán", "Zacatecas")
)

TXT <- list(
  en = list(
    panel_a = "Between states",
    panel_b = "Within the country",
    x_a = "Average household assets in the state (0 to 8)",
    x_b = "Household assets (0 to 8)",
    y   = "Homes with a pet (%)",
    nota_a = "Each point is a state",
    nota_b = "Each point is a group of homes",
    x_rank = "Homes with a pet (%)",
    nacional = "national"
  ),
  es = list(
    panel_a = "Entre entidades",
    panel_b = "Dentro del país",
    x_a = "Activos promedio del hogar en la entidad (0 a 8)",
    x_b = "Activos del hogar (0 a 8)",
    y   = "Viviendas con mascota (%)",
    nota_a = "Cada punto es una entidad",
    nota_b = "Cada punto es un grupo de viviendas",
    x_rank = "Viviendas con mascota (%)",
    nacional = "nacional"
  )
)

# Todas las marcas de los ejes caen en enteros, asi que no hay separador
# decimal que localizar. Se formatean como enteros a proposito: un "75.0" en
# un eje de porcentajes es ruido.
fmt0 <- function(v) formatC(v, format = "d")

# Panel A (promedio de la entidad) y panel B (numero de activos) comparten la
# funcion de escala porque facet_wrap solo admite una, asi que las marcas se
# eligen a partir del rango de cada panel.
cortes_x <- function(lim) if (max(lim, na.rm = TRUE) > 7) seq(0, 8, 2) else 3:5

tema_base <- function(p) {
  theme_minimal(base_size = 11, base_family = "sans") +
    theme(
      plot.background  = element_blank(),
      panel.background = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = p$rule, linewidth = 0.3),
      text             = element_text(colour = p$ink),
      axis.text        = element_text(colour = p$ink_soft, size = 8.5),
      axis.title       = element_text(colour = p$ink_soft, size = 8.5),
      strip.text       = element_text(colour = p$ink, size = 10, hjust = 0,
                                      face = "bold",
                                      margin = margin(b = 6, t = 2)),
      plot.margin      = margin(4, 8, 2, 4),
      legend.position  = "none"
    )
}

guardar <- function(g, nombre, lang, mode, ancho, alto) {
  ruta <- here("images", sprintf("%s-%s-%s.svg", nombre, lang, mode))
  svglite::svglite(ruta, width = ancho, height = alto, bg = "transparent")
  print(g); invisible(grDevices::dev.off())
  message("  ", basename(ruta))
}

# --- Figura 1: la misma relacion en dos niveles de agregacion --------------
# Los dos paneles comparten el eje vertical a proposito: la comparacion solo
# significa algo si "% con mascota" mide lo mismo en los dos lados. El eje
# horizontal es libre porque no son la misma variable (promedio de la entidad
# contra numero de activos de la vivienda).

fig_agregacion <- function(lang, mode) {
  p <- paleta[[mode]]
  t <- TXT[[lang]]

  a <- data.frame(x = estados$activos, y = estados$mascota,
                  panel = factor(t$panel_a, levels = c(t$panel_a, t$panel_b)))
  b <- data.frame(x = gradiente$activos, y = gradiente$mascota,
                  panel = factor(t$panel_b, levels = c(t$panel_a, t$panel_b)))

  ajuste <- stats::lm(y ~ x, data = a)
  linea_a <- data.frame(
    x = range(a$x),
    y = stats::predict(ajuste, newdata = data.frame(x = range(a$x))),
    panel = a$panel[1]
  )

  # Abajo a la derecha en los dos paneles: es la unica zona vacia en ambos
  # (el punto mas bajo del panel A es la Ciudad de Mexico y la linea del panel
  # B termina arriba), asi que la nota no tapa ningun dato.
  etiquetas <- data.frame(
    panel = c(a$panel[1], b$panel[1]),
    x = c(max(a$x), max(b$x)),
    y = c(50, 50),
    lab = c(t$nota_a, t$nota_b)
  )

  ggplot(mapping = aes(x = x, y = y)) +
    geom_line(data = linea_a, colour = p$ochre, linewidth = 0.7, linetype = "22") +
    geom_point(data = a, colour = p$ochre, size = 2.1, alpha = 0.85) +
    geom_line(data = b, colour = p$teal, linewidth = 0.9) +
    geom_point(data = b, colour = p$teal, size = 2.1) +
    geom_text(data = etiquetas, aes(label = lab), hjust = 1, vjust = 0,
              colour = p$ink_soft, size = 3, family = "sans") +
    facet_wrap(~panel, scales = "free_x") +
    scale_y_continuous(limits = c(49, 76), breaks = seq(50, 75, 5),
                       labels = fmt0) +
    scale_x_continuous(breaks = cortes_x, labels = fmt0) +
    labs(x = NULL, y = t$y) +
    tema_base(p) +
    theme(panel.spacing.x = unit(16, "pt"))
}

# --- Figura 2: el ranking estatal con intervalos de confianza --------------
# La figura existe para mostrar que el orden no se sostiene, asi que el
# intervalo es el objeto principal y el punto es secundario.

fig_ranking <- function(lang, mode) {
  p <- paleta[[mode]]
  t <- TXT[[lang]]
  d <- estados
  d$nombre <- NOMBRE_ENT[[lang]][d$cve_ent]
  d <- d[order(d$mascota), ]
  d$nombre <- factor(d$nombre, levels = d$nombre)
  nac <- nacional$pct_mascota

  ggplot(d, aes(y = nombre)) +
    geom_vline(xintercept = nac, colour = p$ink_soft,
               linewidth = 0.5, linetype = "22") +
    geom_linerange(aes(xmin = mascota - 1.96 * mascota_ee,
                       xmax = mascota + 1.96 * mascota_ee),
                   colour = p$rule, linewidth = 1.6) +
    geom_point(aes(x = mascota), colour = p$teal, size = 1.8) +
    annotate("text", x = nac, y = 33.2, label = t$nacional,
             colour = p$ink_soft, size = 2.9, family = "sans", hjust = 0.5) +
    scale_x_continuous(limits = c(50, 80), breaks = seq(50, 80, 5),
                       labels = fmt0) +
    coord_cartesian(clip = "off") +
    labs(x = t$x_rank, y = NULL) +
    tema_base(p) +
    theme(panel.grid.major.y = element_blank(),
          axis.text.y = element_text(colour = p$ink, size = 8),
          plot.margin = margin(14, 8, 2, 4))
}

message("\nEscribiendo figuras...")
for (lang in c("en", "es")) {
  for (mode in c("light", "dark")) {
    guardar(fig_agregacion(lang, mode), "pets-aggregation", lang, mode, 7.2, 3.4)
    guardar(fig_ranking(lang, mode),    "pets-ranking",     lang, mode, 6.4, 6.2)
  }
}

message("\nListo.")
