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
    $PrivateFiles = Get-ChildItem -Path $PrivatePath -Filter '*.ps1'
    foreach ($File in $PrivateFiles) {
        try {
            Write-Verbose "Importing private function: $($File.FullName)"
            . $File.FullName
            $PrivateFunctions += $File.BaseName
        }
        catch {
            Write-Error "Failed to import private function $($File.FullName): $_"
            throw
        }
    }
}

# Import public functions
$PublicPath = Join-Path -Path $ModulePath -ChildPath 'Public'
if (Test-Path -Path $PublicPath) {
    $PublicFiles = Get-ChildItem -Path $PublicPath -Filter '*.ps1'
    foreach ($File in $PublicFiles) {
        try {
            Write-Verbose "Importing public function: $($File.FullName)"
            . $File.FullName
            $PublicFunctions += $File.BaseName
        }
        catch {
            Write-Error "Failed to import public function $($File.FullName): $_"
            throw
        }
    }
}

# Export public functions
Write-Verbose "Exporting public functions: $($PublicFunctions -join ', ')"
Export-ModuleMember -Function @('Start-VoiceCommand', 'Set-OpenAIConfig', 'Get-VoiceCommanderConfig')

# Run environment tests
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