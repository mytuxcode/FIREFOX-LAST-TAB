#!/bin/bash
# Purpose: Guide or automate changing the "browser.tabs.closeWindowWithLastTab" setting in Firefox.

# Detect Firefox profile path
PROFILE_PATH=$(find ~/.mozilla/firefox -type d -name "*.default*" -print -quit)

if [ -z "$PROFILE_PATH" ]; then
  echo "Firefox profile not found. Please open Firefox once so it creates one."
  exit 1
fi

echo "Firefox profile detected at: $PROFILE_PATH"
echo

echo "-------------------------------------------------------------"
echo "1. Open Firefox and go to:  about:config"
echo "2. Accept the Risk and Continue."
echo "3. Search for: browser.tabs.closeWindowWithLastTab"
echo "4. Toggle it from TRUE → FALSE"
echo "-------------------------------------------------------------"
echo

read -p "Would you like me to attempt to set it automatically (experimental)? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    PREF_FILE="$PROFILE_PATH/prefs.js"
    if grep -q 'browser.tabs.closeWindowWithLastTab' "$PREF_FILE"; then
        sed -i 's/user_pref("browser.tabs.closeWindowWithLastTab", true);/user_pref("browser.tabs.closeWindowWithLastTab", false);/' "$PREF_FILE"
    else
        echo 'user_pref("browser.tabs.closeWindowWithLastTab", false);' >> "$PREF_FILE"
    fi
    echo "Preference updated! Restart Firefox for changes to take effect."
else
    echo "Manual instructions have been displayed above."
fi

echo
echo "✅ Done."
