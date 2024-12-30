# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Get the module path
$ModulePath = $PSScriptRoot
Write-Verbose "Module Path: $ModulePath"

# Import all functions
$PublicFunctions = @()
$PrivateFunctions = @()

# Import private functions
$PrivatePath = Join-Path -Path $ModulePath -ChildPath 'Private'
if (Test-Path -Path $PrivatePath) {
    Write-Verbose "Importing private functions from: $PrivatePath"
    $PrivateFiles = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -ErrorAction Stop
    foreach ($File in $PrivateFiles) {
        try {
            Write-Verbose "Importing private function: $($File.Name)"
            . $File.FullName
            $PrivateFunctions += $File.BaseName
        }
        catch {
            Write-Error "Failed to import private function $($File.Name): $_"
            throw
        }
    }
} else {
    Write-Error "Private functions directory not found at: $PrivatePath"
    throw "Module structure is invalid."
}

# Import public functions
$PublicPath = Join-Path -Path $ModulePath -ChildPath 'Public'
if (Test-Path -Path $PublicPath) {
    Write-Verbose "Importing public functions from: $PublicPath"
    $PublicFiles = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -ErrorAction Stop
    foreach ($File in $PublicFiles) {
        try {
            Write-Verbose "Importing public function: $($File.Name)"
            . $File.FullName
            $PublicFunctions += $File.BaseName
        }
        catch {
            Write-Error "Failed to import public function $($File.Name): $_"
            throw
        }
    }
} else {
    Write-Error "Public functions directory not found at: $PublicPath"
    throw "Module structure is invalid."
}

# Export public functions
Write-Verbose "Public functions found: $($PublicFunctions -join ', ')"
Export-ModuleMember -Function $PublicFunctions

# Run environment tests
try {
    $EnvTest = Test-ModuleEnvironment
    Write-Verbose "Environment test results:"
    Write-Verbose "PowerShell Version: $($EnvTest.PowerShellVersion)"
    Write-Verbose "Is Windows: $($EnvTest.IsWindows)"
    Write-Verbose "Platform: $($EnvTest.Platform)"
    Write-Verbose "Speech Available: $($EnvTest.SpeechAvailable)"
    Write-Verbose "Configuration Valid: $($EnvTest.ConfigurationValid)"

    # Display configuration status
    if (-not $EnvTest.ConfigurationValid) {
        Write-Warning "OpenAI API key is not configured. Use Set-OpenAIConfig to set up your API key."
        Write-Host "Example: Set-OpenAIConfig -ApiKey 'your-openai-api-key'" -ForegroundColor Cyan
    }
}
catch {
    Write-Warning "Environment tests failed: $_"
    Write-Warning "Some features may not work correctly."
}