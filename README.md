[Lien pour le dataset](https://huggingface.co/datasets/FronkonGames/steam-games-dataset)
Prendre le games.json car le games.csv est différent et mal formaté.

La data date du Mars-Avril 2025. Donc il se peut que les graphiques montre une baisse des chiffres sur les derniers mois car les données ne sont pas complètes.

les fichiers sont déjà prétraités via le script R 01_data_clean.R pour gagner du temps.:
- games_cleaned.csv : le csv nettoyé (utile pour l'insertion dans Mongodb)
- games_cleaned.json : le json nettoyé