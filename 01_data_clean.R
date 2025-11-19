library(tidyverse)
library(lubridate)

setwd("s:/Bureau/Ceci est un dossier (SSD)/IPSSI Cours/R/Projet_VideoGames")

df_raw <- read.csv("games.csv", stringsAsFactors = FALSE, encoding = "UTF-8")

cat("Données brutes :", nrow(df_raw), "lignes\n")

df_clean <- df_raw %>%
  distinct() %>%
  select(AppID, Name, Release.date, Required.age, Price,
         Supported.languages, Full.audio.languages, Windows, Mac, Linux,
         Metacritic.score, User.score, Positive, Negative, Score.rank,
         Recommendations, Notes, Average.playtime.forever, Developers, Publishers, Categories) %>%
  mutate(
    Release.date = as.Date(Release.date, format = "%b %d, %Y"),
    Year = year(Release.date),
    Price = as.numeric(Price),
    Required.age = as.numeric(Required.age),
    Metacritic.score = as.numeric(Metacritic.score),
    User.score = as.numeric(User.score),
    Positive = as.numeric(Positive),
    Negative = as.numeric(Negative),
    Score.rank = as.numeric(Score.rank),
    Recommendations = as.numeric(Recommendations),
    Average.playtime.forever = as.numeric(Average.playtime.forever)
  ) %>%
  filter(!is.na(Price), Price > 0) %>%
  filter(!is.na(Year), Year >= 2010, Year <= 2024)

cat("Données nettoyées :", nrow(df_clean), "lignes\n")
cat("Colonnes conservées :", ncol(df_clean), "\n")

saveRDS(df_clean, "games_cleaned.rds")
write.csv(df_clean, "games_cleaned.csv", row.names = FALSE)

cat("Fichiers sauvegardés : games_cleaned.rds et games_cleaned.csv\n")
