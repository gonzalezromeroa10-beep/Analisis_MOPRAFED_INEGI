# Análisis Sociodemográfico y Econométrico de la Práctica Deportiva en México (MOPRADEF 2025)

## 📌 Presentación del Proyecto
Este repositorio contiene un pipeline analítico modular desarrollado en R para procesar, ponderar, modelar y visualizar los microdatos del **Módulo de Práctica Deportiva y Ejercicio Físico (MOPRADEF)** publicado por el INEGI. El objetivo principal es examinar las tendencias de la actividad física en México, evaluando tanto las brechas sociodemográficas descriptivas como los determinantes econométricos estructurales y las desigualdades en las motivaciones de la población.

---

## 🛠️ Pipeline Metodológico e Infraestructura Técnica
El procesamiento y modelado se estructuraron en scripts secuenciales bajo los estándares oficiales para el manejo de encuestas con muestras complejas:
* **Inferencia Poblacional:** Incorporación del factor de expansión (`fac_ele`) mediante el paquete `survey` para garantizar representatividad estadística a escala nacional.
* **Procesamiento y Modelado (`Scripts/`):** Pipeline modular que abarca desde la limpieza de microdatos hasta la estimación de modelos logísticos ponderados (`svyglm`).
* **Visualización de Datos:** Generación de gráficos institucionales de alta resolución con `ggplot2` para la comunicación científica y la toma de decisiones.

---

## 📊 Módulos Analíticos y Principales Hallazgos

### 1. Estadística Descriptiva y Distribución Demográfica
* **Distribución Demográfica de la Práctica Deportiva:** Análisis por grupos etarios y sexo que expone el declive de la constancia física conforme avanza la edad y las brechas históricas de participación (`Outputs/distribucion_edad_genero.png`).
* **Motivaciones Múltiples:** Desglose de reactivos (`p27_1` a `p27_8`) para dimensionar el peso de la prevención clínica, el control de peso y la socialización (`Outputs/motivos_practica_deportiva.png`).

### 2. Modelado Econométrico y Análisis Predictivo
* **Determinantes del Motivo "Salud":** Modelo logístico ponderado para aislar el efecto de la edad, el sexo y la escolaridad sobre la probabilidad de buscar la salud preventiva.
* **Brecha de Género y Ciclo de Vida:** Confirmación de un Odds Ratio adverso para las mujeres y un declive sistemático por la edad (`Outputs/probabilidades_salud_edad_sexo.png`).
* **Forest Plot de Variables Clave:** Gráfico optimizado que aísla los efectos estructurales robustos frente al dintel de referencia (`Outputs/forest_plot_variables_clave.png`).

### 3. Segmentación Profunda y Desigualdad Educativa
* **Cruces por Nivel de Escolaridad:** Análisis desagregado de cómo varían las motivaciones y las barreras de práctica deportiva a lo largo de los estratos educativos, evaluando la estratificación social en el acceso al bienestar físico.

---

## 📂 Estructura del Repositorio
```text
analisis-mopradef-inegi/
│
├── Data/                 # Archivos de microdatos originales (INEGI)
├── Scripts/              # Pipeline modular en R:
│   ├── 01_Limpieza.R
│   ├── ...
│   ├── 04_Modelado_Estadistico_Econometrico.R
│   ├── 05_Segmentacion_Profunda_y_Desigualdad.R
│   └── 06_Forest_Plot_de_Variables_Clave.R
├── Outputs/              # Gráficos institucionales exportados en alta resolución (.png)
└── README.md             # Documentación principal del repositorio


🚀 Requisitos y Reproducibilidad
Para replicar el análisis completo en tu entorno local, instala las librerías necesarias para muestras complejas y manipulación de datos:

R
install.packages("pacman")
pacman::p_load(tidyverse, ggplot2, survey)
