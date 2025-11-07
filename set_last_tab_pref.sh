#!/bin/bash
# ============================================================
# Firefox Universal Preference Modifier
# ------------------------------------------------------------
# Purpose:
#   Prevent Firefox from closing the entire window when the
#   last tab is closed by setting:
#       browser.tabs.closeWindowWithLastTab = false
#
# Works on: Linux (Debian, Ubuntu, Mint, Zorin, etc.) and macOS
# Version: 2.0 (Universal Edition)
# ============================================================

echo "---------------------------------------------"
echo "  Firefox: Prevent Closing Window with Last Tab"
echo "---------------------------------------------"
echo

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PROFILE_DIR="$HOME/Library/Application Support/Firefox/Profiles"
else
    PROFILE_DIR="$HOME/.mozilla/firefox"
fi

# Verify Firefox profile directory exists
if [ ! -d "$PROFILE_DIR" ]; then
    echo "⚠️  Firefox profile directory not found."
    echo "Please make sure Firefox is installed and has been opened at least once."
    exit 1
fi

# Detect available profiles
PROFILES=($(find "$PROFILE_DIR" -maxdepth 1 -type d -name "*.default*" -o -name "*.default-release*" | sort))
PROFILE_COUNT=${#PROFILES[@]}

if [ "$PROFILE_COUNT" -eq 0 ]; then
    echo "⚠️  No Firefox profiles found. Please open Firefox once and close it, then rerun this script."
    exit 1
elif [ "$PROFILE_COUNT" -eq 1 ]; then
    PROFILE_PATH="${PROFILES[0]}"
else
    echo "Multiple Firefox profiles detected:"
    i=1
    for profile in "${PROFILES[@]}"; do
        echo "[$i] $profile"
        ((i++))
    done
    echo
    read -p "Enter the number for the profile you want to modify: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$PROFILE_COUNT" ]; then
        PROFILE_PATH="${PROFILES[$((selection-1))]}"
    else
        echo "❌ Invalid selection. Exiting."
        exit 1
    fi
fi

echo
echo "✅ Profile selected:"
echo "   $PROFILE_PATH"
echo

# Show manual instructions
echo "-------------------------------------------------------------"
echo "MANUAL METHOD (Optional)"
echo "-------------------------------------------------------------"
echo "1️⃣  Open Firefox"
echo "2️⃣  Type: about:config  and press ENTER"
echo "3️⃣  Click 'Accept the Risk and Continue'"
echo "4️⃣  Search for: browser.tabs.closeWindowWithLastTab"
echo "5️⃣  Toggle the value from TRUE → FALSE"
echo

# Ask if the user wants to apply automatically
read -p "Would you like to apply this change automatically? (y/n): " apply_choice
if [[ ! "$apply_choice" =~ ^[Yy]$ ]]; then
    echo
    echo "Manual instructions shown above. Exiting..."
    exit 0
fi

# Locate prefs.js
PREF_FILE="$PROFILE_PATH/prefs.js"
if [ ! -f "$PREF_FILE" ]; then
    echo "⚠️  prefs.js not found. Please open Firefox once and close it again, then rerun this script."
    exit 1
fi

# Backup prefs.js before editing
BACKUP_FILE="${PREF_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
cp "$PREF_FILE" "$BACKUP_FILE"
echo "🗄️  Backup created at: $BACKUP_FILE"
echo

# Modify or append preference
if grep -q 'browser.tabs.closeWindowWithLastTab' "$PREF_FILE"; then
    sed -i.bak 's/user_pref("browser\.tabs\.closeWindowWithLastTab", true);/user_pref("browser.tabs.closeWindowWithLastTab", false);/' "$PREF_FILE"
else
    echo 'user_pref("browser.tabs.closeWindowWithLastTab", false);' >> "$PREF_FILE"
fi

echo "✅ Preference successfully updated!"
echo "🔄 Please restart Firefox for the changes to take effect."
echo
echo "Script completed successfully."
