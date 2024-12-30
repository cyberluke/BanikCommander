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
        OpenAIKeyPresent = $false
    }

    # Test Speech capabilities
    try {
        Add-Type -AssemblyName System.Speech -ErrorAction Stop
        $Results.SpeechAvailable = $true
    }
    catch {
        Write-Verbose "Speech capabilities not available: $($_.Exception.Message)"
    }

    # Test OpenAI configuration
    if (-not [string]::IsNullOrEmpty($env:OPENAI_API_KEY)) {
        $Results.OpenAIKeyPresent = $true
    }

    return [PSCustomObject]$Results
}
