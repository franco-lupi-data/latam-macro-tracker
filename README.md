# LatAm Macro Tracker 🇦🇷

> Herramienta automatizada de monitoreo macroeconómico y riesgo soberano de grado B2B, desarrollada en R y Shiny.

[![R](https://img.shields.io/badge/R-4.6%2B-blue.svg)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-Web%20App-orange.svg)](https://shiny.posit.co/)
[![Deployment](https://img.shields.io/badge/Status-Online-success.svg)](https://www.shinyapps.io/)

## 📊 Descripción del Proyecto
**LatAm Macro Tracker** es un dashboard analítico interactivo diseñado para el seguimiento en tiempo real de variables críticas de la economía argentina y su correlación con el riesgo financiero internacional. 

La plataforma está orientada a analistas de riesgos, mesas de dinero y consultores financieros que requieren tableros rápidos, resilientes y con actualización automática sin fricciones operativas.

👉 **[Ver Aplicación en Vivo en Shinyapps.io](https://[TU-USUARIO].shinyapps.io/latam_macro_tracker/)**

---

## 🚀 Características Principales
*   **KPI Cards Dinámicas:** Panel superior de métricas clave con el último valor y período disponible para lectura ejecutiva instantánea.
*   **Integración de Datos Oficiales:** Conexión directa mediante APIs públicas con el **INDEC** (IPC Nivel General) y el **BCRA** (Tipo de Cambio Mayorista Promedio).
*   **Arquitectura Resiliente (Fail-Safe):** Sistema híbrido de ingesta de datos con manejo de errores (`tryCatch`, `timeouts`) y respaldo local en CSV para indicadores de riesgo financiero (EMBI), garantizando un *uptime* del 100%.
*   **Visualización Interactiva:** Gráficos de alta fidelidad construidos con `Plotly`, con ejes sincronizados, tooltips detallados y solapas temáticas independientes.

---

## 🛠️ Stack Tecnológico
*   **Lenguaje:** R
*   **Framework Web:** Shiny
*   **Visualización:** Plotly, HTML/CSS nativo
*   **Manipulación y Consumo de Datos:** `dplyr`, `httr`, `jsonlite`
*   **Infraestructura:** Desplegado y alojado en la nube mediante `rsconnect` y `shinyapps.io`.

---

## ⚙️ Arquitectura y Decisiones de Ingeniería
1.  **Gestión del *Reporting Lag*:** Los datos mensuales y diarios se procesan y normalizan asincrónicamente mediante `full_join` por fechas estandarizadas de inicio de mes, resolviendo desfasajes temporales de publicación.
2.  **Estrategia Híbrida para el Riesgo País (EMBI):** Ante la volatilidad e intermitencia en los metadatos de las APIs públicas para series financieras secundarias, el sistema implementa un mecanismo de respaldos locales (*fallback*) en CSV que previene caídas totales de la aplicación.

---

## 💻 Cómo Ejecutar el Proyecto Localmente

Si deseas clonar y correr este repositorio en tu entorno local de RStudio:

1. Clona el repositorio:
   ```bash
   git clone [https://github.com/](https://github.com/)[TU-USUARIO]/latam-macro-tracker.git