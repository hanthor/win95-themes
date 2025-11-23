#!/bin/bash
set -e

# Paths - Flatpak
DISCORD_FLATPAK="$HOME/.var/app/com.discordapp.Discord"
VESKTOP_FLATPAK="$HOME/.var/app/dev.vencord.Vesktop"
FIREFOX_FLATPAK="$HOME/.var/app/org.mozilla.firefox"
STEAM_FLATPAK="$HOME/.var/app/com.valvesoftware.Steam"
VSCODE_FLATPAK="$HOME/.var/app/com.visualstudio.code"

# Paths - Native
DISCORD_NATIVE="$HOME/.config/discord" # Vencord usually injects here or in ~/.config/Vencord
VENCORD_NATIVE="$HOME/.config/Vencord"
VESKTOP_NATIVE="$HOME/.config/vesktop"
FIREFOX_NATIVE="$HOME/.mozilla/firefox"
STEAM_NATIVE="$HOME/.steam/steam"
VSCODE_NATIVE="$HOME/.config/Code"

REPO_DIR=$(pwd)
DIST_DIR="$REPO_DIR/dist"

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

# Check requirements
if ! command -v npm &> /dev/null; then
    error "npm is not installed. Please install Node.js and npm."
    exit 1
fi

# Build themes
log "Building themes..."
npm install
npm run build steam
npm run build discord
npm run build vscode
npm run build firefox agent
npm run build firefox author
npm run build firefox global

# --- Discord ---
install_discord() {
    local target_dir="$1"
    local name="$2"
    
    if [ -d "$target_dir" ]; then
        log "Installing Discord theme for $name..."
        cp "$DIST_DIR/discord.css" "$target_dir/win95.css"
        log "Discord theme installed to $target_dir/win95.css"
    fi
}

# Flatpak Discord (Vencord)
if [ -d "$DISCORD_FLATPAK/config/Vencord/themes" ]; then
    install_discord "$DISCORD_FLATPAK/config/Vencord/themes" "Discord (Flatpak)"
fi

# Flatpak Vesktop
if [ -d "$VESKTOP_FLATPAK/config/vesktop/themes" ]; then
    install_discord "$VESKTOP_FLATPAK/config/vesktop/themes" "Vesktop (Flatpak)"
fi

# Native Vencord
if [ -d "$VENCORD_NATIVE/themes" ]; then
    install_discord "$VENCORD_NATIVE/themes" "Vencord (Native)"
fi

# Native Vesktop
if [ -d "$VESKTOP_NATIVE/themes" ]; then
    install_discord "$VESKTOP_NATIVE/themes" "Vesktop (Native)"
fi


# --- Firefox ---
install_firefox() {
    local profiles_ini="$1"
    local base_dir="$2"
    local name="$3"

    if [ -f "$profiles_ini" ]; then
        log "Installing Firefox theme for $name..."
        # Find default profile
        PROFILE_PATH=$(grep -E "^Path=" "$profiles_ini" | head -n 1 | cut -d= -f2)
        FULL_PROFILE_PATH="$base_dir/$PROFILE_PATH"
        CHROME_DIR="$FULL_PROFILE_PATH/chrome"
        
        mkdir -p "$CHROME_DIR/CSS"
        mkdir -p "$CHROME_DIR/JS"
        
        cp "$DIST_DIR/firefox_global.css" "$CHROME_DIR/CSS/firefox_global.uc.css"
        cp "$DIST_DIR/firefox_agent.css" "$CHROME_DIR/CSS/win95_agent.uc.css"
        cp "$DIST_DIR/firefox_author.css" "$CHROME_DIR/CSS/win95_author.uc.css"
        # cp "$DIST_DIR/firefox_content.css" "$CHROME_DIR/userContent.css" # File does not exist
        cp "$DIST_DIR/firefox_author.css" "$CHROME_DIR/userChrome.css"
        
        cp "$REPO_DIR/src/firefox/win95_main.uc.mjs" "$CHROME_DIR/JS/"
        
        log "Firefox theme files copied to $CHROME_DIR"
        warn "NOTE: You still need to install fx-autoconfig for the theme to work fully."
    fi
}

# Flatpak Firefox
if [ -d "$FIREFOX_FLATPAK" ]; then
    install_firefox "$FIREFOX_FLATPAK/.mozilla/firefox/profiles.ini" "$FIREFOX_FLATPAK/.mozilla/firefox" "Firefox (Flatpak)"
fi

# Native Firefox
if [ -d "$FIREFOX_NATIVE" ]; then
    install_firefox "$FIREFOX_NATIVE/profiles.ini" "$FIREFOX_NATIVE" "Firefox (Native)"
