# Function to check if a command exists
function Test-CommandExists {
    param ($Command)
    
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to install Git for Windows
function Install-Git {
    Write-Host "Git is not installed. Installing Git for Windows..." -ForegroundColor Yellow
    
    # Download Git for Windows
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
    $installerPath = Join-Path $env:TEMP "GitInstaller.exe"
    
    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
        
        # Install Git silently
        Write-Host "Running Git installer..." -ForegroundColor Yellow
        Start-Process -FilePath $installerPath -Args "/VERYSILENT /NORESTART" -Wait
        
        # Clean up
        Remove-Item $installerPath -Force
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Git has been installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Git. Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Main installation process
Write-Host "Starting Banik Commander installation..." -ForegroundColor Cyan

# Check if Git is installed
if (-not (Test-CommandExists "git")) {
    Install-Git
}

# Clone the repository
$repoPath = Join-Path $PWD "BanikCommander"
if (Test-Path $repoPath) {
    Write-Host "Directory already exists. Removing..." -ForegroundColor Yellow
    Remove-Item $repoPath -Recurse -Force
}

Write-Host "Cloning Banik Commander repository..." -ForegroundColor Yellow
try {
    git clone https://github.com/cyberluke/BanikCommander.git
    Write-Host "Repository cloned successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to clone repository. Error: $_" -ForegroundColor Red
    exit 1
}

# Display README content
Write-Host "`nREADME Contents:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
$readmePath = Join-Path $repoPath "README.md"
if (Test-Path $readmePath) {
    Get-Content $readmePath
}
else {
    Write-Host "README.md not found in the repository." -ForegroundColor Yellow
}

Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
Write-Host "You can now import the module using:" -ForegroundColor Cyan
Write-Host "Import-Module .\BanikCommander\BanikCommander.psm1 -Force" -ForegroundColor White 

Write-Host "`nWould you like to install BanikCommander as a permanent module?" -ForegroundColor Yellow
Write-Host "This will:" -ForegroundColor Cyan
Write-Host "1. Copy the module to your PowerShell modules directory" -ForegroundColor Cyan
Write-Host "2. Add it to your PowerShell profile for automatic import" -ForegroundColor Cyan
$response = Read-Host "Install as permanent module? (Y/N)"

if ($response -eq 'Y') {
    try {
        # Run the module installation script
        & (Join-Path $PSScriptRoot "install-module.ps1")
    }
    catch {
        Write-Error "Failed to install module permanently: $_"
        Write-Host "You can still use the module from its current location." -ForegroundColor Yellow
    }
} 