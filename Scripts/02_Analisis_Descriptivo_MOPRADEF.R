# ============================================================================
# 02 | Tablas descriptivas ponderadas - MOPRADEF 2025
# Requiere ejecutar primero Scripts/01_Carga_y_Limpieza_MOPRADEF.R.
# Instalar una vez: install.packages(c("survey", "dplyr", "readr"))
# Entrada: Data/analisis_df.rds | Salidas: Output/02_*.csv
# ============================================================================

paquetes <- c("survey", "dplyr", "readr")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) stop("Instala: ", paste(faltantes, collapse = ", "))
ruta <- file.path("Data", "analisis_df.rds")
if (!file.exists(ruta)) stop("Falta ", ruta, ". Ejecuta primero el script 01.")
dir.create("Output", showWarnings = FALSE)
datos <- readRDS(ruta)
necesarias <- c("practica", "sexo_grupo", "edad_grupo", "educacion",
                "barrera_abandono", "barrera_nunca", "fac_ele",
                "upm_dis", "est_dis")
faltan_columnas <- setdiff(necesarias, names(datos))
if (length(faltan_columnas)) stop("Faltan columnas: ", paste(faltan_columnas, collapse = ", "))
if (anyNA(datos$fac_ele) || any(datos$fac_ele <= 0) ||
    anyNA(datos$upm_dis) || anyNA(datos$est_dis)) {
  stop("Hay pesos o datos del diseño inválidos.")
}
options(survey.lonely.psu = "adjust")
diseno <- survey::svydesign(ids = ~upm_dis, strata = ~est_dis,
                            weights = ~fac_ele, data = datos, nest = TRUE)

# Tasa nacional: personas con respuesta 0 o 1 a p1.
total <- survey::svymean(~practica, diseno, na.rm = TRUE)
ic_total <- stats::confint(total)
tasa_total <- data.frame(
  grupo = "Total", n_sin_ponderar = sum(!is.na(datos$practica)),
  tasa = as.numeric(stats::coef(total)),
  li_95 = as.numeric(ic_total[1, 1]), ls_95 = as.numeric(ic_total[1, 2]))
readr::write_csv(tasa_total, "Output/02_tasa_nacional.csv")

# Tasas por sexo, edad y nivel educativo; n son personas, no población expandida.
tasas_grupo <- function(variable) {
  est <- survey::svyby(~practica, stats::as.formula(paste0("~", variable)),
                       diseno, survey::svymean, na.rm = TRUE,
                       vartype = "ci", keep.names = FALSE)
  est <- as.data.frame(est)
  names(est)[1:4] <- c("grupo", "tasa", "li_95", "ls_95")
  est$variable <- variable
  est$n_sin_ponderar <- vapply(as.character(est$grupo), function(g) {
    sum(!is.na(datos$practica) & !is.na(datos[[variable]]) &
          as.character(datos[[variable]]) == g)
  }, integer(1))
  est[c("variable", "grupo", "n_sin_ponderar", "tasa", "li_95", "ls_95")]
}
tabla_tasas <- dplyr::bind_rows(lapply(
  c("sexo_grupo", "edad_grupo", "educacion"), tasas_grupo))
readr::write_csv(tabla_tasas, "Output/02_tasas_por_grupo.csv")

# Motivos principales declarados: p3=abandono; p4=nunca practicó.
# El 01 convirtió 99 ('No sabe') en NA. Cada motivo usa como denominador
# todas las respuestas válidas de su tipo y sexo.
motivos <- c(
  "Instalaciones u horarios", "Cansancio por trabajo/estudio",
  "Cansancio por cuidados", "Salud o edad", "Inseguridad",
  "Tiempo por cuidados", "Tiempo por trabajo/estudio", "Dinero",
  "Desgano", "Otro")

estimar_motivos <- function(columna, tipo) {
  sub <- if (columna == "barrera_abandono") {
    subset(diseno, !is.na(barrera_abandono) & !is.na(sexo_grupo))
  } else {
    subset(diseno, !is.na(barrera_nunca) & !is.na(sexo_grupo))
  }
  if (!nrow(sub$variables)) stop("Sin respuestas válidas: ", columna)
  n_grupo <- table(sub$variables$sexo_grupo)
  dplyr::bind_rows(lapply(seq_along(motivos), function(codigo) {
    sub_motivo <- sub
    sub_motivo$variables$indicador <-
      as.numeric(sub_motivo$variables[[columna]] == codigo)
    est <- survey::svyby(~indicador, ~sexo_grupo, sub_motivo,
                         survey::svymean, vartype = "ci", keep.names = FALSE)
    est <- as.data.frame(est)
    names(est)[1:4] <- c("sexo", "proporcion", "li", "ls")
    data.frame(
      tipo = tipo, sexo = as.character(est$sexo),
      n_sin_ponderar = as.integer(n_grupo[as.character(est$sexo)]),
      codigo = codigo, motivo = motivos[codigo],
      porcentaje = 100 * est$proporcion,
      li_95 = 100 * pmax(0, est$li), ls_95 = 100 * pmin(1, est$ls))
  }))
}
tabla_motivos <- dplyr::bind_rows(
  estimar_motivos("barrera_abandono", "Abandonó la práctica"),
  estimar_motivos("barrera_nunca", "Nunca practicó"))
readr::write_csv(tabla_motivos, "Output/02_motivos_por_sexo.csv")

cat("Tasa nacional ponderada:\n")
print(tasa_total)
cat("\nTasas por grupos:\n")
print(tabla_tasas)
cat("\nRespuestas válidas a motivos (sin ponderar):\n")
print(dplyr::distinct(tabla_motivos, tipo, sexo, n_sin_ponderar))
cat("Tres tablas guardadas en Output/. Las diferencias son descriptivas.\n")
