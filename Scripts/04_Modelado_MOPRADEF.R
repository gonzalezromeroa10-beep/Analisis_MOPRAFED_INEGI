# ============================================================================
# 04 | Asociaciones con la práctica deportiva en tiempo libre - MOPRADEF 2025
# Ejecutar desde la raíz del proyecto .Rproj después del script 01.
# Paquetes: install.packages(c("dplyr", "survey", "ggplot2", "readr"))
# Entrada: Data/analisis_df.rds | Salidas: Output/04_*
# ============================================================================

paquetes <- c("dplyr", "survey", "ggplot2", "readr")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) stop("Instala: ", paste(faltantes, collapse = ", "))

ruta <- file.path("Data", "analisis_df.rds")
if (!file.exists(ruta)) stop("No se encuentra ", ruta,
                             ". Ejecuta primero Scripts/01_Carga_y_Limpieza_MOPRADEF.R.")
dir.create("Output", showWarnings = FALSE)

base <- readRDS(ruta)
necesarias <- c("practica", "sexo_grupo", "edad_grupo", "educacion",
                "fac_ele", "upm_dis", "est_dis")
ausentes <- setdiff(necesarias, names(base))
if (length(ausentes)) stop("Faltan columnas: ", paste(ausentes, collapse = ", "))
# Casos completos del modelo; la base del 01 permanece sin modificar.
datos <- base |>
  dplyr::filter(!is.na(practica), !is.na(sexo_grupo), !is.na(edad_grupo),
                !is.na(educacion), !is.na(fac_ele), fac_ele > 0,
                !is.na(upm_dis), !is.na(est_dis)) |>
  droplevels()

cat("Observaciones originales:", nrow(base),
    "; observaciones del modelo:", nrow(datos), "\n")
for (variable in c("practica", "sexo_grupo", "edad_grupo", "educacion")) {
  cat("\n", variable, ":\n", sep = "")
  print(table(datos[[variable]], useNA = "ifany"))
}
if (!nrow(datos) || any(vapply(datos[c("sexo_grupo", "edad_grupo", "educacion")],
                               nlevels, integer(1)) < 2L)) {
  stop("Faltan grupos con datos para estimar el modelo; revisa las tablas anteriores.")
}

# Incorpora estratos, unidades primarias de muestreo y factor de la persona.
options(survey.lonely.psu = "adjust")
diseno <- survey::svydesign(ids = ~upm_dis, strata = ~est_dis,
                            weights = ~fac_ele, data = datos, nest = TRUE)
modelo <- survey::svyglm(practica ~ sexo_grupo + edad_grupo + educacion,
                         design = diseno, family = quasibinomial())
print(summary(modelo))
saveRDS(modelo, "Output/04_modelo_encuesta.rds")

# OR ajustados e intervalos de confianza del 95 %.
beta <- stats::coef(modelo)
ic <- stats::confint(modelo)
resultado <- data.frame(termino = names(beta), OR = exp(beta),
                        li_95 = exp(ic[, 1]), ls_95 = exp(ic[, 2]),
                        row.names = NULL)
readr::write_csv(resultado, "Output/04_odds_ratios.csv")
print(resultado)

# Etiquetas explicitas: las comparaciones siempre usan el mismo grupo de
# referencia dentro de cada variable. El intercepto no se grafica.
etiquetas <- c(
  "sexo_grupoMujer" = "Mujer (ref.: hombre)",
  "edad_grupo18-29" = "18–29 años (ref.: 12–17)",
  "edad_grupo30-44" = "30–44 años (ref.: 12–17)",
  "edad_grupo45-59" = "45–59 años (ref.: 12–17)",
  "edad_grupo60+" = "60+ años (ref.: 12–17)",
  "educacionSecundaria/técnica" = "Secundaria/técnica (ref.: hasta primaria)",
  "educacionMedia superior" = "Media superior (ref.: hasta primaria)",
  "educacionSuperior" = "Superior (ref.: hasta primaria)"
)
grupos <- c("Sexo", rep("Edad", 4), rep("Educación", 3))
grafico_datos <- resultado |>
  dplyr::filter(termino != "(Intercept)") |>
  dplyr::mutate(
    etiqueta = unname(etiquetas[termino]),
    grupo = factor(unname(grupos[match(termino, names(etiquetas))]),
                   levels = c("Sexo", "Edad", "Educación")),
    etiqueta = factor(etiqueta, levels = rev(unname(etiquetas))),
    cruza_uno = li_95 <= 1 & ls_95 >= 1
  )
if (anyNA(grafico_datos$grupo) || anyNA(grafico_datos$etiqueta))
  stop("El modelo devolvió términos inesperados; revisa sus niveles.")

grafico <- ggplot2::ggplot(grafico_datos, ggplot2::aes(x = OR, y = etiqueta)) +
  ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                      linewidth = 0.6, colour = "#8795A5") +
  ggplot2::geom_segment(ggplot2::aes(x = li_95, xend = ls_95,
                                     yend = etiqueta, colour = cruza_uno),
                        linewidth = 0.9) +
  ggplot2::geom_point(ggplot2::aes(colour = cruza_uno), size = 2.8) +
  ggplot2::facet_grid(grupo ~ ., scales = "free_y", space = "free_y",
                      switch = "y") +
  ggplot2::scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4)) +
  ggplot2::scale_colour_manual(values = c(`FALSE` = "#245784",
                                          `TRUE` = "#8795A5"), guide = "none") +
  ggplot2::labs(
    title = "Brechas en la práctica deportiva",
    subtitle = "Odds ratios ajustados · MOPRADEF 2025 · México",
    x = "Odds ratio (escala logarítmica; línea discontinua = 1)", y = NULL,
    caption = paste("Resultado: práctica de deporte o ejercicio en tiempo libre.",
                    "IC del 95 %; asociaciones, no efectos causales.")) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    strip.placement = "outside",
    strip.text.y.left = ggplot2::element_text(angle = 0, face = "bold"),
    plot.title = ggplot2::element_text(face = "bold", size = 17),
    axis.text.y = ggplot2::element_text(colour = "#263746"),
    plot.caption = ggplot2::element_text(hjust = 0)
  )
ggplot2::ggsave("Output/04_forest_plot.png", plot = grafico,
                width = 11, height = 6.5, dpi = 300, bg = "white")
ggplot2::ggsave("Output/04_forest_plot.pdf", plot = grafico,
                width = 11, height = 6.5, bg = "white")
print(grafico)
cat("Archivos generados en Output/.\n")
