
library(mongolite)
library(readr)

# emplacement fichier csv
CSV_CLEAN_FILE <- "games_cleaned.csv"

# parametre de connexion
MONGO_URL <- "mongodb://localhost:27017" 
DB_NAME <- "steam_data"
COLLECTION_NAME <- "games"

cat("Fichier a importer  :", CSV_CLEAN_FILE, "...\n")

if (!file.exists(CSV_CLEAN_FILE)) {
  stop("Erreur : Le fichier '", CSV_CLEAN_FILE, "' n'existe pas. Lancer le script 01_data_clean.R d'abord.")
}

# On lit le fichier. show_col_types = FALSE pour ne pas polluer la console
df_to_import <- read_csv(CSV_CLEAN_FILE, show_col_types = FALSE)
cat("Chargement terminé :", nrow(df_to_import), "lignes prêtes à être importées.\n")


# Importer dans MongoDB

tryCatch({
  # Connexion à la base
  db <- mongo(collection = COLLECTION_NAME, db = DB_NAME, url = MONGO_URL)
  
  count_before <- db$count()
  if(count_before > 0) { db$drop(); cat("Collection précédente effacée.\n") }

  # Insertion
  if (nrow(df_to_import) > 0) {
    cat("Insertion en cours...\n")
    
    db$insert(df_to_import)
    
    cat("Importation terminée.\n")
    cat("Total documents dans la collection '", COLLECTION_NAME, "' : ", db$count(), "\n", sep="")
    
  } else {
    cat("fichier vide !\n")
  }
  
}, error = function(e) {
  cat("ECHEC importation message :\n")
  cat(e$message, "\n")
})