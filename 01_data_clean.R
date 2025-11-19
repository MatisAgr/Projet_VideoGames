library(tidyverse)
library(lubridate)

setwd("s:/Bureau/Ceci est un dossier (SSD)/IPSSI Cours/R/Projet_VideoGames")

df_raw <- read.csv("games.csv", stringsAsFactors = FALSE, encoding = "UTF-8")

cat("Données brutes :", nrow(df_raw), "lignes\n")
cat("Colonnes du fichier :\n")
print(colnames(df_raw)[1:15])

df_clean <- df_raw %>%
  distinct() %>%
  select(AppID, Name, Release.date, Price,
         Supported.languages, Full.audio.languages, Windows, Mac, Linux,
         Metacritic.score, User.score, Positive, Negative,
         Average.playtime.forever, Developers, Publishers, Categories) %>%
  mutate(
    Release.date = as.Date(Release.date, format = "%b %d, %Y"),
    Price = as.numeric(Price),
    Metacritic.score = as.numeric(Metacritic.score),
    User.score = as.numeric(User.score),
    Positive = as.numeric(Positive),
    Negative = as.numeric(Negative),
    Average.playtime.forever = as.numeric(Average.playtime.forever)
  ) %>%
  filter(Price > 0 | is.na(Price))

cat("Données nettoyées :", nrow(df_clean), "lignes\n")
cat("Colonnes conservées :", ncol(df_clean), "\n")

write.csv(df_clean, "games_cleaned.csv", row.names = FALSE)

cat("Fichiers sauvegardés : games_cleaned.csv\n")
