function Initialize-SpeechRecognition {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Culture = "cs-CZ"  # Default to Czech
    )

    try {
        Add-Type -AssemblyName System.Speech

        # Get installed recognizer info
        $recognizerInfo = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers()
        Write-Verbose "Available recognizers: $($recognizerInfo.Count)"
        
        # Try to find Czech recognizer
        $czechRecognizer = $recognizerInfo | Where-Object { $_.Culture.Name -eq $Culture }
        
        if ($null -eq $czechRecognizer) {
            Write-Warning "Czech recognizer not found. Available cultures:"
            $recognizerInfo | ForEach-Object { 
                Write-Warning "- $($_.Culture.Name) ($($_.Culture.DisplayName))" 
            }
            
            # Fallback to default system culture
            Write-Warning "Falling back to system default recognizer..."
            $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
        } else {
            Write-Verbose "Found Czech recognizer"
            $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine($czechRecognizer)
        }

        # Configure audio input
        $recognizer.SetInputToDefaultAudioDevice()

        # Create a simple grammar
        $choices = New-Object System.Speech.Recognition.Choices
        $choices.Add("exit")
        
        $grammarBuilder = New-Object System.Speech.Recognition.GrammarBuilder
        $grammarBuilder.Culture = $recognizer.RecognizerInfo.Culture
        $grammarBuilder.Append($choices)

        # Create a dictation grammar for free-form speech
        $dictationGrammar = New-Object System.Speech.Recognition.DictationGrammar
        $dictationGrammar.Name = "Dictation"
        
        # Load both grammars
        $recognizer.LoadGrammar($dictationGrammar)
        $grammar = New-Object System.Speech.Recognition.Grammar($grammarBuilder)
        $recognizer.LoadGrammar($grammar)

        Write-Verbose "Speech recognition initialized with culture: $($recognizer.RecognizerInfo.Culture.Name)"
        return $recognizer
    }
    catch {
        Write-Warning "Failed to initialize speech recognition: $($_.Exception.Message)"
        Write-Warning "Make sure you have:"
        Write-Warning "1. Windows Speech Recognition enabled"
        Write-Warning "2. The required language pack installed (Settings -> Time & Language -> Language)"
        Write-Warning "3. A working microphone connected"
        return $null
    }
}