function Initialize-SpeechRecognition {
    [CmdletBinding()]
    param()

    try {
        # Load System.Speech assembly
        Add-Type -AssemblyName System.Speech

        # Create and configure the speech recognition engine
        $SpeechEngine = New-Object System.Speech.Recognition.SpeechRecognitionEngine

        # Configure the input
        $SpeechEngine.SetInputToDefaultAudioDevice()

        # Create a simple grammar for basic commands
        $Choices = New-Object System.Speech.Recognition.Choices
        $Choices.Add("exit")
        $Choices.Add("quit")
        $Choices.Add("stop")

        # Build grammar
        $GrammarBuilder = New-Object System.Speech.Recognition.GrammarBuilder
        $GrammarBuilder.Append($Choices)
        $Grammar = New-Object System.Speech.Recognition.Grammar($GrammarBuilder)

        # Load the grammar
        $SpeechEngine.LoadGrammar($Grammar)

        # Also load a dictation grammar for free-form speech
        $DictationGrammar = New-Object System.Speech.Recognition.DictationGrammar
        $SpeechEngine.LoadGrammar($DictationGrammar)

        Write-Verbose "Speech recognition engine initialized successfully"
        return $SpeechEngine
    }
    catch {
        $ErrorMessage = "Failed to initialize speech recognition: $($_.Exception.Message)"
        Write-Warning $ErrorMessage

        if ($_.Exception.GetType().Name -eq "PlatformNotSupportedException") {
            Write-Warning "Speech recognition is only supported on Windows platforms."
        }

        return $null
    }
}