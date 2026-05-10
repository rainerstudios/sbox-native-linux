#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# s&box Native Linux — Pterodactyl / Pelican Entrypoint
#
# Compatible with both Pterodactyl and Pelican egg systems.
# Handles SteamCMD auto-update and native .NET server launch.
# ─────────────────────────────────────────────────────────────────────────────

# Wait for container to fully initialize
sleep 1

# Defaults
TZ=${TZ:-UTC}
export TZ

# Internal Docker IP (used by some eggs)
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

# ─── SteamCMD Auto-Update ────────────────────────────────────────────────────
if [ -z "${AUTO_UPDATE}" ] || [ "${AUTO_UPDATE}" == "1" ]; then
    if [ ! -z "${SRCDS_APPID}" ]; then
        echo "Checking for game server updates..."

        # Steam credentials (default: anonymous)
        if [ -z "${STEAM_USER}" ]; then
            echo "Steam user is not set. Defaulting to anonymous user."
            STEAM_USER=anonymous
            STEAM_PASS=""
            STEAM_AUTH=""
        fi

        # Resolve SteamCMD binary
        STEAMCMD_BIN=""
        for p in /usr/local/bin/steamcmd /opt/steamcmd/steamcmd.sh; do
            if [ -x "$p" ]; then
                STEAMCMD_BIN="$p"
                break
            fi
        done

        if [ -n "${STEAMCMD_BIN}" ]; then
            # Build SteamCMD args
            STEAM_EXTRA=""
            [ -n "${SRCDS_BETAID}" ] && STEAM_EXTRA="${STEAM_EXTRA} -beta ${SRCDS_BETAID}"
            [ -n "${SRCDS_BETAPASS}" ] && STEAM_EXTRA="${STEAM_EXTRA} -betapassword ${SRCDS_BETAPASS}"
            [ "${VALIDATE}" == "1" ] && STEAM_EXTRA="${STEAM_EXTRA} validate"

            ${STEAMCMD_BIN} \
                +force_install_dir /home/container \
                +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
                +app_update ${SRCDS_APPID} ${STEAM_EXTRA} \
                +quit
        else
            echo "WARNING: SteamCMD not found, skipping update."
        fi
    else
        echo "No App ID set. Skipping game server update check."
    fi
else
    echo "Skipping game server update check. AUTO_UPDATE is 0."
fi

# ─── Source 2 Library Path ────────────────────────────────────────────────────
# s&box ships native .so files in bin/linuxsteamrt64/
# These must be on LD_LIBRARY_PATH for the .NET runtime to dlopen them.
if [ -d "/home/container/bin/linuxsteamrt64" ]; then
    export LD_LIBRARY_PATH="/home/container/bin/linuxsteamrt64:${LD_LIBRARY_PATH:-}"
fi

# ─── .NET environment ────────────────────────────────────────────────────────
export DOTNET_ROOT="${DOTNET_ROOT:-/usr/share/dotnet}"
export DOTNET_gcServer=1
export DOTNET_GCHeapHardLimit=0x0

# ─── Replace Startup Variables ───────────────────────────────────────────────
# Pterodactyl/Pelican pass the egg's startup command via $STARTUP with
# {{VARIABLE}} placeholders that need to be converted to ${VARIABLE}.
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo "Starting server..."
echo ":/home/container$ ${MODIFIED_STARTUP}"
eval ${MODIFIED_STARTUP}
