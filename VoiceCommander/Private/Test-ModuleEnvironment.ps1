function Test-ModuleEnvironment {
    [CmdletBinding()]
    param()

    $Results = @{
        PowerShellVersion = $PSVersionTable.PSVersion
        IsWindows = $IsWindows
        Platform = [System.Environment]::OSVersion.Platform
        LoadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() | 
            Where-Object { $_.GetName().Name -match 'System.Speech|Microsoft.Speech' } |
            Select-Object -ExpandProperty FullName
        SpeechAvailable = $false
        ConfigurationAvailable = $false
        ConfigurationValid = $false
        ConfigurationPath = Join-Path $env:USERPROFILE '.voicecommander' 'config.json'
    }

    # Test Speech capabilities
    try {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $Results.SpeechAvailable = $true
    }
    catch {
        Write-Verbose "Speech capabilities not available: $($_.Exception.Message)"
        if (-not $IsWindows) {
            Write-Warning "Speech recognition is only supported on Windows platforms."
        }
    }

    # Test configuration
    if (Test-Path -Path $Results.ConfigurationPath) {
        $Results.ConfigurationAvailable = $true
        try {
            $Config = Get-VoiceCommanderConfig
            if ($null -ne $Config -and -not [string]::IsNullOrEmpty($Config.OpenAIKey)) {
                $Results.ConfigurationValid = $true
                Write-Verbose "OpenAI configuration found and valid"
            } else {
                Write-Warning "OpenAI configuration is present but appears invalid"
            }
        }
        catch {
            Write-Warning "Failed to read OpenAI configuration: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "No configuration found at: $($Results.ConfigurationPath)"
        Write-Host "Use 'Set-OpenAIConfig -ApiKey your-api-key' to configure the OpenAI API key" -ForegroundColor Yellow
    }

    return [PSCustomObject]$Results
}