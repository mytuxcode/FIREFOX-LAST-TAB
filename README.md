# 🦊 Prevent Closing Window with Last Tab

## 📘 Overview

By default, **Firefox** and **Google Chrome** close the entire browser window when you close the last remaining tab.

This repo provides two ways to fix that:

- **Firefox** — scripts (Windows PowerShell + Linux/macOS Bash) that set the built-in preference `browser.tabs.closeWindowWithLastTab = false`.
- **Google Chrome** — a Manifest V3 extension (in [`chrome-extension/`](./chrome-extension)) that reproduces the same behavior, since Chrome has no equivalent setting.

In both cases, closing the last tab will **open a new blank tab instead of closing the window** — preventing accidental browser shutdowns.

---

## 🌐 Google Chrome Extension (`chrome-extension/`)

Chrome doesn't expose a setting like Firefox's `closeWindowWithLastTab`, so this is implemented as a small extension. Its background service worker watches tab events and, when you close the **last** tab in a normal window, immediately opens a fresh new tab so the window stays open. A popup lets you toggle the behavior on/off.

### Install (Load Unpacked)

1. Open Chrome and go to `chrome://extensions`.
2. Enable **Developer mode** (top-right toggle).
3. Click **Load unpacked** and select the `chrome-extension/` folder from this repo.
4. The **Keep Last Tab** icon appears in the toolbar. Click it to turn the behavior on or off (on by default).

### How it works

- `manifest.json` — Manifest V3 config; requests only the `storage` permission.
- `background.js` — keeps a live per-window tab count and, on the last tab's removal (when the window isn't already closing), calls `chrome.tabs.create()` to keep the window alive.
- `popup.html` / `popup.css` / `popup.js` — a small on/off switch; the setting is saved to `chrome.storage.sync`.

> **Note:** Unlike Firefox's native preference, this is a best-effort approach using Chrome's extension APIs. Chrome tears the window down asynchronously when the last tab closes, and the extension races to open a new tab before that completes. It works reliably for normal interactive use; very rare edge cases (e.g. the service worker waking from a cold start on the very first close) may still let a window close.

### Files

```
chrome-extension/
├── manifest.json
├── background.js
├── popup.html
├── popup.css
├── popup.js
└── icons/
    ├── icon16.png
    ├── icon48.png
    └── icon128.png
```

---

## 🦊 Firefox Scripts

These scripts set Firefox's built-in preference `browser.tabs.closeWindowWithLastTab = false`.

### 🪟 Windows PowerShell Script (`Set-FirefoxLastTabPref.ps1`)

```powershell
<#
.SYNOPSIS
    Universal PowerShell script to change the Firefox setting
    "browser.tabs.closeWindowWithLastTab" to false.

.DESCRIPTION
    Works across all Windows systems, regardless of username or profile name.
    - Automatically detects all Firefox profiles.
    - Prompts user if multiple profiles are found.
    - Guides users through manual or automatic configuration.
    - Updates prefs.js safely with backup.

.NOTES
    File: Set-FirefoxLastTabPref.ps1
    Compatible: Windows 10 / 11
    Version: 2.0 (Universal Edition)
#>

Clear-Host
Write-Host "---------------------------------------------"
Write-Host "  Firefox: Prevent Closing Window with Last Tab"
Write-Host "---------------------------------------------`n"

$FirefoxAppData = Join-Path $env:APPDATA "Mozilla\Firefox\Profiles"

if (-not (Test-Path $FirefoxAppData)) {
    Write-Host "⚠️  Firefox profile directory not found."
    Write-Host "Please make sure Firefox is installed and opened at least once."
    exit
}

$Profiles = Get-ChildItem -Path $FirefoxAppData -Directory | Sort-Object Name
if (-not $Profiles) {
    Write-Host "⚠️  No profiles found. Please open Firefox once to create one."
    exit
}

if ($Profiles.Count -gt 1) {
    Write-Host "Multiple Firefox profiles detected:`n"
    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        Write-Host "[$($i+1)] $($Profiles[$i].Name)"
    }
    $selection = Read-Host "`nEnter the number for the profile you want to modify"
    if ($selection -match '^\d+$' -and $selection -ge 1 -and $selection -le $Profiles.Count) {
        $ProfilePath = $Profiles[$selection - 1].FullName
    } else {
        Write-Host "❌ Invalid selection. Exiting."
        exit
    }
} else {
    $ProfilePath = $Profiles[0].FullName
}

Write-Host "`n✅ Profile selected:"
Write-Host "   $ProfilePath`n"

Write-Host "-------------------------------------------------------------"
Write-Host "MANUAL METHOD (Optional)"
Write-Host "-------------------------------------------------------------"
Write-Host "1️⃣  Open Firefox"
Write-Host "2️⃣  Type: about:config  and press ENTER"
Write-Host "3️⃣  Click 'Accept the Risk and Continue'"
Write-Host "4️⃣  Search for: browser.tabs.closeWindowWithLastTab"
Write-Host "5️⃣  Toggle the value from TRUE → FALSE`n"

