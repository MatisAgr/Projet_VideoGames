library(shiny)
library(tidyverse)
library(ggplot2)
library(plotly)

df <- readRDS("games_cleaned.rds")
model <- readRDS("model_peak_ccu.rds")

df <- df %>%
  mutate(Primary_Genre = sapply(strsplit(Genres, ","), 
                                 function(x) trimws(x[1])))

ui <- fluidPage(
  titlePanel("Dashboard Jeux Steam"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Filtres"),
      selectInput("genre", "Genre Principal :",
                  c("Tous", sort(unique(df$Primary_Genre)))),
      sliderInput("year_range", "Années :",
                  min = min(df$Year), max = max(df$Year),
                  value = c(2015, 2024), step = 1),
      sliderInput("price_range", "Prix (€) :",
                  min = 0, max = 60, value = c(0, 30)),
      
      hr(),
      h4("Prédiction IA"),
      numericInput("pred_price", "Prix (€) :", value = 19.99),
      numericInput("pred_meta", "Score Metacritic :", value = 75, min = 0, max = 100),
      numericInput("pred_user", "Score Utilisateur :", value = 7, min = 0, max = 10),
      numericInput("pred_ratio", "Ratio Avis+ :", value = 0.8, min = 0, max = 1),
      actionButton("predict_btn", "Prédire Peak CCU", class = "btn-primary")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Vue d'ensemble",
                 fluidRow(
                   column(6, plotlyOutput("plot_price_meta")),
                   column(6, plotlyOutput("plot_ccu_year"))
                 ),
                 fluidRow(
                   column(6, plotlyOutput("plot_genres")),
                   column(6, plotlyOutput("plot_reviews"))
                 )
        ),
        tabPanel("Données",
                 dataTableOutput("table_data")
        ),
        tabPanel("Prédiction",
                 h3("Résultat"),
                 verbatimTextOutput("pred_result"),
                 plotOutput("pred_context")
        )
      )
    )
  )
)

server <- function(input, output) {
  
  filtered_data <- reactive({
    data <- df
    
    if (input$genre != "Tous") {
      data <- data %>% filter(Primary_Genre == input$genre)
    }
    
    data %>%
      filter(Year >= input$year_range[1] & Year <= input$year_range[2]) %>%
      filter(Price >= input$price_range[1] & Price <= input$price_range[2])
  })
  
  output$plot_price_meta <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = Price, y = Metacritic.score)) +
      geom_point(alpha = 0.4, color = "steelblue") +
      geom_smooth(method = "lm", se = FALSE, color = "red") +
      labs(title = "Prix vs Score Metacritic", x = "Prix", y = "Metacritic") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$plot_ccu_year <- renderPlotly({
    p <- filtered_data() %>%
      group_by(Year) %>%
      summarise(Avg_CCU = mean(Peak.CCU, na.rm = TRUE)) %>%
      ggplot(aes(x = Year, y = Avg_CCU)) +
      geom_line(color = "darkblue", size = 1) +
      geom_point() +
      labs(title = "Peak CCU Moyen par Année", x = "Année", y = "Peak CCU") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$plot_genres <- renderPlotly({
    p <- filtered_data() %>%
      group_by(Primary_Genre) %>%
      summarise(Count = n()) %>%
      arrange(desc(Count)) %>%
      head(10) %>%
      ggplot(aes(x = reorder(Primary_Genre, Count), y = Count)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      coord_flip() +
      labs(title = "Top 10 Genres", x = "", y = "Nombre de jeux") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$plot_reviews <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = Review.Ratio)) +
      geom_histogram(bins = 30, fill = "purple", alpha = 0.7) +
      labs(title = "Distribution Ratio Avis+", x = "Ratio", y = "Fréquence") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$table_data <- renderDataTable({
    filtered_data() %>%
      select(Name, Year, Price, Metacritic.score, Peak.CCU) %>%
      arrange(desc(Peak.CCU))
  })
  
  pred_result <- eventReactive(input$predict_btn, {
    new_data <- data.frame(
      Price = input$pred_price,
      Metacritic.score = input$pred_meta,
      User.score = input$pred_user,
      Review.Ratio = input$pred_ratio
    )
    log_pred <- predict(model, new_data)
    peak_ccu <- 10^log_pred - 1
    return(max(0, peak_ccu))
  })
  
  output$pred_result <- renderText({
    req(pred_result())
    paste("Peak CCU Estimé :", round(pred_result(), 0), "joueurs")
  })
  
  output$pred_context <- renderPlot({
    req(pred_result())
    
    avg_ccu <- mean(df$Peak.CCU, na.rm = TRUE)
    median_ccu <- median(df$Peak.CCU, na.rm = TRUE)
    
    data.frame(
      Type = c("Moyenne globale", "Médiane globale", "Votre prédiction"),
      CCU = c(avg_ccu, median_ccu, pred_result())
    ) %>%
      ggplot(aes(x = Type, y = CCU, fill = Type)) +
      geom_bar(stat = "identity", width = 0.6) +
      scale_fill_manual(values = c("grey70", "grey50", "steelblue")) +
      labs(title = "Mise en contexte", y = "Peak CCU") +
      theme_minimal() +
      theme(legend.position = "none")
  })
}

shinyApp(ui, server)
