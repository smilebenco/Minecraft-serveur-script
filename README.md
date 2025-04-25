🔁 Script de Redémarrage Automatique pour Serveur Minecraft

Ce script Bash permet de gérer automatiquement le lancement, le nettoyage des entités, et le redémarrage périodique d’un serveur Minecraft Java. Il inclut également une notification via Webhook Discord pour signaler les redémarrages.
✨ Fonctionnalités

    🚀 Lancement automatique du serveur Minecraft (server.jar)
    🔄 Redémarrage planifié toutes les 4 heures (modifiable)
    🧹 Nettoyage automatique des entités item si leur nombre dépasse un seuil défini
    ⏱ Sauvegarde du monde avant chaque redémarrage
    🔔 Notifications Discord en cas de redémarrage (activable ou non)
    📝 Logs horodatés enregistrés dans un dossier logs/
    🔒 Connexion via RCON pour exécuter des commandes en jeu

⚙️ Prérequis

    java installé
    mcrcon installé (outil pour envoyer des commandes via RCON)
    Un fichier server.jar (votre serveur Minecraft)
    Configuration du serveur pour autoriser RCON :
    enable-rcon=true
    rcon.password=mdp
    rcon.port=25575

🔧 Configuration rapide
Modifiez les valeurs au début du script selon vos besoins :
    
    WEBHOOK_URL= # URL Webhook Discord                       # URL Webhook Discord
    RESTART_EVERY_SECONDS=$((4 * 60 * 60))                   # Intervalle de redémarrage (4h)
    ENABLE_DISCORD_NOTIF=true                                # Active les notifications Discord
    RESTART_DELAY=5                                          # Délai entre chaque redémarrage
    MAX_ENTITIES=600                                         # Seuil de nettoyage des entités "item"
    RCON_PASSWORD="mdp"                                      # Mot de passe RCON
    RCON_PORT=25575                                          # Port RCON
