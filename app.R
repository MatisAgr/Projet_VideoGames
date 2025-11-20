library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(readr)
library(ggplot2)
library(mongolite)
library(lubridate)

# --- CONFIGURATION MONGODB ---
MONGO_URL <- "mongodb://localhost:27017"
DB_NAME <- "steam_data"
COLLECTION_NAME <- "games"

get_games_data <- function() {
  tryCatch({
    db <- mongo(collection = COLLECTION_NAME, db = DB_NAME, url = MONGO_URL)
    games_data <- db$find()
    names(games_data) <- gsub("\\.", "_", names(games_data))
    return(games_data)
  }, error = function(e) {
    stop("Erreur de connexion à MongoDB: ", e$message)
  })
}

games_data <- get_games_data()

ui <- navbarPage(
  "🎮 Dashboard Jeux Vidéo",
  theme = NULL,
  useShinyjs(),
  tags$head(
    tags$script(src = "https://cdn.tailwindcss.com"),
    tags$style(HTML("
      body { @apply bg-gray-100; }
      .sidebar-panel { @apply bg-white p-6 rounded-lg shadow-md; }
      .main-panel { @apply bg-white p-6 rounded-lg shadow-md; }
      .stat-panel { @apply bg-gradient-to-br from-blue-500 to-blue-600 text-white p-4 rounded-lg shadow-md; }
      .stat-panel h5 { @apply text-sm font-semibold opacity-90; }
      .stat-panel-content { @apply text-2xl font-bold mt-2; }
      .section-title { @apply text-2xl font-bold text-gray-800 mb-4; }
      .filter-section h4 { @apply text-lg font-bold text-gray-800 mb-4; }
      table { @apply w-full; }
      .page-header { @apply bg-gradient-to-r from-blue-600 to-blue-700 text-white p-6 rounded-lg shadow-md mb-6; }
      .page-header h1 { @apply text-3xl font-bold m-0; }
    "))
  ),
  
  tabPanel("Accueil",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-full mx-auto",
        div(class = "page-header", h1("🎮 Dashboard Jeux Vidéo")),
        div(class = "bg-white p-6 rounded-lg shadow-md mb-6",
          h3(class = "section-title", "⭐ Top 10 - Meilleures critiques"),
          DTOutput("top_10_table")
        ),
        div(class = "bg-white p-6 rounded-lg shadow-md",
          h3(class = "section-title", "📉 Bottom 10 - Moins bonnes critiques"),
          DTOutput("bottom_10_table")
        )
      )
    )
  ),
  
  tabPanel("Données & Filtres",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-full mx-auto",
        div(class = "page-header", h1("🎮 Données & Statistiques")),
        div(class = "grid grid-cols-1 xl:grid-cols-5 gap-6",
          div(class = "xl:col-span-1",
            div(class = "sidebar-panel",
              div(class = "filter-section",
                h4("Filtrer les données"),
                div(class = "mb-4", sliderInput("price_filter", "Prix maximum ($)", min = 0, max = max(games_data$Price, na.rm = TRUE), value = max(games_data$Price, na.rm = TRUE))),
                div(class = "mb-4", sliderInput("score_filter", "Score Metacritic minimum", min = 0, max = 100, value = 0)),
                div(class = "mb-4", selectInput("platform_filter", "Plateforme", choices = c("Tous" = "all", "Windows" = "windows", "Mac" = "mac", "Linux" = "linux"))),
                div(class = "mb-4", actionButton("btn_refresh", "Actualiser", class = "w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg")),
                hr(class = "my-4 border-gray-300"),
                div(class = "text-sm text-gray-600", p("Données depuis MongoDB"))
              )
            )
          ),
          div(class = "xl:col-span-4",
            div(class = "main-panel mb-6",
              h3(class = "section-title", "Données en temps réel"),
              p(class = "text-gray-600 mb-4", "Jeux vidéo filtrés :"),
              DTOutput("games_table")
            ),
            div(
              h4(class = "section-title", "Statistiques"),
              div(class = "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4",
                div(class = "stat-panel", h5("Nombre de jeux"), div(class = "stat-panel-content", textOutput("count_games"))),
                div(class = "stat-panel", h5("Prix moyen"), div(class = "stat-panel-content", textOutput("avg_price"))),
                div(class = "stat-panel", h5("Score Metacritic"), div(class = "stat-panel-content", textOutput("avg_score"))),
                div(class = "stat-panel", h5("Score utilisateur"), div(class = "stat-panel-content", textOutput("avg_user")))
              )
            )
          )
        )
      )
    )
  ),
  
  tabPanel("Graphiques & Analyses",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-full mx-auto",
        div(class = "page-header", h1("📊 Graphiques & Analyses")),
        div(class = "grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6",
          div(class = "main-panel", h4(class = "section-title", "Distribution des prix"), plotOutput("plot_price_dist")),
          div(class = "main-panel", h4(class = "section-title", "Distribution Metacritic"), plotOutput("plot_metacritic_dist"))
        ),
        div(class = "grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6",
          div(class = "main-panel", h4(class = "section-title", "Jeux par année"), plotOutput("plot_games_by_year")),
          div(class = "main-panel", h4(class = "section-title", "Prix par année"), plotOutput("plot_price_by_year"))
        ),
        div(class = "grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6",
          div(class = "main-panel", h4(class = "section-title", "Jeux par plateforme"), plotOutput("plot_platform_count")),
          div(class = "main-panel", h4(class = "section-title", "Prix par plateforme"), plotOutput("plot_platform_price"))
        ),
        div(class = "main-panel mb-6", h4(class = "section-title", "Top 15 catégories"), plotOutput("plot_top_categories", height = "500px")),
        div(class = "grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6",
          div(class = "main-panel", h4(class = "section-title", "Metacritic vs User Score"), plotOutput("plot_score_correlation")),
          div(class = "main-panel", h4(class = "section-title", "Prix vs Temps de jeu"), plotOutput("plot_price_playtime"))
        ),
        div(class = "main-panel", h4(class = "section-title", "Top 10 éditeurs"), plotOutput("plot_top_publishers", height = "500px"))
      )
    )
  ),
  
  tabPanel("Ajouter un jeu",
    div(class = "min-h-screen bg-gray-100 p-6",
      div(class = "max-w-4xl mx-auto",
        div(class = "page-header", h1("➕ Ajouter un nouveau jeu")),
        div(class = "bg-white p-8 rounded-lg shadow-md",
          div(class = "grid grid-cols-1 md:grid-cols-2 gap-6 mb-6",
            div(
              h4(class = "font-bold text-gray-800 mb-2", "AppID"),
              numericInput("form_appid", NULL, value = 1)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Name"),
              textInput("form_name", NULL, placeholder = "Nom du jeu")
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Release date"),
              dateInput("form_release", NULL)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Price ($)"),
              numericInput("form_price", NULL, value = 0)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Supported languages"),
              textInput("form_languages", NULL, placeholder = "Exemple: English, French")
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Developers"),
              textInput("form_developers", NULL, placeholder = "Nom du/des développeur(s)")
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Publishers"),
              textInput("form_publishers", NULL, placeholder = "Nom du/des éditeur(s)")
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Categories"),
              textInput("form_categories", NULL, placeholder = "Exemple: Single-player, Multiplayer")
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Metacritic score"),
              numericInput("form_metacritic", NULL, value = 0, min = 0, max = 100)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "User score"),
              numericInput("form_user_score", NULL, value = 0, min = 0, max = 10)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Positive reviews"),
              numericInput("form_positive", NULL, value = 0)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Negative reviews"),
              numericInput("form_negative", NULL, value = 0)
            )
          ),
          div(class = "grid grid-cols-1 md:grid-cols-4 gap-4 mb-6",
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Windows"),
              checkboxInput("form_windows", "Disponible", value = TRUE)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Mac"),
              checkboxInput("form_mac", "Disponible", value = FALSE)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Linux"),
              checkboxInput("form_linux", "Disponible", value = FALSE)
            ),
            div(
              h4(class = "font-bold text-gray-800 mb-2", "Average playtime (hours)"),
              numericInput("form_playtime", NULL, value = 0)
            )
          ),
          div(class = "flex gap-4",
            actionButton("btn_submit_game", "✅ Ajouter à MongoDB", class = "bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-6 rounded-lg"),
            actionButton("btn_reset_form", "🔄 Réinitialiser", class = "bg-gray-600 hover:bg-gray-700 text-white font-bold py-3 px-6 rounded-lg")
          ),
          div(id = "form_message", class = "mt-6 p-4 rounded-lg", style = "display:none;")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  output$top_10_table <- renderDT({
    top_10 <- games_data %>% filter(!is.na(Metacritic_score)) %>% arrange(desc(Metacritic_score)) %>% head(10) %>% select(Name, Price, Metacritic_score, User_score, Release_date)
    datatable(top_10, options = list(pageLength = 10, dom = 't'), colnames = c("Nom", "Prix", "Metacritic", "User", "Date"))
  })
  
  output$bottom_10_table <- renderDT({
    bottom_10 <- games_data %>% filter(!is.na(Metacritic_score)) %>% arrange(Metacritic_score) %>% head(10) %>% select(Name, Price, Metacritic_score, User_score, Release_date)
    datatable(bottom_10, options = list(pageLength = 10, dom = 't'), colnames = c("Nom", "Prix", "Metacritic", "User", "Date"))
  })
  
  data_trigger <- reactiveVal(0)
  
  filtered_data <- reactive({
    data_trigger()
    data <- games_data %>% filter(Price <= input$price_filter, Metacritic_score >= input$score_filter | is.na(Metacritic_score))
    if (input$platform_filter != "all") {
      if (input$platform_filter == "windows") data <- data %>% filter(Windows == 1)
      else if (input$platform_filter == "mac") data <- data %>% filter(Mac == 1)
      else if (input$platform_filter == "linux") data <- data %>% filter(Linux == 1)
    }
    return(data)
  })
  
  output$games_table <- renderDT({
    datatable(filtered_data() %>% select(Name, Price, Metacritic_score, User_score, Release_date, Windows, Mac, Linux), options = list(pageLength = 10))
  })
  
  output$count_games <- renderText(nrow(filtered_data()))
  output$avg_price <- renderText(paste0("$", round(mean(filtered_data()$Price, na.rm = TRUE), 2)))
  output$avg_score <- renderText(round(mean(filtered_data()$Metacritic_score, na.rm = TRUE), 1))
  output$avg_user <- renderText(round(mean(filtered_data()$User_score, na.rm = TRUE), 2))
  
  observeEvent(input$btn_refresh, { data_trigger(data_trigger() + 1) })
  
  output$plot_price_dist <- renderPlot({
    df <- games_data %>% filter(!is.na(Price))
    ggplot(df, aes(x = Price)) + geom_histogram(bins = 50, fill = "steelblue", color = "black") + xlim(0, 100) + labs(x = "Prix ($)", y = "Nombre") + theme_minimal()
  })
  
  output$plot_metacritic_dist <- renderPlot({
    df <- games_data %>% filter(!is.na(Metacritic_score))
    if(nrow(df) > 0) ggplot(df, aes(x = Metacritic_score)) + geom_histogram(bins = 30, fill = "purple", color = "black") + labs(x = "Score", y = "Nombre") + theme_minimal()
  })
  
  output$plot_games_by_year <- renderPlot({
    df <- games_data %>% filter(!is.na(Release_date)) %>% mutate(Year = year(Release_date)) %>% group_by(Year) %>% summarise(Count = n(), .groups = 'drop')
    ggplot(df, aes(x = Year, y = Count)) + geom_line(color = "steelblue", size = 1) + geom_point(size = 2) + labs(x = "Année", y = "Nombre") + theme_minimal()
  })
  
  output$plot_price_by_year <- renderPlot({
    df <- games_data %>% filter(!is.na(Release_date) & !is.na(Price)) %>% mutate(Year = year(Release_date)) %>% group_by(Year) %>% summarise(Avg = mean(Price, na.rm = TRUE), .groups = 'drop')
    ggplot(df, aes(x = Year, y = Avg)) + geom_line(color = "orange", size = 1) + geom_point(size = 2) + labs(x = "Année", y = "Prix ($)") + theme_minimal()
  })
  
  output$plot_platform_count <- renderPlot({
    df <- data.frame(Plateforme = c("Windows", "Mac", "Linux"), Count = c(sum(games_data$Windows == 1, na.rm = TRUE), sum(games_data$Mac == 1, na.rm = TRUE), sum(games_data$Linux == 1, na.rm = TRUE)))
    ggplot(df, aes(x = Plateforme, y = Count, fill = Plateforme)) + geom_bar(stat = "identity") + labs(y = "Nombre") + theme_minimal() + guides(fill = "none")
  })
  
  output$plot_platform_price <- renderPlot({
    df <- data.frame(Plateforme = c("Windows", "Mac", "Linux"), Prix = c(mean(games_data$Price[games_data$Windows == 1], na.rm = TRUE), mean(games_data$Price[games_data$Mac == 1], na.rm = TRUE), mean(games_data$Price[games_data$Linux == 1], na.rm = TRUE)))
    ggplot(df, aes(x = Plateforme, y = Prix, fill = Plateforme)) + geom_bar(stat = "identity") + labs(y = "Prix ($)") + theme_minimal() + guides(fill = "none")
  })
  
  output$plot_top_categories <- renderPlot({
    df <- games_data %>% filter(!is.na(Categories))
    if(nrow(df) > 0) {
      cats <- unlist(strsplit(df$Categories, ","))
      cats <- trimws(cats)
      top <- sort(table(cats), decreasing = TRUE)[1:15]
      df_plot <- data.frame(Category = names(top), Count = as.numeric(top))
      ggplot(df_plot, aes(x = reorder(Category, Count), y = Count)) + geom_bar(stat = "identity", fill = "steelblue") + coord_flip() + labs(x = "", y = "Nombre") + theme_minimal()
    }
  })
  
  output$plot_score_correlation <- renderPlot({
    df <- games_data %>% filter(!is.na(Metacritic_score) & !is.na(User_score))
    if(nrow(df) > 0) ggplot(df, aes(x = Metacritic_score, y = User_score)) + geom_point(alpha = 0.5, color = "red") + geom_smooth(method = "lm", se = TRUE, color = "blue") + labs(x = "Metacritic", y = "User") + theme_minimal()
  })
  
  output$plot_price_playtime <- renderPlot({
    df <- games_data %>% filter(!is.na(Average_playtime_forever) & !is.na(Price) & Price > 0)
    if(nrow(df) > 0) ggplot(df, aes(x = Price, y = Average_playtime_forever)) + geom_point(alpha = 0.5, color = "darkblue") + geom_smooth(method = "lm", se = TRUE, color = "red") + xlim(0, 100) + ylim(0, 500) + labs(x = "Prix ($)", y = "Heures") + theme_minimal()
  })
  
  output$plot_top_publishers <- renderPlot({
    df <- games_data %>% filter(!is.na(Publishers))
    if(nrow(df) > 0) {
      pubs <- unlist(strsplit(df$Publishers, ","))
      pubs <- trimws(pubs)
      top <- sort(table(pubs), decreasing = TRUE)[1:10]
      df_plot <- data.frame(Publisher = names(top), Count = as.numeric(top))
      ggplot(df_plot, aes(x = reorder(Publisher, Count), y = Count)) + geom_bar(stat = "identity", fill = "steelblue") + coord_flip() + labs(x = "", y = "Nombre") + theme_minimal()
    }
  })
  
  # PAGE 4: FORMULAIRE D'AJOUT DE JEU
  observeEvent(input$btn_submit_game, {
    # Validation
    if (input$form_name == "" || is.na(input$form_name)) {
      shinyjs::runjs("document.getElementById('form_message').style.display='block'; document.getElementById('form_message').style.backgroundColor='#fee'; document.getElementById('form_message').innerHTML='<strong style=\"color:red;\">Erreur: Le nom du jeu est obligatoire!</strong>';")
      return()
    }
    
    # Créer le nouveau jeu
    new_game <- data.frame(
      AppID = as.numeric(input$form_appid),
      Name = input$form_name,
      Release_date = as.character(input$form_release),
      Price = as.numeric(input$form_price),
      Supported_languages = input$form_languages,
      Full_audio_languages = "",
      Windows = as.numeric(input$form_windows),
      Mac = as.numeric(input$form_mac),
      Linux = as.numeric(input$form_linux),
      Metacritic_score = as.numeric(input$form_metacritic),
      User_score = as.numeric(input$form_user_score),
      Positive = as.numeric(input$form_positive),
      Negative = as.numeric(input$form_negative),
      Average_playtime_forever = as.numeric(input$form_playtime),
      Developers = input$form_developers,
      Publishers = input$form_publishers,
      Categories = input$form_categories,
      stringsAsFactors = FALSE
    )
    
    # Insérer dans MongoDB
    tryCatch({
      db <- mongo(collection = COLLECTION_NAME, db = DB_NAME, url = MONGO_URL)
      db$insert(new_game)
      
      # Message de succès
      shinyjs::runjs("document.getElementById('form_message').style.display='block'; document.getElementById('form_message').style.backgroundColor='#efe'; document.getElementById('form_message').innerHTML='<strong style=\"color:green;\">✅ Jeu ajouté avec succès à MongoDB!</strong>';")
      
      # Réinitialiser le formulaire après 2 secondes
      shiny::invalidateLater(2000, session)
      
    }, error = function(e) {
      shinyjs::runjs(paste0("document.getElementById('form_message').style.display='block'; document.getElementById('form_message').style.backgroundColor='#fee'; document.getElementById('form_message').innerHTML='<strong style=\"color:red;\">Erreur MongoDB: ", gsub("'", "\\'", e$message), "</strong>';"))
    })
  })
  
  # Bouton Réinitialiser
  observeEvent(input$btn_reset_form, {
    updateNumericInput(session, "form_appid", value = 1)
    updateTextInput(session, "form_name", value = "")
    updateDateInput(session, "form_release", value = Sys.Date())
    updateNumericInput(session, "form_price", value = 0)
    updateTextInput(session, "form_languages", value = "")
    updateTextInput(session, "form_developers", value = "")
    updateTextInput(session, "form_publishers", value = "")
    updateTextInput(session, "form_categories", value = "")
    updateNumericInput(session, "form_metacritic", value = 0)
    updateNumericInput(session, "form_user_score", value = 0)
    updateNumericInput(session, "form_positive", value = 0)
    updateNumericInput(session, "form_negative", value = 0)
    updateNumericInput(session, "form_playtime", value = 0)
    updateCheckboxInput(session, "form_windows", value = TRUE)
    updateCheckboxInput(session, "form_mac", value = FALSE)
    updateCheckboxInput(session, "form_linux", value = FALSE)
    shinyjs::runjs("document.getElementById('form_message').style.display='none';")
  })
}

shinyApp(ui = ui, server = server)
