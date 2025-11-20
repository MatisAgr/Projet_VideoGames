library(shiny)
library(dplyr)
library(DT) # Pour de jolis tableaux interactifs
library(readr)
library(ggplot2)

# --- CHARGEMENT DES DONNÉES ---
games_data <- read_csv("c:/Users/julie/Desktop/Exercices/R/Projet_VideoGames/games_cleaned.csv", 
                       show_col_types = FALSE)

# --- INTERFACE UTILISATEUR (UI) ---
ui <- navbarPage(
  "🎮 Dashboard Jeux Vidéo",
  theme = NULL,
  
  # CSS Tailwind
  tags$head(
    tags$script(src = "https://cdn.tailwindcss.com"),
    tags$style(HTML("
      body {
        @apply bg-gray-100;
      }
      .sidebar-panel {
        @apply bg-white p-6 rounded-lg shadow-md;
      }
      .main-panel {
        @apply bg-white p-6 rounded-lg shadow-md;
      }
      .stat-panel {
        @apply bg-gradient-to-br from-blue-500 to-blue-600 text-white p-4 rounded-lg shadow-md;
      }
      .stat-panel h5 {
        @apply text-sm font-semibold opacity-90;
      }
      .stat-panel-content {
        @apply text-2xl font-bold mt-2;
      }
      .section-title {
        @apply text-2xl font-bold text-gray-800 mb-4;
      }
      .filter-section h4 {
        @apply text-lg font-bold text-gray-800 mb-4;
      }
      table {
        @apply w-full;
      }
      .dataTables_wrapper {
        @apply bg-white rounded-lg;
      }
      .page-header {
        @apply bg-gradient-to-r from-blue-600 to-blue-700 text-white p-6 rounded-lg shadow-md mb-6;
      }
      .page-header h1 {
        @apply text-3xl font-bold m-0;
      }
      .top-10-container {
        @apply bg-white p-6 rounded-lg shadow-md mb-6;
      }
      .bottom-10-container {
        @apply bg-white p-6 rounded-lg shadow-md;
      }
    "))
  ),
  
  # PAGE 1: ACCUEIL AVEC TOP 10 ET BOTTOM 10
  tabPanel("Accueil",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-full mx-auto",
        # Header
        div(class = "page-header",
          h1("🎮 Dashboard Jeux Vidéo")
        ),
        
        # Top 10
        div(class = "top-10-container",
          h3(class = "section-title", "⭐ Top 10 - Meilleures critiques (Metacritic)"),
          DTOutput("top_10_table")
        ),
        
        # Bottom 10
        div(class = "bottom-10-container",
          h3(class = "section-title", "📉 Bottom 10 - Moins bonnes critiques"),
          DTOutput("bottom_10_table")
        )
      )
    )
  ),
  
  # PAGE 2: FILTRES ET STATISTIQUES (ancienne page)
  tabPanel("Données & Filtres",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-full mx-auto",
        # Header
        div(class = "page-header",
          h1("🎮 Données & Statistiques")
        ),
        
        # Main content
        div(class = "grid grid-cols-1 xl:grid-cols-5 gap-6",
          # Sidebar
          div(class = "xl:col-span-1",
            div(class = "sidebar-panel",
              div(class = "filter-section",
                h4("Filtrer les données"),
                
                div(class = "mb-4",
                  sliderInput("price_filter", "Prix maximum ($)", 
                              min = 0, max = max(games_data$Price, na.rm = TRUE), 
                              value = max(games_data$Price, na.rm = TRUE))
                ),
                
                div(class = "mb-4",
                  sliderInput("score_filter", "Score Metacritic minimum", 
                              min = 0, max = 100, value = 0)
                ),
                
                div(class = "mb-4",
                  selectInput("platform_filter", "Plateforme",
                              choices = c("Tous" = "all", 
                                         "Windows" = "windows", 
                                         "Mac" = "mac", 
                                         "Linux" = "linux"))
                ),
                
                div(class = "mb-4",
                  actionButton("btn_refresh", "Actualiser", class = "w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg transition")
                ),
                
                hr(class = "my-4 border-gray-300"),
                
                div(class = "text-sm text-gray-600",
                  p("Affichage des données du fichier games_cleaned.csv")
                )
              )
            )
          ),
          
          # Main content area
          div(class = "xl:col-span-4",
            # Tableau
            div(class = "main-panel mb-6",
              h3(class = "section-title", "Données en temps réel"),
              p(class = "text-gray-600 mb-4", "Voici les jeux vidéo filtrés :"),
              DTOutput("games_table")
            ),
            
            # Statistiques
            div(
              h4(class = "section-title", "Statistiques"),
              div(class = "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4",
                div(class = "stat-panel",
                  h5("Nombre de jeux"),
                  div(class = "stat-panel-content", textOutput("count_games"))
                ),
                div(class = "stat-panel",
                  h5("Prix moyen"),
                  div(class = "stat-panel-content", textOutput("avg_price"))
                ),
                div(class = "stat-panel",
                  h5("Score Metacritic moyen"),
                  div(class = "stat-panel-content", textOutput("avg_score"))
                ),
                div(class = "stat-panel",
                  h5("Score utilisateur moyen"),
                  div(class = "stat-panel-content", textOutput("avg_user"))
                )
              )
            )
          )
        )
      )
    )
  )
)

