# Create a shortcut in your Windows Start Menu
$shortcutPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Banik.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "pwsh.exe"
$shortcut.Arguments = "-NoExit -Command Start-Banik"
$shortcut.Save()

Write-Host "Shortcut created in Start Menu" -ForegroundColor Green
Write-Host "You can now start Banik Commander from the Windows Start Menu" -ForegroundColor Cyan 