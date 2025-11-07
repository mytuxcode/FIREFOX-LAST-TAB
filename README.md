# 🦊 Firefox — Prevent Closing Window with Last Tab

## 📘 Overview

By default, Firefox closes the entire browser window when you close the last remaining tab.  
This PowerShell script lets you **disable that behavior** by changing the hidden preference:

```
browser.tabs.closeWindowWithLastTab
```

When set to `false`, closing the last tab will **open a new blank tab instead of closing the window** — preventing accidental browser shutdowns.

---

## ⚙️ What the Script Does

The script performs the following steps:

1. **Detects your Firefox profile path** automatically (e.g., `C:\Users\<username>\AppData\Roaming\Mozilla\Firefox\Profiles\xxxx.default-release`).
2. **Displays manual instructions** for users who want to change the setting themselves via `about:config`.
3. **Offers an optional automatic fix**, which:
   - Locates your `prefs.js` file in the Firefox profile directory.
   - Searches for the `browser.tabs.closeWindowWithLastTab` preference.
   - Changes its value from `true` → `false`, or adds it if missing.
4. **Applies the update** to Firefox’s configuration and instructs you to restart Firefox.

---

## 💻 Script Contents

Save the following script as `Set-FirefoxLastTabPref.ps1`:

```powershell
<#
.SYNOPSIS
    Guides or automates changing the "browser.tabs.closeWindowWithLastTab" setting in Firefox.

.DESCRIPTION
    This script locates your Firefox profile folder and offers two options:
    1. Display manual instructions to change the setting in about:config.
    2. Automatically edit the prefs.js file to set the preference to false.

.NOTES
    File: Set-FirefoxLastTabPref.ps1
    Tested on: Windows 10 / 11
#>

Write-Host "---------------------------------------------"
Write-Host "  Firefox: Prevent Closing Window with Last Tab"
Write-Host "---------------------------------------------`n"

# Locate Firefox profile directory
$FirefoxProfilePath = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory | 
    Where-Object { $_.Name -match '\.default' -or $_.Name -match '\.default-release' } | 
    Select-Object -First 1

if (-not $FirefoxProfilePath) {
    Write-Host "⚠️  Firefox profile not found. Please open Firefox once to create it."
    exit
}

Write-Host "✅ Firefox profile found:"
Write-Host "   $($FirefoxProfilePath.FullName)`n"

Write-Host "-------------------------------------------------------------"
Write-Host "MANUAL METHOD:"
Write-Host "-------------------------------------------------------------"
Write-Host "1️⃣  Open Firefox"
Write-Host "2️⃣  In the address bar, type: about:config"
Write-Host "3️⃣  Click 'Accept the Risk and Continue'"
Write-Host "4️⃣  Search for: browser.tabs.closeWindowWithLastTab"
Write-Host "5️⃣  Toggle the value from TRUE → FALSE`n"

# Ask if the user wants to update automatically
$choice = Read-Host "Would you like to automatically apply this change? (Y/N)"
if ($choice -match '^[Yy]$') {
    $prefsFile = Join-Path $FirefoxProfilePath.FullName "prefs.js"
    if (-not (Test-Path $prefsFile)) {
        Write-Host "⚠️  prefs.js file not found. Please open Firefox once and close it."
        exit
    }

    # Read file and check for existing preference
    $prefsContent = Get-Content $prefsFile -Raw
    if ($prefsContent -match 'browser\.tabs\.closeWindowWithLastTab') {
        # Replace true with false
        $newContent = $prefsContent -replace 'user_pref\("browser\.tabs\.closeWindowWithLastTab", true\);', 'user_pref("browser.tabs.closeWindowWithLastTab", false);'
    }
    else {
        # Append new preference
        $newContent = $prefsContent + "`nuser_pref(""browser.tabs.closeWindowWithLastTab"", false);"
    }

    # Write back to file
    Set-Content -Path $prefsFile -Value $newContent -Encoding UTF8
    Write-Host "`n✅ Preference updated successfully!"
    Write-Host "Please restart Firefox for the changes to take effect."
}
else {
    Write-Host "`nManual instructions displayed above."
}

Write-Host "`nDone."
```

---

## 🧭 How to Use

### **Option 1 — Manual Method**

If you prefer to change the setting yourself:

1. Open Firefox.
2. Type `about:config` in the address bar and press **Enter**.
3. Click **Accept the Risk and Continue**.
4. In the search bar, type:
   ```
   browser.tabs.closeWindowWithLastTab
   ```
5. Double-click the entry or click the toggle button to change the value from `true` to `false`.
6. Done! You no longer close the entire window when the last tab is closed.

---

### **Option 2 — Run the PowerShell Script (Automatic Method)**

#### 🪟 Step 1 — Save the Script

- Save the code above into a file named:
  ```
  Set-FirefoxLastTabPref.ps1
  ```

#### 🪟 Step 2 — Allow PowerShell Scripts (if needed)

If you get an error about scripts being disabled, run this once as Administrator:

```powershell
Set-ExecutionPolicy RemoteSigned
```

Press **Y** and **Enter** to confirm.

#### 🪟 Step 3 — Run the Script

1. Right-click the file → **Run with PowerShell**  
   or  
   Open PowerShell, navigate to the folder where the script is saved, then run:

   ```powershell
   .\Set-FirefoxLastTabPref.ps1
   ```

2. When prompted, choose:
   - **Y** to automatically apply the change.
   - **N** to follow the manual instructions instead.

3. Restart Firefox for changes to take effect.

---

## 🧩 Example Output

```
---------------------------------------------
  Firefox: Prevent Closing Window with Last Tab
---------------------------------------------

✅ Firefox profile found:
   C:\Users\demo\AppData\Roaming\Mozilla\Firefox\Profiles\xxxx.default-release

MANUAL METHOD:
1️⃣  Open Firefox
2️⃣  In the address bar, type: about:config
3️⃣  Click 'Accept the Risk and Continue'
4️⃣  Search for: browser.tabs.closeWindowWithLastTab
5️⃣  Toggle the value from TRUE → FALSE

Would you like to automatically apply this change? (Y/N): Y

✅ Preference updated successfully!
Please restart Firefox for the changes to take effect.
```

---

## 🧠 Notes

- The `prefs.js` file is automatically updated in your current Firefox profile.
- Always **close Firefox before running the script** to avoid overwriting preferences.
- If Firefox sync is enabled, this setting may sync across your devices.
- You can re-enable the default behavior by setting the value back to `true`.

---

