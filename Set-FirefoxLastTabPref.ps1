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

# Step 1: Detect Firefox installation
$FirefoxAppData = Join-Path $env:APPDATA "Mozilla\Firefox\Profiles"

if (-not (Test-Path $FirefoxAppData)) {
    Write-Host "⚠️  Firefox profile directory not found."
    Write-Host "Please make sure Firefox is installed and opened at least once."
    exit
}

# Step 2: Find all Firefox profiles
$Profiles = Get-ChildItem -Path $FirefoxAppData -Directory | Sort-Object Name
if (-not $Profiles) {
    Write-Host "⚠️  No profiles found. Please open Firefox once to create one."
    exit
}

# Step 3: If multiple profiles, ask which one to modify
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

# Step 4: Display manual instructions
Write-Host "-------------------------------------------------------------"
Write-Host "MANUAL METHOD (Optional)"
Write-Host "-------------------------------------------------------------"
Write-Host "1️⃣  Open Firefox"
Write-Host "2️⃣  Type: about:config  and press ENTER"
Write-Host "3️⃣  Click 'Accept the Risk and Continue'"
Write-Host "4️⃣  Search for: browser.tabs.closeWindowWithLastTab"
Write-Host "5️⃣  Toggle the value from TRUE → FALSE`n"

# Step 5: Ask if user wants to automate
$choice = Read-Host "Would you like to apply this change automatically? (Y/N)"
if ($choice -notmatch '^[Yy]$') {
    Write-Host "`nManual instructions displayed above. Exiting..."
    exit
}

# Step 6: Locate prefs.js
$prefsFile = Join-Path $ProfilePath "prefs.js"
if (-not (Test-Path $prefsFile)) {
    Write-Host "⚠️  prefs.js not found. Please open Firefox and close it again, then retry."
    exit
}

# Step 7: Create a backup before modifying
$backupFile = "$prefsFile.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $prefsFile $backupFile -Force
Write-Host "🗄️  Backup created at: $backupFile`n"

# Step 8: Modify or add preference
$prefsContent = Get-Content $prefsFile -Raw
if ($prefsContent -match 'browser\.tabs\.closeWindowWithLastTab') {
    $newContent = $prefsContent -replace 'user_pref\("browser\.tabs\.closeWindowWithLastTab", true\);', 'user_pref("browser.tabs.closeWindowWithLastTab", false);'
} else {
    $newContent = $prefsContent + "`nuser_pref(""browser.tabs.closeWindowWithLastTab"", false);"
}

# Step 9: Write changes
Set-Content -Path $prefsFile -Value $newContent -Encoding UTF8
Write-Host "✅ Preference successfully updated!"
Write-Host "🔄 Please restart Firefox for the changes to take effect.`n"
Write-Host "Script completed successfully."
