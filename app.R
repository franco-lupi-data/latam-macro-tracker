library(shiny)
library(plotly)
library(dplyr)
library(httr)
library(jsonlite)

options(repos = c(CRAN = "https://cloud.r-project.org"))

# --- 1. MOTOR DE DATOS ROBUSTO Y BLINDADO ---
descargar_serie <- function(id_serie, fecha_inicio = "2020-01-01") {
  url <- paste0("https://apis.datos.gob.ar/series/api/series/?ids=", id_serie, "&start_date=", fecha_inicio, "&limit=5000&format=json")
  
  resultado <- tryCatch({
    respuesta <- GET(url, timeout(15))
    if (status_code(respuesta) != 200) return(NULL)
    
    contenido <- content(respuesta, "text", encoding = "UTF-8")
    datos_json <- fromJSON(contenido)
    if (is.null(datos_json$data) || length(datos_json$data) == 0) return(NULL)
    
    df <- as.data.frame(datos_json$data)
    df$V1 <- as.Date(df$V1)
    df$V2 <- as.numeric(df$V2)
    return(df)
  }, error = function(e) {
    return(NULL)
  })
  
  return(resultado)
}

# 1. Descarga IPC (Mensual)
ipc <- descargar_serie("148.3_INIVELNAL_DICI_M_26", fecha_inicio = "2020-01-01")
if (!is.null(ipc)) {
  colnames(ipc) <- c("Fecha", "IPC_Nivel_General")
} else {
  ipc <- data.frame(Fecha = as.Date(character()), IPC_Nivel_General = numeric())
}

# 2. Descarga Tipo de Cambio Mayorista (Diario -> Mensualizado)
tc_diario <- descargar_serie("168.1_T_CAMBI500_D_0_0_17", fecha_inicio = "2020-01-01")
if (!is.null(tc_diario)) {
  colnames(tc_diario) <- c("Fecha", "TC_Mayorista_Diario")
  tc_mensual <- tc_diario %>%
    filter(!is.na(Fecha)) %>%
    mutate(Fecha = as.Date(paste0(format(Fecha, "%Y-%m"), "-01"), format = "%Y-%m-%d")) %>%
    group_by(Fecha) %>%
    summarise(Tipo_Cambio_Mayorista_Prom = mean(TC_Mayorista_Diario, na.rm = TRUE))
} else {
  tc_mensual <- data.frame(Fecha = as.Date(character()), Tipo_Cambio_Mayorista_Prom = numeric())
}

# 3. Consolidación base (IPC + TC)
datos_macro <- full_join(ipc, tc_mensual, by = "Fecha") %>%
  arrange(Fecha)

# 4. Estrategia Híbrida para EMBI: API con fallback a CSV local
embi_diario <- descargar_serie("43.1_EMBI_ARG_0_0_21", fecha_inicio = "2020-01-01")
embi_mensual <- NULL

if (!is.null(embi_diario) && nrow(embi_diario) > 0) {
  colnames(embi_diario) <- c("Fecha", "EMBI_Diario")
  embi_mensual <- embi_diario %>%
    filter(!is.na(Fecha)) %>%
    mutate(Fecha = as.Date(paste0(format(Fecha, "%Y-%m"), "-01"), format = "%Y-%m-%d")) %>%
    group_by(Fecha) %>%
    summarise(EMBI_Promedio = mean(EMBI_Diario, na.rm = TRUE))
} else if (file.exists("embi_historico.csv")) {
  # Si la API falla, levantamos el CSV local de respaldo
  embi_local <- read.csv("embi_historico.csv")
  embi_local$Fecha <- as.Date(embi_local$Fecha)
  embi_mensual <- embi_local
}

if (!is.null(embi_mensual) && nrow(embi_mensual) > 0) {
  datos_macro <- full_join(datos_macro, embi_mensual, by = "Fecha") %>% arrange(Fecha)
} else {
  datos_macro$EMBI_Promedio <- NA
}


