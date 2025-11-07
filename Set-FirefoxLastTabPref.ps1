<#
.SYNOPSIS
    Guides or automates changing the "browser.tabs.closeWindowWithLastTab" setting in Firefox.

.DESCRIPTION
    This script locates your Firefox profile folder and offers two options:
    1. Display manual instructions to change the setting in about:config.
    2. Automatically edit the prefs.js file to set the preference to false.

.NOTES
    File: Set-FirefoxLastTabPref.ps1
    Author: Andy
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
