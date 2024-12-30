function Initialize-SpeechRecognition {
    [CmdletBinding()]
    param()

    try {
        # Check if System.Speech assembly is available
        if (-not ('System.Speech.Recognition.SpeechRecognitionEngine' -as [Type])) {
            Write-Verbose "Loading System.Speech assembly..."
            Add-Type -AssemblyName System.Speech
        }

        Write-Verbose "Creating speech recognition engine..."
        $SpeechEngine = New-Object System.Speech.Recognition.SpeechRecognitionEngine

        Write-Verbose "Setting input to default audio device..."
        $SpeechEngine.SetInputToDefaultAudioDevice()

        # Create grammar with common PowerShell commands
        Write-Verbose "Creating speech recognition grammar..."
        $Choices = New-Object System.Speech.Recognition.Choices
        $CommonCommands = @(
            "exit",
            "get process",
            "get service",
            "get computer info",
            "clear host",
            "help"
        )
        foreach ($Command in $CommonCommands) {
            $Choices.Add($Command)
        }

        # Add wildcard grammar for general commands
        $GrammarBuilder = New-Object System.Speech.Recognition.GrammarBuilder
        $GrammarBuilder.Append($Choices)
        $GrammarBuilder.AppendWildcard()

        Write-Verbose "Loading grammar..."
        $Grammar = New-Object System.Speech.Recognition.Grammar($GrammarBuilder)
        $SpeechEngine.LoadGrammar($Grammar)

        Write-Verbose "Speech recognition engine initialized successfully."
        return $SpeechEngine
    }
    catch {
        $ErrorMessage = "Failed to initialize speech recognition: $($_.Exception.Message)"
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
}