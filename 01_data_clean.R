library(tidyverse)
library(lubridate)
library(jsonlite)

# --- configuration ---
# définir le répertoire de travail sur celui du script
script_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
if (script_dir != "") {
  setwd(script_dir)
} else {
  # fallback si pas dans RStudio
  script_dir <- getSrcDirectory(function(x) {x})
  if (script_dir != "") setwd(script_dir)
}

cat("Répertoire de travail :", getwd(), "\n")

input_file <- "games.json"            
output_csv <- "games_cleaned.csv"
output_json <- "games_cleaned.json"

# vérification fichier
if (!file.exists(input_file)) {
  stop("fichier games.json introuvable dans : ", getwd())
}

# lecture du fichier JSON
cat("Lecture du fichier JSON en cours...\n")
games_raw <- fromJSON(input_file, simplifyVector = FALSE)

cat("Total jeux lus :", length(games_raw), "\n")

# extract et transformation des données
cat("Extraction des données...\n")

df_list <- lapply(names(games_raw), function(app_id) {
  game <- games_raw[[app_id]]
  
  # fonction helper pour extraire les listes en string
  list_to_string <- function(x) {
    if (is.null(x) || length(x) == 0) return(NA_character_)
    paste(unlist(x), collapse = ", ")
  }
  
  data.frame(
    AppID = as.character(app_id),
    Name = ifelse(is.null(game$name), NA_character_, game$name),
    Release.date = ifelse(is.null(game$release_date), NA_character_, game$release_date),
    Price = ifelse(is.null(game$price), NA_real_, as.numeric(game$price)),
    Supported.languages = list_to_string(game$supported_languages),
    Full.audio.languages = list_to_string(game$full_audio_languages),
    Windows = ifelse(is.null(game$windows), FALSE, as.logical(game$windows)),
    Mac = ifelse(is.null(game$mac), FALSE, as.logical(game$mac)),
    Linux = ifelse(is.null(game$linux), FALSE, as.logical(game$linux)),
    Metacritic.score = ifelse(is.null(game$metacritic_score), NA_real_, as.numeric(game$metacritic_score)),
    User.score = ifelse(is.null(game$user_score), NA_real_, as.numeric(game$user_score)),
    Positive = ifelse(is.null(game$positive), NA_real_, as.numeric(game$positive)),
    Negative = ifelse(is.null(game$negative), NA_real_, as.numeric(game$negative)),
    Average.playtime.forever = ifelse(is.null(game$average_playtime_forever), NA_real_, as.numeric(game$average_playtime_forever)),
    Developers = list_to_string(game$developers),
    Publishers = list_to_string(game$publishers),
    Categories = list_to_string(game$categories),
    stringsAsFactors = FALSE
  )
})

# combiner toutes les lignes
df_raw <- bind_rows(df_list)

cat("Lignes extraites :", nrow(df_raw), "\n")

# nettoyage et filtrage
df_clean <- df_raw %>%

  # nettoyage des espaces
  mutate(across(where(is.character), ~str_trim(.))) %>%
  
  # suppression des doublons
  distinct(AppID, .keep_all = TRUE) %>%
  
  # conversion des dates
  mutate(
    Release.date = parse_date_time(Release.date, orders = c("b d, Y", "Y-m-d", "b Y"), quiet = TRUE),
    Release.date = as.Date(Release.date)
  ) %>%
  
  # filtrage : garder uniquement les lignes avec au moins un AppID et un nom
  filter(!is.na(AppID), !is.na(Name), Name != "")

cat("Lignes après nettoyage :", nrow(df_clean), "\n")

# création du JSON propre
# convertir le dataframe en liste de jeux (format JSON structuré)
games_clean_list <- list()

for (i in 1:nrow(df_clean)) {
  row <- df_clean[i, ]
  app_id <- row$AppID
  
  games_clean_list[[app_id]] <- list(
    name = row$Name,
    release_date = if(is.na(row$Release.date)) NULL else as.character(row$Release.date),
    price = if(is.na(row$Price)) NULL else row$Price,
    supported_languages = if(is.na(row$Supported.languages)) list() else strsplit(row$Supported.languages, ", ")[[1]],
    full_audio_languages = if(is.na(row$Full.audio.languages)) list() else strsplit(row$Full.audio.languages, ", ")[[1]],
    windows = row$Windows,
    mac = row$Mac,
    linux = row$Linux,
    metacritic_score = if(is.na(row$Metacritic.score)) 0 else row$Metacritic.score,
    user_score = if(is.na(row$User.score)) 0 else row$User.score,
    positive = if(is.na(row$Positive)) 0 else row$Positive,
    negative = if(is.na(row$Negative)) 0 else row$Negative,
    average_playtime_forever = if(is.na(row$Average.playtime.forever)) 0 else row$Average.playtime.forever,
    developers = if(is.na(row$Developers)) list() else strsplit(row$Developers, ", ")[[1]],
    publishers = if(is.na(row$Publishers)) list() else strsplit(row$Publishers, ", ")[[1]],
    categories = if(is.na(row$Categories)) list() else strsplit(row$Categories, ", ")[[1]]
  )
}

# écriture des fichiers nettoyés
cat("Ecriture des fichiers...\n")
write_csv(df_clean, output_csv)
write_json(games_clean_list, output_json, pretty = TRUE, auto_unbox = TRUE)

lignes_supprimees <- nrow(df_raw) - nrow(df_clean)
cat("Lignes supprimées lors du nettoyage :", lignes_supprimees, "\n")

cat("Fichier CSV écrit :", output_csv, "\n")
cat("Fichier JSON écrit :", output_json, "\n")