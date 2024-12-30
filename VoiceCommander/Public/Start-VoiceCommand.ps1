function Start-VoiceCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$OpenAIKey,

        [Parameter()]
        [string]$LogPath = "$env:USERPROFILE\VoiceCommander\logs",

        [Parameter()]
        [switch]$Verbose
    )

    begin {
        Write-Verbose "Starting Voice Commander..."

        # Validate OpenAI API Key
        if ([string]::IsNullOrEmpty($OpenAIKey)) {
            throw "OpenAI API Key is required. Please provide a valid API key."
        }

        # Ensure log directory exists
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
            Write-Verbose "Created log directory: $LogPath"
        }

        # Initialize speech recognition
        try {
            Write-Verbose "Initializing speech recognition engine..."
            $SpeechEngine = Initialize-SpeechRecognition
            Write-Host "Voice Commander initialized successfully. Start speaking commands..." -ForegroundColor Green
            Write-Host "Available commands: Get-Process, Get-Service, Get-ComputerInfo, Clear-Host, Help, Exit" -ForegroundColor Cyan
        }
        catch {
            $ErrorMessage = "Failed to initialize speech recognition: $($_.Exception.Message)"
            Write-Error $ErrorMessage
            Write-CommandLog -Command "Initialization" -Success $false -Error $ErrorMessage -LogPath $LogPath
            return
        }
    }

    process {
        while ($true) {
            try {
                # Capture voice input
                Write-Host "`nListening... (Say 'exit' to quit)" -ForegroundColor Cyan
                $RecognitionResult = $SpeechEngine.Recognize()

                if ($null -eq $RecognitionResult) {
                    Write-Verbose "No speech detected, continuing..."
                    continue
                }

                $SpokenText = $RecognitionResult.Text
                Write-Verbose "Recognized text: $SpokenText"

                # Check for exit command
                if ($SpokenText -eq "exit") {
                    Write-Host "Exiting Voice Commander..." -ForegroundColor Yellow
                    break
                }

                # Convert speech to PowerShell command
                Write-Verbose "Converting speech to PowerShell command..."
                $CommandResult = Convert-SpeechToCommand -InputText $SpokenText -OpenAIKey $OpenAIKey

                if ($null -eq $CommandResult) {
                    Write-Host "Could not generate a valid PowerShell command." -ForegroundColor Red
                    continue
                }

                # Display the generated command
                Write-Host "`nGenerated Command:" -ForegroundColor Yellow
                Write-Host $CommandResult.Command -ForegroundColor Cyan

                # Test command safety
                Write-Verbose "Testing command safety..."
                $SafetyCheck = Test-CommandSafety -Command $CommandResult.Command

                if (-not $SafetyCheck.IsSafe) {
                    Write-Host "Warning: $($SafetyCheck.Reason)" -ForegroundColor Yellow
                    $Confirm = Read-Host "Do you want to execute this command? (Y/N)"

                    if ($Confirm -ne "Y") {
                        Write-Host "Command execution cancelled." -ForegroundColor Red
                        Write-CommandLog -Command $CommandResult.Command -Success $false -Error "User cancelled execution" -LogPath $LogPath
                        continue
                    }
                }

                # Execute the command
                try {
                    Write-Verbose "Executing command..."
                    $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                    Write-Host "`nCommand Output:" -ForegroundColor Green
                    $ExecutionResult | Format-Table -AutoSize

                    # Log the successful command
                    Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                }
                catch {
                    $ErrorMessage = "Error executing command: $($_.Exception.Message)"
                    Write-Host $ErrorMessage -ForegroundColor Red
                    Write-CommandLog -Command $CommandResult.Command -Success $false -Error $ErrorMessage -LogPath $LogPath
                }
            }
            catch {
                $ErrorMessage = "Error processing voice command: $($_.Exception.Message)"
                Write-Host $ErrorMessage -ForegroundColor Red
                Write-CommandLog -Command "Voice Processing Error" -Success $false -Error $ErrorMessage -LogPath $LogPath
            }
        }
    }

    end {
        Write-Verbose "Cleaning up resources..."
        $SpeechEngine.Dispose()
        Write-Host "Voice Commander terminated successfully." -ForegroundColor Green
    }
}