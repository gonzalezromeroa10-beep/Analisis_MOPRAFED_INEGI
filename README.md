Análisis Sociodemográfico de la Práctica Deportiva en México (MOPRADEF 2025)
📌 Presentación del Proyecto
Este repositorio contiene un pipeline analítico desarrollado en R para procesar, ponderar y visualizar los microdatos del Módulo de Práctica Deportiva y Ejercicio Físico (MOPRADEF 2025) publicado por el INEGI. El objetivo principal es examinar las tendencias de la actividad física en México, evaluando brechas sociodemográficas (como género y edad) y las motivaciones estructurales que impulsan a la población a mantenerse físicamente activa.

🛠️ Pipeline Metodológico e Infraestructura Técnica
El procesamiento de los datos se diseñó bajo los estándares de la estadística oficial mexicana, garantizando la reproducibilidad y el rigor en el manejo de muestras complejas:

Inferencia Poblacional: Incorporación y expansión del factor de expansión muestral (fac_ele) para obtener estimaciones representativas a nivel poblacional.

Procesamiento de Datos: Limpieza y transformación de variables sociodemográficas y reactivos multirrespuesta con tidyverse.

Visualización de Datos: Generación de gráficos institucionales de alta resolución con ggplot2, optimizados con paletas de colores sobrias y tipografía clara para comunicación científica y toma de decisiones.

📊 Principales Hallazgos y Visualizaciones
1. Distribución Demográfica de la Práctica Deportiva
El análisis por grupos etarios y sexo refleja cómo disminuye la constancia de la actividad física conforme avanza la edad y evidencia las brechas históricas de participación.

Gráfico generado: Outputs/distribucion_edad_genero.png

2. Motivaciones para el Ejercicio y la Actividad Física
El desglose de los reactivos múltiples (p27_1 a p27_8) permite dimensionar el peso relativo de factores como la prevención clínica, el control de peso, la estética corporal y la socialización en la decisión de ejercitarse.

Gráfico generado: Outputs/motivos_practica_deportiva.png

📂 Estructura del Repositorio
Plaintext
analisis-mopradef-inegi/
│
├── Data/               # Archivos de microdatos originales (INEGI)
├── Scripts/            # Scripts de limpieza, procesamiento y visualización en R
├── Outputs/            # Gráficos exportados en alta resolución (.png)
└── README.md           # Documentación principal del repositorio
🚀 Requisitos y Reproducibilidad
Para ejecutar este proyecto en tu entorno local, asegúrate de tener instalado R y las siguientes librerías principales:

R
install.packages("pacman")
pacman::p_load(tidyverse, ggplot2)
Clona el repositorio, asegúrate de colocar la base de datos oficial en la ruta Data/ y ejecuta los scripts en orden secuencial para replicar todo el análisis y la generación de gráficos.

Para complementar este estudio sobre el contexto de la actividad física en el país, puedes revisar este análisis en video sobre las tendencias recientes del INEGI y la actividad física en México.
