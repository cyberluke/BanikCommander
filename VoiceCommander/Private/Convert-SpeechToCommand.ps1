function Convert-SpeechToCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$InputText,
        
        [Parameter(Mandatory)]
        [string]$OpenAIKey
    )

    try {
        # Clean up input text
        $CleanedText = $InputText.Trim()

        # Generate PowerShell command using OpenAI
        $GeneratedCommand = Invoke-OpenAIRequest -InputText $CleanedText -ApiKey $OpenAIKey

        if ([string]::IsNullOrEmpty($GeneratedCommand)) {
            Write-Warning "No command was generated from the input text"
            return $null
        }

        # Create result object
        $Result = @{
            OriginalText = $CleanedText
            Command = $GeneratedCommand
        }

        return $Result
    }
    catch {
        Write-Error "Failed to convert speech to command: $_"
        return $null
    }
}
