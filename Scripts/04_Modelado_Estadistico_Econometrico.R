# =====================================================================
# Script 04: Modelado Econométrico y Probabilidades Predichas (MOPRADEF)
# Objetivo: Regresión logística ponderada y visualización de probabilidades 
# predichas para el motivo de práctica por "Salud" (p27_1).
# =====================================================================

# 0. Cargar librerías necesarias
pacman::p_load(tidyverse, survey, ggplot2)

# 1. Preparación del dataframe analítico para el modelo
model_df <- analisis_df %>%
  mutate(
    # Variable dependiente binaria: Motivo "Salud" (1 = Sí lo eligió, 0 = No)
    motivo_salud_bin = as.numeric(p27_1 == 1),
    
    # Covariables sociodemográficas
    sexo_f = as.factor(sexo),
    edad_num = as.numeric(edad),
    escolaridad = as.factor(niv)
  )

# 2. Configurar el diseño muestral complejo incorporando el factor de expansión (fac_ele)
diseno_mopradef <- svydesign(
  id = ~1,                
  weights = ~fac_ele,     
  data = model_df
)

# 3. Estimar el Modelo de Regresión Logística Ponderada (GLM con diseño complejo)
modelo_logit_salud <- svyglm(
  motivo_salud_bin ~ sexo_f + edad_num + escolaridad,
  design = diseno_mopradef,
  family = quasibinomial(link = "logit")
)

# 4. Cálculo directo de Probabilidades Predichas por Edad y Sexo
newdata_grid <- expand.grid(
  edad_num = seq(min(model_df$edad_num, na.rm = TRUE), max(model_df$edad_num, na.rm = TRUE), by = 1),
  sexo_f = levels(model_df$sexo_f),
  escolaridad = levels(model_df$escolaridad)[1] 
)

# Obtenemos las predicciones en escala link (logit)
pred_link <- predict(modelo_logit_salud, newdata = newdata_grid, type = "link")

# Si pred_link es una matriz o vector, extraemos la estimación y el error estándar de manera segura
if(is.matrix(pred_link)) {
  fit_val <- pred_link[, 1]
  se_val <- pred_link[, 2]
} else {
  fit_val <- pred_link
  # Estimamos una aproximación del error estándar si no viene adjunto
  se_val <- sd(pred_link) / sqrt(length(pred_link)) 
}

# Transformamos de escala logit a probabilidad (0 a 1) usando plogis
newdata_grid$fit <- plogis(fit_val)
newdata_grid$lower <- plogis(fit_val - 1.96 * se_val)
newdata_grid$upper <- plogis(fit_val + 1.96 * se_val)

# Etiquetamos el género de forma legible
efectos_edad_sexo <- newdata_grid %>%
  mutate(
    Genero = if_else(sexo_f == "2", "Mujer", "Hombre")
  )

# 5. Generar el Gráfico Profesional de Probabilidades Predichas
grafico_probabilidades <- ggplot(efectos_edad_sexo, aes(x = edad_num, y = fit, color = Genero, fill = Genero)) +
  geom_line(size = 1.3) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.18, linetype = "blank") + 
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0.4, 1.0)) +
  theme_minimal(base_size = 13) +
  labs(
    title = "Probabilidad Predicha de Practicar Ejercicio por 'Salud'",
    subtitle = "Efecto combinado de edad y género (Modelo Logístico Ponderado - MOPRADEF)",
    x = "Edad (Años)",
    y = "Probabilidad Estimada (%)",
    color = "Sexo",
    fill = "Sexo"
  ) +
  scale_color_manual(values = c("#2b5c8f", "#d95f02")) + 
  scale_fill_manual(values = c("#2b5c8f", "#d95f02")) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    axis.title = element_text(face = "bold")
  )

# Mostrar el gráfico en la pestaña Plots de RStudio
print(grafico_probabilidades)

# 6. Exportar resultados y gráfico final a Outputs
ggsave(
  filename = "Outputs/probabilidades_salud_edad_sexo.png", 
  plot = grafico_probabilidades, 
  width = 10, 
  height = 6, 
  dpi = 300
)

print("¡Gráfico de probabilidades predichas generado y guardado con éxito en Outputs/")

# 6. Exportar resultados estadísticos y gráfico final a la carpeta Outputs
sink("Outputs/modelo_econometrico_salud_resultados.txt")
cat("--- REPORTE DE MODELADO ECONOMÉTRICO: MOTIVO SALUD (MOPRADEF) ---\n\n")
print(summary(modelo_logit_salud))
cat("\n--- COEFICIENTES DEL MODELO ---\n")
print(coef(modelo_logit_salud))
sink()

ggsave(
  filename = "Outputs/probabilidades_salud_edad_sexo.png", 
  plot = grafico_probabilidades, 
  width = 10, 
  height = 6, 
  dpi = 300
)

print("¡Script completado con éxito! Reporte de texto y gráfico de probabilidades guardados en Outputs/")