# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Get the module path
$ModulePath = $PSScriptRoot
Write-Verbose "Module Path: $ModulePath"

# Import private functions
Write-Verbose "Importing private functions from: $ModulePath\Private"
$PrivateFunctions = Get-ChildItem -Path "$ModulePath\Private\*.ps1" -ErrorAction SilentlyContinue

foreach ($Private in $PrivateFunctions) {
    try {
        Write-Verbose "Importing private function: $($Private.Name)"
        . $Private.FullName
    }
    catch {
        Write-Error "Failed to import private function $($Private.Name): $_"
    }
}

# Import public functions
Write-Verbose "Importing public functions from: $ModulePath\Public"
$PublicFunctions = Get-ChildItem -Path "$ModulePath\Public\*.ps1" -ErrorAction SilentlyContinue

foreach ($Public in $PublicFunctions) {
    try {
        Write-Verbose "Importing public function: $($Public.Name)"
        . $Public.FullName
    }
    catch {
        Write-Error "Failed to import public function $($Public.Name): $_"
    }
}

# Export public functions
$PublicFunctions | ForEach-Object {
    Export-ModuleMember -Function $_.BaseName
}

# Export any aliases
Export-ModuleMember -Alias *

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