# Get the user's PowerShell modules directory
$modulesPath = $env:PSModulePath.Split(';')[0]  # Usually points to Documents\PowerShell\Modules
$moduleDir = Join-Path $modulesPath "BanikCommander"

# Create the module directory if it doesn't exist
if (-not (Test-Path $moduleDir)) {
    New-Item -ItemType Directory -Path $moduleDir -Force
}

# Copy module files
Copy-Item -Path ".\BanikCommander\*" -Destination $moduleDir -Recurse -Force

# Create or update PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent

# Create profile directory if it doesn't exist
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

# Add module import to profile if not already present
$importCommand = "Import-Module BanikCommander -ErrorAction SilentlyContinue"
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath
    if ($profileContent -notcontains $importCommand) {
        Add-Content -Path $profilePath -Value "`n$importCommand"
    }
} else {
    Set-Content -Path $profilePath -Value $importCommand
}

Write-Host "BanikCommander module installed successfully!" -ForegroundColor Green
Write-Host "The module will be automatically imported in new PowerShell sessions." -ForegroundColor Cyan
Write-Host "You can also manually import it using: Import-Module BanikCommander" -ForegroundColor Cyan 