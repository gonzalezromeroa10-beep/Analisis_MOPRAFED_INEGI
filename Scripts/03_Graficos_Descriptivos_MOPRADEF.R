# ============================================================================
# 03 | Gráficos descriptivos - MOPRADEF 2025
# Ejecutar desde la raíz del proyecto .Rproj después de los scripts 01 y 02.
# Instalar una vez: install.packages(c("readr", "dplyr", "ggplot2", "scales"))
# Entradas: Output/02_*.csv | Salidas: Output/03_*.png
# ============================================================================

paquetes <- c("readr", "dplyr", "ggplot2", "scales")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) stop("Instala: ", paste(faltantes, collapse = ", "))

archivos <- c("Output/02_tasas_por_grupo.csv",
              "Output/02_motivos_por_sexo.csv")
sin_archivo <- archivos[!file.exists(archivos)]
if (length(sin_archivo)) {
  stop("Faltan resultados del script 02: ", paste(sin_archivo, collapse = ", "))
}
tasas <- readr::read_csv(archivos[1], show_col_types = FALSE)
motivos <- readr::read_csv(archivos[2], show_col_types = FALSE)
if (!all(c("variable", "grupo", "tasa", "li_95", "ls_95") %in% names(tasas)) ||
    !all(c("tipo", "sexo", "motivo", "porcentaje", "n_sin_ponderar") %in% names(motivos))) {
  stop("Las columnas CSV no coinciden con el script 02 actualizado.")
}

# 1. Tasas ponderadas. Incluye todas las categorías, también las referencias
# del modelo: Hombre, 12-17 años y Hasta primaria.
etiquetas_grupo <- c("sexo_grupo" = "Sexo", "edad_grupo" = "Edad",
                     "educacion" = "Educación")
tasas$variable <- factor(unname(etiquetas_grupo[tasas$variable]),
                         levels = c("Sexo", "Edad", "Educación"))
if (anyNA(tasas$variable)) stop("Se encontraron grupos inesperados en la tabla de tasas.")
tasas$grupo <- factor(tasas$grupo,
                      levels = c("Superior", "Media superior", "Secundaria/técnica",
                                 "Hasta primaria", "60+", "45-59", "30-44", "18-29",
                                 "12-17", "Mujer", "Hombre"))
grafico_tasas <- ggplot2::ggplot(
  tasas, ggplot2::aes(x = grupo, y = tasa, ymin = li_95, ymax = ls_95)) +
  ggplot2::geom_pointrange(colour = "#245784", linewidth = 0.75) +
  ggplot2::coord_flip() +
  ggplot2::facet_grid(variable ~ ., scales = "free_y", space = "free_y") +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                              limits = c(0, 1)) +
  ggplot2::labs(
    title = "¿Quiénes practican deporte o ejercicio en su tiempo libre?",
    subtitle = "Tasas ponderadas e intervalos de confianza del 95 % · MOPRADEF 2025",
    x = NULL, y = "Porcentaje que practica",
    caption = "Cada punto es la tasa del grupo; las líneas muestran la incertidumbre muestral.") +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                 strip.text.y = ggplot2::element_text(face = "bold"),
                 plot.title = ggplot2::element_text(face = "bold", size = 16),
                 plot.caption = ggplot2::element_text(hjust = 0))
ggplot2::ggsave("Output/03_tasas_por_grupo.png", grafico_tasas,
                width = 11, height = 7, dpi = 300, bg = "white")

# 2. Motivos: gráficos separados con una escala común para compararlos.
# Los porcentajes de las 10 razones suman 100 dentro de cada tipo y sexo.
colores <- c("Hombre" = "#245784", "Mujer" = "#B46052")
maximo <- max(40, ceiling(max(motivos$porcentaje, na.rm = TRUE) / 10) * 10)

dibujar_motivos <- function(tipo_elegido, titulo, codigo, salida) {
  sub <- dplyr::filter(motivos, .data$tipo == tipo_elegido)
  if (nrow(sub) != 20L || !setequal(sub$sexo, names(colores))) {
    stop("Se esperaban 10 motivos para cada sexo en: ", tipo_elegido)
  }
  # Orden según el porcentaje promedio de ambos sexos dentro de este gráfico.
  orden <- sub |>
    dplyr::group_by(motivo) |>
    dplyr::summarise(promedio = mean(porcentaje), .groups = "drop") |>
    dplyr::arrange(promedio) |>
    dplyr::pull(motivo)
  sub$motivo <- factor(sub$motivo, levels = orden)
  grafico <- ggplot2::ggplot(sub,
                             ggplot2::aes(x = motivo, y = porcentaje, fill = sexo)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.74),
                      width = 0.72) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(limits = c(0, maximo),
                                breaks = seq(0, maximo, by = 10),
                                expand = ggplot2::expansion(mult = c(0, 0.02))) +
    ggplot2::scale_fill_manual(values = colores) +
    ggplot2::labs(
      title = titulo,
      subtitle = "Porcentaje ponderado por sexo · motivo principal declarado",
      x = NULL, y = "Porcentaje de respuestas válidas", fill = NULL,
      caption = paste0(codigo, "; excluye 'No sabe'. Fuente: MOPRADEF 2025.")) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   plot.title = ggplot2::element_text(face = "bold", size = 15),
                   plot.subtitle = ggplot2::element_text(size = 10),
                   axis.text.y = ggplot2::element_text(size = 11),
                   legend.position = "top",
                   legend.justification = "left",
                   legend.text = ggplot2::element_text(size = 9),
                   legend.key.size = grid::unit(0.42, "cm"),
                   legend.spacing.x = grid::unit(0.08, "cm"),
                   plot.caption = ggplot2::element_text(hjust = 0, size = 8),
                   plot.margin = ggplot2::margin(8, 12, 8, 8))
  ggplot2::ggsave(salida, grafico, width = 11, height = 8,
                  dpi = 300, bg = "white")
  grafico
}

grafico_abandono <- dibujar_motivos(
  "Abandonó la práctica", "Motivos para abandonar la práctica deportiva",
  "Pregunta p3", "Output/03_motivos_abandono.png")
grafico_nunca <- dibujar_motivos(
  "Nunca practicó", "Motivos para nunca haber practicado deporte",
  "Pregunta p4", "Output/03_motivos_nunca_practico.png")

print(grafico_tasas)
print(grafico_abandono)
print(grafico_nunca)
cat("Tres gráficos guardados en Output/.\n")
