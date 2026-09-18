# =====================================================================
# Proyecto: Análisis MOPRADEF 2025 (INEGI)
# Script 01: Carga e Inspección Inicial de Datos
# =====================================================================

# 1. Instalar y cargar librerías necesarias
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, haven, readxl)

# 2. Localizar y cargar la base de datos .sav
# RStudio detecta automáticamente la ruta gracias al proyecto (.Rproj)
# Buscamos el archivo dentro de la carpeta Data/mopradef_bd_2025_sav
ruta_archivo <- list.files(
  path = "Data", 
  pattern = "\\.sav$", 
  recursive = TRUE, 
  full.names = TRUE
)

print(paste("Archivo encontrado:", ruta_archivo))

# Cargamos los datos utilizando la librería haven
mopradef_raw <- read_spss(ruta_archivo)

# 3. Vista rápida de la estructura de los datos
glimpse(mopradef_raw)

# 4. Inspeccionar las primeras columnas y nombres de variables
head(mopradef_raw, 5)