# --- 2. INTERFAZ DE USUARIO (UI) ---
ui <- fluidPage(
  titlePanel("LatAm Macro Tracker — Monitor Económico y Financiero"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Panel de Control"),
      p("Herramienta automatizada de seguimiento macroeconómico y riesgo soberano."),
      hr(),
      helpText("Fuentes: INDEC / BCRA / Backup Local (Actualizado vía API)."),
      hr(),
      h4("Exportación"),
      p("Descargá la base de datos consolidada."),
      downloadButton("download_csv", "Descargar CSV", class = "btn-primary w-100"),
      tags$hr(),
      tags$small("Desarrollado para consultoría financiera y gestión de riesgos.")
    ),
    
    mainPanel(
      width = 9,
      
      # --- BLOQUE DE TARJETAS KPI ---
      fluidRow(
        column(4,
               div(style = "background-color: #f8f9fa; padding: 15px; border-left: 5px solid #2c3e50; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 15px;",
                   h5("Último TC Mayorista", style = "color: #7f8c8d; margin-top: 0; font-weight: 600; font-size: 14px;"),
                   h4(textOutput("kpi_tc"), style = "color: #2c3e50; font-weight: bold; margin-bottom: 0;")
               )
        ),
        column(4,
               div(style = "background-color: #f8f9fa; padding: 15px; border-left: 5px solid #e74c3c; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 15px;",
                   h5("Último IPC General", style = "color: #7f8c8d; margin-top: 0; font-weight: 600; font-size: 14px;"),
                   h4(textOutput("kpi_ipc"), style = "color: #e74c3c; font-weight: bold; margin-bottom: 0;")
               )
        ),
        column(4,
               div(style = "background-color: #f8f9fa; padding: 15px; border-left: 5px solid #e67e22; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 15px;",
                   h5("Último EMBI (Promedio)", style = "color: #7f8c8d; margin-top: 0; font-weight: 600; font-size: 14px;"),
                   h4(textOutput("kpi_embi"), style = "color: #e67e22; font-weight: bold; margin-bottom: 0;")
               )
        )
      ),
      # ----------------------------
      
      tabsetPanel(
        tabPanel("Tipo de Cambio Mayorista", 
                 br(),
                 plotlyOutput("plot_tc", height = "450px")
        ),
        tabPanel("IPC - Nivel General", 
                 br(),
                 plotlyOutput("plot_ipc", height = "450px")
        ),
        tabPanel("Riesgo País (EMBI)", 
                 br(),
                 plotlyOutput("plot_embi", height = "450px")
        )
      )
    )
  )
)


# --- 3. LÓGICA DEL SERVIDOR (SERVER) ---
server <- function(input, output, session) {
  
  output$kpi_tc <- renderText({
    df_valid <- datos_macro %>% filter(!is.na(Tipo_Cambio_Mayorista_Prom))
    if(nrow(df_valid) > 0) {
      ultimo <- tail(df_valid, 1)
      paste0("$ ", format(round(ultimo$Tipo_Cambio_Mayorista_Prom, 2), nsmall = 2, big.mark = ".", decimal.mark = ","), 
             " (", format(ultimo$Fecha, "%b %Y"), ")")
    } else { "Sin datos" }
  })
  
  output$kpi_ipc <- renderText({
    df_valid <- datos_macro %>% filter(!is.na(IPC_Nivel_General))
    if(nrow(df_valid) > 0) {
      ultimo <- tail(df_valid, 1)
      paste0(format(round(ultimo$IPC_Nivel_General, 2), nsmall = 2, big.mark = ".", decimal.mark = ","), 
             " (", format(ultimo$Fecha, "%b %Y"), ")")
    } else { "Sin datos" }
  })
  
  output$kpi_embi <- renderText({
    if("EMBI_Promedio" %in% names(datos_macro)) {
      df_valid <- datos_macro %>% filter(!is.na(EMBI_Promedio))
      if(nrow(df_valid) > 0) {
        ultimo <- tail(df_valid, 1)
        return(paste0(round(ultimo$EMBI_Promedio, 0), " pb (", format(ultimo$Fecha, "%b %Y"), ")"))
      }
    }
    return("No disponible")
  })
  
  output$plot_tc <- renderPlotly({
    plot_ly(datos_macro, x = ~Fecha, y = ~Tipo_Cambio_Mayorista_Prom, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#2c3e50', width = 2.5),
            marker = list(size = 6, color = '#2c3e50')) %>%
      layout(
        title = "Evolución del Tipo de Cambio Mayorista (Promedio Mensual)",
        xaxis = list(title = "Fecha"),
        yaxis = list(title = "ARS por Dólar"),
        hovermode = 'x unified'
      )
  })
  
  output$plot_ipc <- renderPlotly({
    plot_ly(datos_macro, x = ~Fecha, y = ~IPC_Nivel_General, type = 'scatter', mode = 'lines+markers',
            line = list(color = '#e74c3c', width = 2.5),
            marker = list(size = 6, color = '#e74c3c')) %>%
      layout(
        title = "Evolución del IPC - Nivel General",
        xaxis = list(title = "Fecha"),
        yaxis = list(title = "Índice"),
        hovermode = 'x unified'
      )
  })
  
  output$plot_embi <- renderPlotly({
    if("EMBI_Promedio" %in% names(datos_macro) && any(!is.na(datos_macro$EMBI_Promedio))) {
      plot_ly(datos_macro, x = ~Fecha, y = ~EMBI_Promedio, type = 'scatter', mode = 'lines+markers',
              line = list(color = '#e67e22', width = 2.5),
              marker = list(size = 6, color = '#e67e22')) %>%
        layout(
          title = "Evolución del Spread Soberano - Riesgo País EMBI",
          xaxis = list(title = "Fecha"),
          yaxis = list(title = "Puntos Básicos (pb)"),
          hovermode = 'x unified'
        )
    } else {
      plot_ly() %>% layout(title = "Serie de Riesgo País no disponible")
    }
  })
  
  # --- HANDLER DE DESCARGA CSV ---
  output$download_csv <- downloadHandler(
    filename = function() {
      paste("latam_macro_dataset_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(datos_macro, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)