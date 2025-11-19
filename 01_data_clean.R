library(tidyverse)
library(lubridate)

setwd("s:/Bureau/Ceci est un dossier (SSD)/IPSSI Cours/R/Projet_VideoGames")

# charger le csv
df_raw <- read_csv("games.csv", show_col_types = FALSE)

cat("Données brutes :", nrow(df_raw), "lignes\n")

df_clean <- df_raw %>%
  # normaliser
  rename(
    Release.date = `Release date`,
    Supported.languages = `Supported languages`,
    Full.audio.languages = `Full audio languages`,
    Metacritic.score = `Metacritic score`,
    User.score = `User score`,
    Average.playtime.forever = `Average playtime forever`
  ) %>%
  
  # vérifier que AppID est bien un nombre. 
  filter(str_detect(as.character(AppID), "^[0-9]+$")) %>%
  
  distinct() %>%
  select(AppID, Name, Release.date, Price,
         Supported.languages, Full.audio.languages, Windows, Mac, Linux,
         Metacritic.score, User.score, Positive, Negative,
         Average.playtime.forever, Developers, Publishers, Categories) %>%
  mutate(
    # formatage par sécurité
    Release.date = parse_date_time(Release.date, orders = c("b d, Y", "Y-m-d", "b Y")),
    Release.date = as.Date(Release.date),
    
    Price = as.numeric(Price),
    Metacritic.score = as.numeric(Metacritic.score),
    User.score = as.numeric(User.score),
    Positive = as.numeric(Positive),
    Negative = as.numeric(Negative),
    Average.playtime.forever = as.numeric(Average.playtime.forever)
  ) %>%
  filter(Price > 0 | is.na(Price))

cat("Données nettoyées :", nrow(df_clean), "lignes\n")

# réécrire un nouveau fichier csv cleané
write.csv(df_clean, "games_cleaned.csv", row.names = FALSE)