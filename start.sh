#!/bin/bash

# === Configuration ===
WEBHOOK_URL="https://discord.com/api/webhooks/0123456789"
RESTART_EVERY_SECONDS=$((4 * 60 * 60))  # 4 heures
ENABLE_DISCORD_NOTIF=true
RESTART_DELAY=5
JAR_FILE="server.jar"
LOG_FOLDER="logs"
RCON_PASSWORD="mdp"
RCON_PORT=25575

CHECK_INTERVAL=300     # Vérifie toutes les 5 minutes
MAX_ENTITIES=600      # Seuil d'entités "item"
LAST_ENTITY_CLEANUP=0

mkdir -p "$LOG_FOLDER"

while true
do
    START_TIME=$(date +%s)
    DATE=$(LC_TIME=fr_FR.UTF-8 date +"%d-%m-%Y_%H-%M-%S")
    LOG_FILE="$LOG_FOLDER/$DATE.log"

    echo "[$(date)] ▶️ Lancement du serveur Minecraft..." | tee -a "$LOG_FILE"

    # Lancer le serveur Minecraft
    java -jar "$JAR_FILE" --nogui | tee -a "$LOG_FILE" &
    SERVER_PID=$!

    echo "[$(date)] 🆔 PID du serveur : $SERVER_PID" | tee -a "$LOG_FILE"

    # Boucle de surveillance
    while kill -0 $SERVER_PID 2>/dev/null; do
        CURRENT_TIME=$(date +%s)
        UPTIME=$((CURRENT_TIME - START_TIME))

        # === Nettoyage auto des entités ===
        if (( CURRENT_TIME - LAST_ENTITY_CLEANUP >= CHECK_INTERVAL )); then
            ENTITY_COUNT=$(mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "execute at @a run data get entity @s Pos" | wc -l)

            echo "[$(LC_TIME=fr_FR.UTF-8 date +"%d/%m/%Y %H:%M:%S")] 📊 Entités estimées : $ENTITY_COUNT" | tee -a "$LOG_FILE"

            if (( ENTITY_COUNT > MAX_ENTITIES )); then
                echo "[$(LC_TIME=fr_FR.UTF-8 date +"%d/%m/%Y %H:%M:%S")] ⚠ Trop d'entités détectées ($ENTITY_COUNT). Nettoyage..." | tee -a "$LOG_FILE"

                mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Trop d'objets au sol ! Nettoyage automatique en cours..."
                mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "kill @e[type=item]"
                LAST_ENTITY_CLEANUP=$CURRENT_TIME
            fi
        fi

        # === Redémarrage programmé ===
        if [ "$UPTIME" -ge "$RESTART_EVERY_SECONDS" ]; then
            echo "[$(date)] ⏰ Temps écoulé. Préparation au redémarrage..." | tee -a "$LOG_FILE"

            mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Redémarrage automatique dans 5 minutes."
            sleep 300

            mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Redémarrage dans 1 minute."
            sleep 50

            for i in $(seq 10 -1 1); do
                mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Redémarrage dans $i secondes..."
                sleep 1
            done

            mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Sauvegarde du monde..."
            mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "save-all"
            sleep 3

            mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "stop"

            wait $SERVER_PID
            break
        fi

        sleep 10
    done

    echo "[$(date)] 🔁 Serveur arrêté. Redémarrage dans $RESTART_DELAY secondes..." | tee -a "$LOG_FILE"

    if [ "$ENABLE_DISCORD_NOTIF" = true ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"🚨 Le serveur Minecraft a été redémarré à $(date).\"}" \
             "$WEBHOOK_URL"
    fi

    sleep "$RESTART_DELAY"
done
