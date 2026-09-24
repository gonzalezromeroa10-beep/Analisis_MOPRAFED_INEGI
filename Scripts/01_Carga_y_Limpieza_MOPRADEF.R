# ============================================================================
# 01 | Carga, validación y preparación de MOPRADEF 2025
# Ejecutar desde la raíz del proyecto .Rproj.
# Instalar una vez: install.packages(c("haven", "dplyr"))
# Salida: Data/analisis_df.rds (insumo común de los scripts 02, 03 y 04).
# ============================================================================

paquetes <- c("haven", "dplyr")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) stop("Instala estos paquetes: ", paste(faltantes, collapse = ", "))

ruta_entrada <- file.path("Data", "mopradef_bd_2025_sav", "MOPRADEF.sav")
ruta_salida <- file.path("Data", "analisis_df.rds")
if (!file.exists(ruta_entrada)) {
  stop("No se encuentra ", ruta_entrada,
       ". Abre el proyecto .Rproj y verifica la ubicación del archivo.")
}

modulo <- haven::read_sav(ruta_entrada)
necesarias <- c("llaveviv", "p1", "p3", "p4", "sexo", "edad", "niv",
                "fac_ele", "upm_dis", "est_dis")
ausentes <- setdiff(necesarias, names(modulo))
if (length(ausentes)) stop("Faltan columnas: ", paste(ausentes, collapse = ", "))
if (anyNA(modulo$llaveviv) || anyDuplicated(as.character(modulo$llaveviv))) {
  stop("La llave de vivienda está vacía o duplicada; revisa el archivo leído.")
}
if (any(!is.na(modulo$p1) & !as.numeric(modulo$p1) %in% c(1, 2))) {
  stop("p1 contiene códigos inesperados. Revisa el diccionario antes de recodificar.")
}
if (anyNA(modulo$fac_ele) || any(as.numeric(modulo$fac_ele) <= 0) ||
    anyNA(modulo$upm_dis) || anyNA(modulo$est_dis)) {
  stop("Faltan o son inválidos los pesos, UPM o estratos del diseño.")
}

# Se mantienen todas las filas. Los valores 'no sabe' y los no especificados
# quedan como NA únicamente en la variable recodificada correspondiente.
# Así p3 y p4 siguen disponibles aunque una persona no declare su edad o nivel.
analisis_df <- modulo |>
  dplyr::mutate(
    llaveviv = as.character(llaveviv),
    practica = dplyr::case_when(
      as.numeric(p1) == 1 ~ 1L,
      as.numeric(p1) == 2 ~ 0L,
      TRUE ~ NA_integer_),
    sexo_grupo = factor(as.numeric(sexo), levels = c(1, 2),
                        labels = c("Hombre", "Mujer")),
    edad_val = dplyr::if_else(as.numeric(edad) >= 12 & as.numeric(edad) <= 97,
                              as.numeric(edad), NA_real_),
    edad_grupo = cut(edad_val, breaks = c(12, 18, 30, 45, 60, Inf),
                     right = FALSE,
                     labels = c("12-17", "18-29", "30-44", "45-59", "60+")),
    educacion = dplyr::case_when(
      as.numeric(niv) %in% 0:2 ~ "Hasta primaria",
      as.numeric(niv) %in% c(3, 4, 5) ~ "Secundaria/técnica",
      as.numeric(niv) %in% c(6, 7) ~ "Media superior",
      as.numeric(niv) %in% 8:11 ~ "Superior",
      TRUE ~ NA_character_),
    educacion = factor(educacion,
                       levels = c("Hasta primaria", "Secundaria/técnica",
                                  "Media superior", "Superior")),
    barrera_abandono = dplyr::if_else(as.numeric(p3) %in% 1:10,
                                      as.numeric(p3), NA_real_),
    barrera_nunca = dplyr::if_else(as.numeric(p4) %in% 1:10,
                                   as.numeric(p4), NA_real_),
    fac_ele = as.numeric(fac_ele)
  )

# Comprobaciones antes de sobrescribir la versión preparada.
if (nrow(analisis_df) != nrow(modulo)) stop("Se perdieron observaciones.")
if (!all(c(0L, 1L) %in% analisis_df$practica)) {
  stop("No se identificaron ambas respuestas de práctica (sí y no).")
}
if (nlevels(droplevels(analisis_df$sexo_grupo)) < 2L ||
    nlevels(droplevels(analisis_df$educacion)) < 2L) {
  stop("Faltan grupos de sexo o educación; revisa las codificaciones.")
}

saveRDS(analisis_df, ruta_salida, version = 3)
cat("Archivo creado: ", ruta_salida, "\n", sep = "")
cat("Filas: ", nrow(analisis_df), "; práctica válida: ",
    sum(!is.na(analisis_df$practica)), "; edad válida: ",
    sum(!is.na(analisis_df$edad_val)), "; educación válida: ",
    sum(!is.na(analisis_df$educacion)), "\n", sep = "")
cat("Motivos válidos: abandono=", sum(!is.na(analisis_df$barrera_abandono)),
    "; nunca practicó=", sum(!is.na(analisis_df$barrera_nunca)), "\n", sep = "")
print(table(analisis_df$practica, useNA = "ifany"))