fi


# --- Steam ---
install_steam() {
    local steam_root="$1"
    local name="$2"
    
    log "Installing Steam theme for $name..."
    SKIN_DIR="$steam_root/skins/Win95"
    mkdir -p "$SKIN_DIR/resource"
    cp "$DIST_DIR/steam.css" "$SKIN_DIR/resource/webkit.css"
    log "Steam skin installed to $SKIN_DIR"
    
    # Patch Steam
    STEAMUI_DIR="$steam_root/steamui"
    # Try to find chunk file
    FOUND_CHUNK=$(find "$STEAMUI_DIR" -name "chunk~*.js" | grep "2dcc5aaf7" | head -n 1 || true)
    
    if [ -n "$FOUND_CHUNK" ]; then
         log "Found chunk file at $FOUND_CHUNK. Patching..."
         ./scripts/patch steam "$FOUND_CHUNK"
    else
         warn "Steam UI chunk file not found in $STEAMUI_DIR. Skipping patch."
    fi
}

# Flatpak Steam
if [ -d "$STEAM_FLATPAK/.local/share/Steam" ]; then
    install_steam "$STEAM_FLATPAK/.local/share/Steam" "Steam (Flatpak)"
fi

# Native Steam
if [ -d "$STEAM_NATIVE" ]; then
    install_steam "$STEAM_NATIVE" "Steam (Native)"
fi


# --- VS Code ---
install_vscode() {
    local config_dir="$1"
    local name="$2"
    
    log "Installing VS Code theme for $name..."
    THEME_INSTALL_DIR="$config_dir/User/win95-themes"
    mkdir -p "$THEME_INSTALL_DIR"
    
    cp "$DIST_DIR/vscode.css" "$THEME_INSTALL_DIR/"
    cp "$REPO_DIR/src/shared++/ElementUtils.js" "$THEME_INSTALL_DIR/"
    cp "$REPO_DIR/src/vscode/vscode.js" "$THEME_INSTALL_DIR/"
    
    SETTINGS_FILE="$config_dir/User/settings.json"
    
    if [ -f "$SETTINGS_FILE" ]; then
        log "Updating VS Code settings.json..."
        
        node -e "
        const fs = require('fs');
        const path = '$SETTINGS_FILE';
        const themeDir = '$THEME_INSTALL_DIR';
        
        try {
            // Backup settings.json
            fs.copyFileSync(path, path + '.bak');
            console.log('Backed up settings.json to ' + path + '.bak');

            const content = fs.readFileSync(path, 'utf8');
            // Use eval to parse JSONC (JSON with comments/trailing commas)
            const settings = eval('(' + content + ')');
            
            settings['custom-ui-style.external.imports'] = [
                \`file://\${themeDir}/vscode.css\`,
                \`file://\${themeDir}/ElementUtils.js\`,
                \`file://\${themeDir}/vscode.js\`
            ];
            
            settings['editor.scrollbar.arrowSize'] = 16;
            settings['editor.scrollbar.vertical'] = 'visible';
            settings['editor.scrollbar.verticalHasArrows'] = true;
            settings['editor.scrollbar.horizontalHasArrows'] = true;
            settings['terminal.integrated.cursorStyle'] = 'underline';
            settings['terminal.integrated.fontFamily'] = 'MS Gothic';
            settings['terminal.integrated.fontSize'] = 12;
            settings['window.titleBarStyle'] = 'native';
            settings['window.dialogStyle'] = 'custom';
            settings['window.menuStyle'] = 'custom';
            settings['breadcrumbs.enabled'] = false;
            settings['explorer.compactFolders'] = false;
            settings['editor.roundedSelection'] = false;
            settings['workbench.editor.tabSizing'] = 'shrink';
            settings['workbench.editor.wrapTabs'] = true;
            
            fs.writeFileSync(path, JSON.stringify(settings, null, '\t'));
            console.log('Settings updated successfully.');
        } catch (e) {
            console.error('Error updating settings:', e);
            process.exit(1);
        }
        "
    else
        warn "VS Code settings.json not found at $SETTINGS_FILE"
    fi
}

# Flatpak VS Code
if [ -d "$VSCODE_FLATPAK/config/Code" ]; then
    install_vscode "$VSCODE_FLATPAK/config/Code" "VS Code (Flatpak)"
fi

# Native VS Code
if [ -d "$VSCODE_NATIVE" ]; then
    install_vscode "$VSCODE_NATIVE" "VS Code (Native)"
fi

log "Installation complete! Please restart your apps."
