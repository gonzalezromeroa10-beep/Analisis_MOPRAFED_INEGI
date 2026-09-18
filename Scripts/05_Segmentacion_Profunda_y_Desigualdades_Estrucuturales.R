# =====================================================================
# Script 05: Segmentación Profunda por Nivel Educativo y Motivos (MOPRADEF)
# Objetivo: Analizar cómo varían los distintos motivos deportivos según la escolaridad
# =====================================================================

pacman::p_load(tidyverse, survey)

# 1. Preparación del dataframe para evaluar múltiples motivos y escolaridad
segmentacion_df <- analisis_df %>%
  mutate(
    escolaridad = as.factor(niv),
    motivo_salud  = as.numeric(p27_1 == 1), # Motivo: Salud
    motivo_diver  = as.numeric(p27_2 == 1), # Motivo: Divertirse / pasar el rato
    motivo_forma  = as.numeric(p27_3 == 1)  # Motivo: Ponerse en forma
  )

# 2. Configurar el diseño muestral complejo con el factor de expansión
diseno_completo <- svydesign(
  id = ~1,                
  weights = ~fac_ele,     
  data = segmentacion_df
)

# 3. Calcular la proporción ponderada de cada motivo según el nivel de escolaridad
perfil_escolar_salud <- svyby(~motivo_salud, ~escolaridad, diseno_completo, svymean, na.rm = TRUE)
perfil_escolar_diver <- svyby(~motivo_diver, ~escolaridad, diseno_completo, svymean, na.rm = TRUE)

print("=== PROPORCIÓN DE MOTIVO 'SALUD' SEGÚN ESCOLARIDAD ===")
print(perfil_escolar_salud)

print("=== PROPORCIÓN DE MOTIVO 'DIVERSIÓN' SEGÚN ESCOLARIDAD ===")
print(perfil_escolar_diver)

# 4. Exportar los resultados de segmentación a la carpeta Outputs
sink("Outputs/segmentacion_escolaridad_motivos.txt")
cat("--- ANÁLISIS DE SEGMENTACIÓN PROFUNDA: MOTIVOS POR ESCOLARIDAD (MOPRADEF) ---\n\n")
cat("1. Motivo: SALUD\n")
print(perfil_escolar_salud)
cat("\n2. Motivo: DIVERSIÓN\n")
print(perfil_escolar_diver)
sink()

print("¡Segmentación profunda por escolaridad ejecutada y guardada en Outputs/")
