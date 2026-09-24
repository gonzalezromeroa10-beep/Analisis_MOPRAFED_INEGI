# ============================================================================
# 05 | Desigualdades cruzadas y motivos ligados al tiempo - MOPRADEF 2025
# Economía del Desarrollo: sexo x educación y práctica deportiva.
# Lectura cualitativa de las respuestas: tiempo de trabajo y cuidados.
# Ejecutar desde la raíz del .Rproj, después del script 01.
# install.packages(c("survey", "dplyr", "ggplot2", "readr", "scales"))
# ============================================================================

paquetes <- c("survey", "dplyr", "ggplot2", "readr", "scales")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) stop("Instala: ", paste(faltantes, collapse = ", "))
ruta <- "Data/analisis_df.rds"
if (!file.exists(ruta)) stop("Falta ", ruta, ". Ejecuta primero el script 01.")
datos <- readRDS(ruta)
necesarias <- c("practica", "sexo_grupo", "educacion", "barrera_abandono",
                "barrera_nunca", "fac_ele", "upm_dis", "est_dis")
faltan <- setdiff(necesarias, names(datos))
if (length(faltan)) stop("Faltan columnas: ", paste(faltan, collapse = ", "))
dir.create("Output", showWarnings = FALSE)
options(survey.lonely.psu = "adjust")

# A. Cruce sexo x educación: tasas de práctica dentro de cada combinación.
grupo_interseccion <- interaction(datos$sexo_grupo, datos$educacion,
                                  sep = " | ", drop = TRUE)
datos$sexo_educacion <- grupo_interseccion
diseno <- survey::svydesign(ids = ~upm_dis, strata = ~est_dis,
                            weights = ~fac_ele, data = datos, nest = TRUE)
est <- survey::svyby(~practica, ~sexo_educacion, diseno, survey::svymean,
                     na.rm = TRUE, vartype = "ci", keep.names = FALSE)
est <- as.data.frame(est)
names(est)[1:4] <- c("grupo", "tasa", "li_95", "ls_95")
parts <- strsplit(as.character(est$grupo), " \\| ")
est$sexo <- vapply(parts, `[`, character(1), 1)
est$educacion <- vapply(parts, `[`, character(1), 2)
est$n_sin_ponderar <- vapply(as.character(est$grupo), function(g) {
  sum(!is.na(datos$practica) & !is.na(datos$sexo_educacion) &
        as.character(datos$sexo_educacion) == g)
}, integer(1))
# Evita mostrar estimaciones inestables basadas en muy pocos casos.
est$graficable <- est$n_sin_ponderar >= 30
readr::write_csv(est, "Output/05_practica_sexo_educacion.csv")
if (any(!est$graficable)) {
  message("Se omiten del gráfico las combinaciones con menos de 30 observaciones; ",
          "ver n_sin_ponderar en el CSV.")
}

est_plot <- dplyr::filter(est, graficable)
est_plot$educacion <- factor(est_plot$educacion,
                             levels = c("Hasta primaria", "Secundaria/técnica", "Media superior", "Superior"))
grafico_cruces <- ggplot2::ggplot(est_plot,
                                  ggplot2::aes(x = educacion, y = tasa, ymin = li_95, ymax = ls_95,
                                               colour = sexo)) +
  ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.45),
                           linewidth = 0.7) +
  ggplot2::coord_flip() +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                              limits = c(0, 1)) +
  ggplot2::scale_colour_manual(values = c("Hombre" = "#245784",
                                          "Mujer" = "#B46052")) +
  ggplot2::labs(title = "Práctica deportiva por sexo y educación",
                subtitle = "Tasas ponderadas e intervalos de confianza del 95 %",
                x = NULL, y = "Porcentaje que practica", colour = "Sexo",
                caption = "Se muestran grupos con al menos 30 personas; n de cada grupo en el CSV.") +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                 panel.grid.major.y = ggplot2::element_blank(),
                 legend.position = "top")
ggplot2::ggsave("Output/05_practica_sexo_educacion.png", grafico_cruces,
                width = 10, height = 5.5, dpi = 300, bg = "white")

