function Set-OpenAIConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ApiKey
    )

    Write-Host "Configuring OpenAI API key..." -ForegroundColor Cyan

    # Basic validation of API key format
    if (-not ($ApiKey -match '^sk-[a-zA-Z0-9]{48}$')) {
        Write-Warning "The provided API key doesn't match the expected format (sk-...)."
        Write-Host "API key should start with 'sk-' followed by 48 characters." -ForegroundColor Yellow
        $Confirm = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($Confirm -ne "Y") {
            Write-Host "Configuration cancelled." -ForegroundColor Yellow
            return
        }
    }

    # Test if we can create the configuration directory
    $ConfigPath = Join-Path $env:USERPROFILE '.voicecommander'
    if (-not (Test-Path -Path $ConfigPath)) {
        try {
            New-Item -ItemType Directory -Path $ConfigPath -Force | Out-Null
            Write-Verbose "Created configuration directory: $ConfigPath"
        }
        catch {
            Write-Error "Failed to create configuration directory: $_"
            return
        }
    }

    $Result = Set-VoiceCommanderConfig -OpenAIKey $ApiKey
    if ($Result) {
        Write-Host "OpenAI API key configured successfully." -ForegroundColor Green
        Write-Host "You can now use Start-VoiceCommand without specifying the API key." -ForegroundColor Cyan
        Write-Host "Configuration stored securely in $env:USERPROFILE\.voicecommander" -ForegroundColor Gray

        # Verify the configuration can be read back
        $Config = Get-VoiceCommanderConfig
        if ($null -eq $Config) {
            Write-Warning "Configuration was saved but could not be verified. You may need to run Set-OpenAIConfig again."
        }
    }
    else {
        Write-Error "Failed to configure OpenAI API key. Please try again or check the error message above."
    }
}