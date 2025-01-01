# Check if we're in the correct directory
$moduleFile = Join-Path $PSScriptRoot "BanikCommander" "BanikCommander.psm1"
if (-not (Test-Path $moduleFile)) {
    Write-Error "BanikCommander module not found. Make sure you're running this script from the correct directory."
    exit 1
}

# Remove module if it's already loaded
if (Get-Module BanikCommander) {
    Remove-Module BanikCommander -Force
}

# Import the module
try {
    Import-Module $moduleFile -Force -ErrorAction Stop
    Write-Host "BanikCommander module imported successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to import BanikCommander module: $_"
    exit 1
}

# Function to save command to b.ps1
function Save-CommandToFile {
    param (
        [string]$Command,
        [string]$FilePath = "b.ps1"
    )
    
    try {
        Set-Content -Path $FilePath -Value $Command -Force
        Write-Host "`nCommand saved to $FilePath" -ForegroundColor Green
        Write-Host "You can run it using: .\$FilePath" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Failed to save command to file: $_"
    }
}

# If arguments are provided, use preview mode
if ($args.Count -gt 0) {
    $prompt = $args -join " "
    Write-Host "`nPreview mode - Input text:" -ForegroundColor Cyan
    Write-Host $prompt -ForegroundColor Yellow
    
    try {
        Write-Verbose "Calling Start-Banik with preview mode..."
        # Capture the command output
        $result = Start-Banik -TextOnly -Preview -AutoPrompt $prompt -Verbose
        
        Write-Verbose "Result received: $($result | ConvertTo-Json)"
        
        # Check if we got a command back
        if ($result -and $result.GeneratedCommand) {
            Write-Verbose "Command found in result: $($result.GeneratedCommand)"
            # Save the command to b.ps1
            Save-CommandToFile -Command $result.GeneratedCommand
        }
        else {
            Write-Error "No command was generated. Result: $($result | ConvertTo-Json)"
            exit 1
        }
    }
    catch {
        Write-Error "Failed to start BanikCommander in preview mode: $_"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}
else {
    # Regular interactive mode
    try {
        $null = Start-Banik -TextOnly # Suppress the return value in interactive mode
    }
    catch {
        Write-Error "Failed to start BanikCommander: $_"
        exit 1
    }
} 