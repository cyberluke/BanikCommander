function Set-VoiceCommanderConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$OpenAIKey
    )

    try {
        # Define configuration path
        $ConfigPath = Join-Path $env:USERPROFILE '.voicecommander'
        $ConfigFile = Join-Path $ConfigPath 'config.json'

        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $ConfigPath)) {
            New-Item -ItemType Directory -Path $ConfigPath -Force | Out-Null
            Write-Verbose "Created configuration directory: $ConfigPath"
        }

        # Validate OpenAI key format (basic check)
        if (-not ($OpenAIKey -match '^sk-[a-zA-Z0-9]{48}$')) {
            Write-Warning "The OpenAI key format appears incorrect. Please verify your API key."
        }

        # Create or update configuration
        $Config = @{
            OpenAIKey = $OpenAIKey
            LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Convert to JSON and save securely
        $Config | ConvertTo-Json | ConvertTo-SecureString -AsPlainText -Force | 
            ConvertFrom-SecureString | 
            Set-Content -Path $ConfigFile -Force

        Write-Host "Configuration saved successfully." -ForegroundColor Green
        Write-Verbose "Configuration saved to: $ConfigFile"
        return $true
    }
    catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
}