$choice = Read-Host "Would you like to apply this change automatically? (Y/N)"
if ($choice -notmatch '^[Yy]$') {
    Write-Host "`nManual instructions displayed above. Exiting..."
    exit
}

$prefsFile = Join-Path $ProfilePath "prefs.js"
if (-not (Test-Path $prefsFile)) {
    Write-Host "⚠️  prefs.js not found. Please open Firefox once and close it again, then retry."
    exit
}

$backupFile = "$prefsFile.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $prefsFile $backupFile -Force
Write-Host "🗄️  Backup created at: $backupFile`n"

$prefsContent = Get-Content $prefsFile -Raw
if ($prefsContent -match 'browser\.tabs\.closeWindowWithLastTab') {
    $newContent = $prefsContent -replace 'user_pref\("browser\.tabs\.closeWindowWithLastTab", true\);', 'user_pref("browser.tabs.closeWindowWithLastTab", false);'
} else {
    $newContent = $prefsContent + "`nuser_pref(""browser.tabs.closeWindowWithLastTab"", false);"
}

Set-Content -Path $prefsFile -Value $newContent -Encoding UTF8
Write-Host "✅ Preference successfully updated!"
Write-Host "🔄 Please restart Firefox for the changes to take effect.`n"
Write-Host "Script completed successfully."
```

---

### 🐧 Linux/macOS Bash Script (`set_last_tab_pref.sh`)

```bash
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
# Version: 2.0 (Univeral Edition)
# ============================================================

echo "---------------------------------------------"
echo "  Firefox: Prevent Closing Window with Last Tab"
echo "---------------------------------------------"
echo

if [[ "$OSTYPE" == "darwin"* ]]; then
    PROFILE_DIR="$HOME/Library/Application Support/Firefox/Profiles"
else
    PROFILE_DIR="$HOME/.mozilla/firefox"
fi

if [ ! -d "$PROFILE_DIR" ]; then
    echo "⚠️  Firefox profile directory not found."
    echo "Please make sure Firefox is installed and has been opened at least once."
    exit 1
fi

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

echo "-------------------------------------------------------------"
echo "MANUAL METHOD (Optional)"
echo "-------------------------------------------------------------"
echo "1️⃣  Open Firefox"
echo "2️⃣  Type: about:config  and press ENTER"
echo "3️⃣  Click 'Accept the Risk and Continue'"
echo "4️⃣  Search for: browser.tabs.closeWindowWithLastTab"
echo "5️⃣  Toggle the value from TRUE → FALSE"
echo

read -p "Would you like to apply this change automatically? (y/n): " apply_choice
if [[ ! "$apply_choice" =~ ^[Yy]$ ]]; then
    echo
    echo "Manual instructions shown above. Exiting..."
    exit 0
fi

PREF_FILE="$PROFILE_PATH/prefs.js"
if [ ! -f "$PREF_FILE" ]; then
    echo "⚠️  prefs.js not found. Please open Firefox once and close it again, then rerun this script."
    exit 1
fi

BACKUP_FILE="${PREF_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
cp "$PREF_FILE" "$BACKUP_FILE"
echo "🗄️  Backup created at: $BACKUP_FILE"
echo

if grep -q 'browser.tabs.closeWindowWithLastTab' "$PREF_FILE"; then
    sed -i.bak 's/user_pref("browser\.tabs\.closeWindowWithLastTab", true);/user_pref("browser.tabs.closeWindowWithLastTab", false);/' "$PREF_FILE"
else
    echo 'user_pref("browser.tabs.closeWindowWithLastTab", false);' >> "$PREF_FILE"
fi

echo "✅ Preference successfully updated!"
echo "🔄 Please restart Firefox for the changes to take effect."
echo
echo "Script completed successfully."
```

---

## 🧭 How to Run

### 🪟 **Windows (PowerShell)**

1. Save the code as `Set-FirefoxLastTabPref.ps1`  
2. Right-click the file → **Run with PowerShell**, or run manually:
   ```powershell
   .\Set-FirefoxLastTabPref.ps1
   ```
3. Follow the prompts and restart Firefox.

### 🐧 **Linux / macOS (Bash)**

1. Save the code as `set_last_tab_pref.sh`  
2. Make it executable:
   ```bash
   chmod +x set_last_tab_pref.sh
   ```
3. Run it:
   ```bash
   ./set_last_tab_pref.sh
   ```
4. Follow the prompts and restart Firefox.

---

## 🧠 Notes

- Always **close Firefox before running the script** to avoid overwriting preferences.  
- Both scripts automatically **detect your profiles** and create **timestamped backups**.  
- You can re-enable the original behavior by setting:
  ```
  browser.tabs.closeWindowWithLastTab = true
  ```

---

## 🐧 Author

**Maintainer:** [@mytuxcode](https://github.com/mytuxcode)  
If this project helps you, consider starring ⭐ the repository!
