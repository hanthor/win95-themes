# Win95 Themes Installer Guide

This guide documents the automated installer scripts for Win95 Themes, supporting both Flatpak and Native Linux installations.

## 1. Main Installer (`install.sh`)

The `install.sh` script automates the building and installation of themes for Discord, Firefox, Steam, and VS Code.

### Supported Apps & Paths

| App | Flatpak Path | Native Path |
| :--- | :--- | :--- |
| **Discord** | `~/.var/app/com.discordapp.Discord/config/Vencord/themes` | `~/.config/Vencord/themes` or `~/.config/discord` |
| **Vesktop** | `~/.var/app/dev.vencord.Vesktop/config/vesktop/themes` | `~/.config/vesktop/themes` |
| **Firefox** | `~/.var/app/org.mozilla.firefox/.mozilla/firefox` | `~/.mozilla/firefox` |
| **Steam** | `~/.var/app/com.valvesoftware.Steam/.local/share/Steam` | `~/.steam/steam` |
| **VS Code** | `~/.var/app/com.visualstudio.code/config/Code/User` | `~/.config/Code/User` |

### Usage

```bash
./install.sh
```

### Features
- **Auto-Detection**: Checks for both Flatpak and Native paths.
- **Building**: Automatically runs `npm run build` for all targets.
- **Patching**:
    - **Steam**: Attempts to patch `steamui/chunk~2dcc5aaf7.js` (or similar) for custom CSS support.
    - **VS Code**: Updates `settings.json` to include the theme imports. **Backs up** the original settings to `settings.json.bak`.
- **Safety**: Checks for `npm` and `flatpak` (optional) availability.

## 2. fx-autoconfig Installer (`scripts/install_fx_autoconfig.sh`)

This script attempts to install [fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig) to enable advanced customizations (JS scripts) in Firefox.

### Usage

```bash
./scripts/install_fx_autoconfig.sh
```

### Features
- **Native Support**: Installs to standard locations (requires `sudo` for program files).
- **Flatpak Support (Experimental)**:
    - Creates a Flatpak extension at `~/.local/share/flatpak/extension/org.mozilla.firefox.systemconfig`.
    - Copies program files to the extension directory.
    - Installs profile scripts to the detected profile.

## 3. Manual Steps

### Firefox
After running `install.sh`, you may still need to manually configure `fx-autoconfig` if the automated script fails or if you are on a restricted system.
- **Flatpak**: The automated script uses an experimental "systemconfig" extension method. If themes don't load, verify that `about:config` preferences for `toolkit.legacyUserProfileCustomizations.stylesheets` is set to `true`.

### Discord / Vesktop
- Ensure **Vencord** is installed. The script looks for the Vencord themes directory. If you use a different client mod, you may need to manually copy `dist/discord.css`.

### Steam
- The script installs the skin to `skins/Win95`. Select it in Steam Settings -> Interface -> Skin.
- Patching is required for some layout fixes. The script attempts this automatically.

### VS Code
- The script modifies `settings.json`. If you have a complex configuration or use a settings sync extension, verify the changes.
