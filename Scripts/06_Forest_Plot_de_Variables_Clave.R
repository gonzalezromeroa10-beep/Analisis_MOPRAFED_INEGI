# =====================================================================
# Script 06 (Corrección de Ejes): Forest Plot de Variables Clave
# Objetivo: Visualizar correctamente los OR de Sexo y Edad
# =====================================================================

# 3 y 4. Generar el Forest Plot con la escala correcta en el eje X
grafico_coeficientes_limpio <- ggplot(or_plot_df, aes(x = reorder(Variable_Label, OR), y = OR)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", size = 0.8) + # Línea de referencia (OR = 1)
  geom_pointrange(aes(ymin = CI_lower, ymax = CI_upper), color = "#2b5c8f", size = 1, fatten = 4) +
  coord_flip() + # Voltear para barras horizontales
  scale_y_continuous(limits = c(0.6, 1.1), breaks = c(0.6, 0.7, 0.8, 0.9, 1.0, 1.1)) + # Escala amplia que sí incluye a ambos
  theme_minimal(base_size = 13) +
  labs(
    title = "Factores Determinantes del Motivo 'Salud' (Odds Ratios)",
    subtitle = "Modelo Logístico Ponderado MOPRADEF - Efectos Principales (IC al 95%)",
    x = "",
    y = "Odds Ratio Estimado (Escala Logarítmica)"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(size = 12, face = "bold")
  )

# Mostrar el gráfico corregido en RStudio
print(grafico_coeficientes_limpio)

# Guardar la imagen corregida en Outputs
ggsave(
  filename = "Outputs/forest_plot_variables_clave.png", 
  plot = grafico_coeficientes_limpio, 
  width = 9, 
  height = 4.5, 
  dpi = 300
)

print("¡Forest plot corregido y guardado con éxito en Outputs/")