# --- LOGIQUE SERVEUR ---
server <- function(input, output, session) {
  
  # ===== PAGE 1: TOP 10 ET BOTTOM 10 =====
  
  # Top 10 par Metacritic
  output$top_10_table <- renderDT({
    top_10 <- games_data %>%
      filter(!is.na(Metacritic.score)) %>%
      arrange(desc(Metacritic.score)) %>%
      head(10) %>%
      select(Name, Price, Metacritic.score, User.score, Release.date)
    
    datatable(top_10, options = list(pageLength = 10, dom = 't'),
              colnames = c("Nom du jeu", "Prix", "Score Metacritic", "Score Utilisateur", "Date de sortie"))
  })
  
  # Bottom 10 par Metacritic
  output$bottom_10_table <- renderDT({
    bottom_10 <- games_data %>%
      filter(!is.na(Metacritic.score)) %>%
      arrange(Metacritic.score) %>%
      head(10) %>%
      select(Name, Price, Metacritic.score, User.score, Release.date)
    
    datatable(bottom_10, options = list(pageLength = 10, dom = 't'),
              colnames = c("Nom du jeu", "Prix", "Score Metacritic", "Score Utilisateur", "Date de sortie"))
  })
  
  # ===== PAGE 2: FILTRES ET STATISTIQUES =====
  
  # Variable réactive pour déclencher les mises à jour
  data_trigger <- reactiveVal(0)
  
  # Données filtrées
  filtered_data <- reactive({
    data_trigger() # Dépendance
    
    data <- games_data %>%
      filter(Price <= input$price_filter,
             Metacritic.score >= input$score_filter | is.na(Metacritic.score))
    
    # Filtre plateforme
    if (input$platform_filter != "all") {
      if (input$platform_filter == "windows") {
        data <- data %>% filter(Windows == 1)
      } else if (input$platform_filter == "mac") {
        data <- data %>% filter(Mac == 1)
      } else if (input$platform_filter == "linux") {
        data <- data %>% filter(Linux == 1)
      }
    }
    
    return(data)
  })
  
  # Affichage du tableau
  output$games_table <- renderDT({
    datatable(filtered_data() %>% 
              select(Name, Price, Metacritic.score, User.score, Release.date, Windows, Mac, Linux),
              options = list(pageLength = 10))
  })
  
  # Statistiques
  output$count_games <- renderText({
    nrow(filtered_data())
  })
  
  output$avg_price <- renderText({
    paste0("$", round(mean(filtered_data()$Price, na.rm = TRUE), 2))
  })
  
  output$avg_score <- renderText({
    round(mean(filtered_data()$Metacritic.score, na.rm = TRUE), 1)
  })
  
  output$avg_user <- renderText({
    round(mean(filtered_data()$User.score, na.rm = TRUE), 2)
  })
  
  # Bouton Rafraîchir
  observeEvent(input$btn_refresh, {
    data_trigger(data_trigger() + 1)
  })
}

# Lancement de l'application
shinyApp(ui = ui, server = server)