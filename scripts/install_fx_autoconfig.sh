#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log "Downloading fx-autoconfig..."
git clone --depth 1 https://github.com/MrOtherGuy/fx-autoconfig.git "$TEMP_DIR/fx-autoconfig"

# --- Flatpak Installation ---
FIREFOX_FLATPAK_ID="org.mozilla.firefox"
FLATPAK_USER_DIR="$HOME/.local/share/flatpak"
EXTENSION_DIR="$FLATPAK_USER_DIR/extension/$FIREFOX_FLATPAK_ID.systemconfig/x86_64/stable"

if flatpak list | grep -q "$FIREFOX_FLATPAK_ID"; then
    log "Detected Firefox Flatpak ($FIREFOX_FLATPAK_ID)"
    
    # 1. Install "Program" files (The tricky part)
    log "Attempting to install systemconfig extension for Flatpak..."
    mkdir -p "$EXTENSION_DIR"
    
    # Copy program files to the extension directory
    # The extension mounts to /app/etc/firefox (usually) or somewhere similar.
    # We copy the contents of 'program' to the root of the extension.
    cp -r "$TEMP_DIR/fx-autoconfig/program/"* "$EXTENSION_DIR/"
    
    log "Extension files copied to $EXTENSION_DIR"
    warn "You may need to enable this extension or ensure your Flatpak configuration allows it."
    warn "If this doesn't work, fx-autoconfig might not be supported on your Flatpak setup."

    # 2. Install Profile files
    FIREFOX_DATA_DIR="$HOME/.var/app/$FIREFOX_FLATPAK_ID/.mozilla/firefox"
    PROFILES_INI="$FIREFOX_DATA_DIR/profiles.ini"
    
    if [ -f "$PROFILES_INI" ]; then
        PROFILE_PATH=$(grep -E "^Path=" "$PROFILES_INI" | head -n 1 | cut -d= -f2)
        FULL_PROFILE_PATH="$FIREFOX_DATA_DIR/$PROFILE_PATH"
        CHROME_DIR="$FULL_PROFILE_PATH/chrome"
        
        log "Installing profile files to $CHROME_DIR..."
        mkdir -p "$CHROME_DIR"
        cp -r "$TEMP_DIR/fx-autoconfig/profile/chrome/"* "$CHROME_DIR/"
        log "Profile files installed."
    else
        warn "Could not find profiles.ini for Flatpak Firefox."
    fi
else
    log "Firefox Flatpak not found (or at least not $FIREFOX_FLATPAK_ID)."
fi

# --- Native Installation ---
# Try to detect native firefox install location
POSSIBLE_LOCATIONS=(
    "/usr/lib/firefox"
    "/usr/lib64/firefox"
    "/opt/firefox"
    "/usr/local/lib/firefox"
)

FOUND_LOC=""
for loc in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$loc" ] && [ -f "$loc/firefox" ]; then
        FOUND_LOC="$loc"
        break
    fi
done

if [ -n "$FOUND_LOC" ]; then
    log "Detected Native Firefox at $FOUND_LOC"
    log "Installing fx-autoconfig program files (requires sudo)..."
    
    # We need to copy program/config.js to $FOUND_LOC
    # and program/defaults/pref/config-prefs.js to $FOUND_LOC/defaults/pref
    
    if sudo cp "$TEMP_DIR/fx-autoconfig/program/config.js" "$FOUND_LOC/"; then
        log "Copied config.js"
    else
        error "Failed to copy config.js"
    fi
    
    if sudo cp "$TEMP_DIR/fx-autoconfig/program/defaults/pref/config-prefs.js" "$FOUND_LOC/defaults/pref/"; then
        log "Copied config-prefs.js"
    else
        error "Failed to copy config-prefs.js"
    fi
    
    # Profile files for Native
    NATIVE_PROFILES_INI="$HOME/.mozilla/firefox/profiles.ini"
    if [ -f "$NATIVE_PROFILES_INI" ]; then
        PROFILE_PATH=$(grep -E "^Path=" "$NATIVE_PROFILES_INI" | head -n 1 | cut -d= -f2)
        FULL_PROFILE_PATH="$HOME/.mozilla/firefox/$PROFILE_PATH"
        CHROME_DIR="$FULL_PROFILE_PATH/chrome"
        
        log "Installing profile files to $CHROME_DIR..."
        mkdir -p "$CHROME_DIR"
        cp -r "$TEMP_DIR/fx-autoconfig/profile/chrome/"* "$CHROME_DIR/"
        log "Profile files installed."
    fi
else
    log "Native Firefox installation not found in standard locations."
    log "If you have a native install, please manually copy the files from the fx-autoconfig repo."
fi

log "fx-autoconfig installation attempt complete."
log "Please restart Firefox and check if it works."
log "You may need to clear the startup cache (delete 'startupCache' folder in your profile)."
