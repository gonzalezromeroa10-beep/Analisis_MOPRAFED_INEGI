# =====================================================================
# Proyecto: Análisis MOPRADEF 2025 (INEGI)
# Script 03: Análisis Descriptivo Ponderado y Gráficos (Eje X Mejorado)
# =====================================================================

pacman::p_load(tidyverse, ggplot2)

# 1. Asegurar formato de variables
analisis_grafico_df <- analisis_df %>%
  mutate(
    sexo = as.factor(sexo),
    edad = as.numeric(edad)
  )

# 2. Generación de gráfico con marcas personalizadas en el eje X
grafico_edad_genero <- ggplot(analisis_grafico_df, aes(x = edad, fill = sexo, color = sexo)) +
  geom_density(alpha = 0.4, weights = analisis_grafico_df$fac_ele, size = 1) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Distribución de la Población Deportiva por Edad y Género",
    subtitle = "Estimación ponderada con microdatos del MOPRADEF 2025 (INEGI)",
    x = "Edad",
    y = "Densidad Poblacional Ponderada",
    fill = "Género",
    color = "Género"
  ) +
  # Forzar los cortes (breaks) en el eje X cada 5 o 10 años para mayor detalle
  scale_x_continuous(breaks = seq(15, 90, by = 5)) +
  scale_fill_manual(values = c("#1f78b4", "#33a02c"), labels = c("Hombre", "Mujer")) +
  scale_color_manual(values = c("#1f78b4", "#33a02c"), labels = c("Hombre", "Mujer")) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, vjust = 0.5) # Asegura que los números se lean bien
  )

# Mostrar el gráfico en la pestaña Plots
print(grafico_edad_genero)

# 3. Guardar la visualización actualizada en Outputs
ggsave(
  filename = "Outputs/distribucion_edad_genero.png", 
  plot = grafico_edad_genero, 
  width = 10, 
  height = 5, 
  dpi = 300
)

print("¡Gráfico con escala optimizada guardado con éxito!")

# =====================================================================
# Adenda Script 03: Análisis de Motivos de Práctica Deportiva (p27_*)
# =====================================================================

pacman::p_load(tidyverse, ggplot2)

# 1. Inspeccionar los nombres y etiquetas de las variables p27 para entender su estructura
# (Recordemos que vienen con metadatos de SPSS gracias a 'haven')
print("Estructura de las variables p27 en el dataset:")
glimpse(analisis_df %>% select(contains("p27")))

# 2. Transformar y calcular la proporción ponderada de cada motivo
# Nota: En los catálogos del INEGI, típicamente '1' significa que SÍ es un motivo.
# Vamos a convertir las columnas p27 a formato largo (long format) para facilitar el gráfico.

motivos_long <- analisis_df %>%
  select(viv_sel, n_ren, fac_ele, contains("p27")) %>%
  pivot_longer(
    cols = contains("p27"),
    names_to = "motivo_code",
    values_to = "resp"
  ) %>%
  # Filtramos las respuestas afirmativas (ajusta el valor si el INEGI usa otra codificación, ej: 1)
  # O podemos convertir la etiqueta de haven a texto legible:
  mutate(
    resp_label = as_factor(resp)
  )

# Vista previa de la transformación
head(motivos_long)

# 3. Agregación ponderada de los principales motivos de práctica
# Calculamos cuántas personas (población expandida) respaldan cada motivo
resumen_motivos <- motivos_long %>%
  filter(resp_label %in% c("Sí", "Si", 1)) %>% # Filtro robusto para respuestas afirmativas
  group_by(motivo_code) %>%
  summarise(
    poblacion_total = sum(fac_ele, na.rm = TRUE)
  ) %>%
  mutate(
    porcentaje = (poblacion_total / sum(poblacion_total)) * 100
  ) %>%
  arrange(desc(poblacion_total))

print("Resumen ponderado de motivos:")
print(resumen_motivos)

# 4. Gráfico de barras horizontal para los motivos principales
grafico_motivos <- ggplot(resumen_motivos, aes(x = reorder(motivo_code, porcentaje), y = porcentaje)) +
  geom_col(fill = "#2b5c8f", width = 0.7) +
  coord_flip() + # Barras horizontales para mayor legibilidad de las etiquetas
  theme_minimal(base_size = 12) +
  labs(
    title = "Principales Motivos de Práctica Deportiva o Ejercicio",
    subtitle = "Estimación porcentual ponderada con microdatos MOPRADEF 2025 (INEGI)",
    x = "Motivo (Variables P27)",
    y = "Porcentaje Estimado de la Población (%)"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.major.y = element_blank()
  )

# Mostrar el gráfico en la pestaña Plots
print(grafico_motivos)

# Guardar en la carpeta Outputs
ggsave(
  filename = "Outputs/motivos_practica_deportiva.png", 
  plot = grafico_motivos, 
  width = 9, 
  height = 5, 
  dpi = 300
)

print("¡Gráfico de motivos guardado con éxito en Outputs!")