# B. Motivos específicos entre quienes dieron respuestas válidas a p3 o p4.
# 6: falta de tiempo por cuidados; 7: falta de tiempo por trabajo/estudio.
# Cada estimación se refiere a la razón PRINCIPAL, no a todo el tiempo usado.
estimar_tiempo <- function(columna, tipo, codigo, etiqueta) {
  sub <- if (columna == "barrera_abandono") {
    subset(diseno, !is.na(barrera_abandono) & !is.na(sexo_grupo))
  } else {
    subset(diseno, !is.na(barrera_nunca) & !is.na(sexo_grupo))
  }
  sub$variables$indicador <- as.numeric(sub$variables[[columna]] == codigo)
  est <- survey::svyby(~indicador, ~sexo_grupo, sub, survey::svymean,
                       vartype = "ci", keep.names = FALSE)
  est <- as.data.frame(est)
  names(est)[1:4] <- c("sexo", "proporcion", "li", "ls")
  n_por_sexo <- table(sub$variables$sexo_grupo)
  n_motivo <- table(factor(sub$variables$sexo_grupo[sub$variables$indicador == 1],
                           levels = levels(sub$variables$sexo_grupo)))
  data.frame(tipo = tipo, motivo = etiqueta, sexo = as.character(est$sexo),
             n_respuestas_validas = as.integer(n_por_sexo[as.character(est$sexo)]),
             n_eligio_motivo = as.integer(n_motivo[as.character(est$sexo)]),
             porcentaje = 100 * est$proporcion,
             li_95 = 100 * pmax(0, est$li), ls_95 = 100 * pmin(1, est$ls))
}

especificaciones <- list(
  c("barrera_abandono", "Abandonó", "6", "Tiempo por cuidados"),
  c("barrera_abandono", "Abandonó", "7", "Tiempo por trabajo/estudio"),
  c("barrera_nunca", "Nunca practicó", "6", "Tiempo por cuidados"),
  c("barrera_nunca", "Nunca practicó", "7", "Tiempo por trabajo/estudio"))
tabla_tiempo <- dplyr::bind_rows(lapply(especificaciones, function(x) {
  estimar_tiempo(x[1], x[2], as.integer(x[3]), x[4])
}))
# El umbral es una regla de presentación, no una prueba estadística.
tabla_tiempo$graficable <- tabla_tiempo$n_eligio_motivo >= 10
readr::write_csv(tabla_tiempo, "Output/05_motivos_tiempo_por_sexo.csv")
if (any(!tabla_tiempo$graficable)) {
  message("Motivos con menos de 10 respuestas en algún grupo se omiten del gráfico; ",
          "consultar el CSV.")
}
tiempo_plot <- dplyr::filter(tabla_tiempo, graficable)
tiempo_plot$motivo <- factor(tiempo_plot$motivo,
                             levels = c("Tiempo por cuidados",
                                        "Tiempo por trabajo/estudio"))
grafico_tiempo <- ggplot2::ggplot(tiempo_plot,
                                  ggplot2::aes(x = motivo, y = porcentaje, ymin = li_95, ymax = ls_95,
                                               colour = sexo)) +
  ggplot2::geom_pointrange(position = ggplot2::position_dodge(width = 0.45),
                           linewidth = 0.7) +
  ggplot2::coord_flip() +
  ggplot2::facet_wrap(~tipo, ncol = 1) +
  ggplot2::scale_colour_manual(values = c("Hombre" = "#245784",
                                          "Mujer" = "#B46052")) +
  ggplot2::labs(title = "Tiempo de trabajo y cuidados como motivo declarado",
                subtitle = "Porcentaje ponderado entre quienes respondieron p3 o p4",
                x = NULL, y = "Porcentaje de respuestas válidas", colour = "Sexo",
                caption = paste("IC del 95 %. Se muestran motivos con n >= 10 por sexo.",
                                "Son respuestas declaradas, no efectos causales.")) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                 panel.grid.major.y = ggplot2::element_blank(),
                 legend.position = "top")
ggplot2::ggsave("Output/05_motivos_tiempo_por_sexo.png", grafico_tiempo,
                width = 11, height = 6, dpi = 300, bg = "white")
print(est[c("grupo", "n_sin_ponderar", "tasa", "li_95", "ls_95")])
print(tabla_tiempo)
print(grafico_cruces)
print(grafico_tiempo)
cat("Resultados del script 05 guardados en Output/.\n")
