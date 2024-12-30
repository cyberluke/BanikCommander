function Get-BanikCommanderConfig {
    [CmdletBinding()]
    param()

    try {
        # Define configuration path
        $ConfigPath = Join-Path $env:USERPROFILE '.banikcommander'
        $ConfigFile = Join-Path $ConfigPath 'config.json'

        # Check if config exists
        if (-not (Test-Path -Path $ConfigFile)) {
            Write-Verbose "No configuration found at: $ConfigFile"
            Write-Host "Configuration not found. Use Set-OpenAIConfig to configure your API key." -ForegroundColor Yellow
            return $null
        }

        # Read and decrypt configuration
        try {
            $EncryptedConfig = Get-Content -Path $ConfigFile -ErrorAction Stop
            $DecryptedJson = [System.Security.SecureString]::new()
            $DecryptedJson = ConvertTo-SecureString -String $EncryptedConfig
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DecryptedJson)
            $DecryptedConfig = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

            # Parse JSON and validate structure
            $Config = $DecryptedConfig | ConvertFrom-Json

            # Validate configuration
            if (-not $Config.OpenAIKey -or -not $Config.LastUpdated) {
                throw "Invalid configuration structure"
            }

            Write-Verbose "Configuration loaded successfully"
            return $Config
        }
        catch {
            Write-Error "Failed to read or decrypt configuration: $_"
            Write-Host "Configuration appears corrupted. Please reconfigure using Set-OpenAIConfig." -ForegroundColor Red
            return $null
        }
        finally {
            if ($null -ne $BSTR) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            }
        }
    }
    catch {
        Write-Error "Failed to access configuration: $_"
        return $null
    }
}