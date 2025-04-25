#!/bin/bash

# === Configuration ===
WEBHOOK_URL="https://discord.com/api/webhooks/123456789"
RESTART_EVERY_SECONDS=$((4 * 60 * 60))  # 4 heures
ENABLE_DISCORD_NOTIF=true
RESTART_DELAY=5
JAR_FILE="server.jar"
LOG_FOLDER="logs"
RCON_PASSWORD="<le mot de passe>"
RCON_PORT=25575

CHECK_INTERVAL=300
MAX_ENTITIES=600
LAST_ENTITY_CLEANUP=0
MESSAGE_ID_FILE="message_id.txt"

mkdir -p "$LOG_FOLDER"

while true; do
    START_TIME=$(date +%s)
    DATE=$(LC_TIME=fr_FR.UTF-8 date +"%d-%m-%Y_%H-%M-%S")
    LOG_FILE="$LOG_FOLDER/$DATE.log"

    echo "[$(date)] Lancement du serveur Minecraft..." | tee -a "$LOG_FILE"

    java -jar "$JAR_FILE" --nogui | tee -a "$LOG_FILE" &
    SERVER_PID=$!

    echo "[$(date)] PID du serveur : $SERVER_PID" | tee -a "$LOG_FILE"

    while kill -0 $SERVER_PID 2>/dev/null; do
        CURRENT_TIME=$(date +%s)
        UPTIME=$((CURRENT_TIME - START_TIME))

        if (( CURRENT_TIME - LAST_ENTITY_CLEANUP >= CHECK_INTERVAL )); then
            ENTITY_COUNT=$(mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" \
                "execute as @e[type=item] run data get entity @s UUID" | wc -l)

            echo "[$(LC_TIME=fr_FR.UTF-8 date +"%d/%m/%Y %H:%M:%S")] Entités estimées : $ENTITY_COUNT" | tee -a "$LOG_FILE"

            if (( ENTITY_COUNT > MAX_ENTITIES )); then
                echo "[$(LC_TIME=fr_FR.UTF-8 date +"%d/%m/%Y %H:%M:%S")] ⚠ Trop d'entités détectées ($ENTITY_COUNT). Nettoyage..." | tee -a "$LOG_FILE"

                mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "say [Serveur] Trop d'objets au sol ! Nettoyage automatique en cours..."
                mcrcon -H localhost -P $RCON_PORT -p "$RCON_PASSWORD" "kill @e[type=item]"
                LAST_ENTITY_CLEANUP=$CURRENT_TIME
            fi
        fi

        if [ "$UPTIME" -ge "$RESTART_EVERY_SECONDS" ]; then
            echo "[$(date)] Temps écoulé. Préparation au redémarrage..." | tee -a "$LOG_FILE"

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
        CURRENT_DATE="$(date)"
        MESSAGE_CONTENT="🚨 Le serveur Minecraft a été redémarré à $CURRENT_DATE."

        if [ -f "$MESSAGE_ID_FILE" ]; then
            MESSAGE_ID=$(cat "$MESSAGE_ID_FILE")
            curl -X PATCH "$WEBHOOK_URL/messages/$MESSAGE_ID" \
                 -H "Content-Type: application/json" \
                 -d "{\"content\": \"$MESSAGE_CONTENT\"}" \
                 && printf "[$(date)] Message Discord mis à jour.\n" | tee -a "$LOG_FILE"
        else
            curl -X POST -H "Content-Type: application/json" \
                 -d "{\"content\": \"$MESSAGE_CONTENT\"}" \
                 "$WEBHOOK_URL?wait=true" -o response.json

            grep -o '"id":"[0-9]*"' response.json | head -n1 | cut -d '"' -f4 > "$MESSAGE_ID_FILE"

            printf "[$(date)] Message Discord envoyé et ID sauvegardé.\n" | tee -a "$LOG_FILE"
        fi
    fi

    sleep "$RESTART_DELAY"
done
