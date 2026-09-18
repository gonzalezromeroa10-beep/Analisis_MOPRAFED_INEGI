# =====================================================================
# Proyecto: Análisis MOPRADEF 2025 (INEGI)
# Script 02: Unión de Tablas y Limpieza de Variables
# =====================================================================

pacman::p_load(tidyverse)

# 1. Unir la tabla sociodemográfica con la del módulo deportivo
mopradef_completo <- demografia_raw %>%
  inner_join(modulo_raw, by = c("viv_sel", "n_ren", "upm_dis", "est_dis"))

# 2. Verificar el éxito de la unión
print(paste("Total de registros en la base integrada:", nrow(mopradef_completo)))

# 3. Selección de variables analíticas clave
analisis_df <- mopradef_completo %>%
  select(
    viv_sel, n_ren,
    sexo,            # Género 
    edad = edad.x,   # Edad 
    niv,             # Nivel de escolaridad
    contains("p27"), # Motivos de práctica deportiva
    fac_ele          # Ponderador muestral
  )

# Vista previa de las primeras filas del dataset analítico
head(analisis_df)