function Start-VoiceCommand {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$OpenAIKey,

        [Parameter()]
        [string]$LogPath = "$env:USERPROFILE\VoiceCommander\logs",

        [Parameter()]
        [switch]$TextOnly,

        [Parameter()]
        [switch]$Verbose
    )

    begin {
        Write-Verbose "Starting Voice Commander..."

        # Get API key from parameter or config
        if ([string]::IsNullOrEmpty($OpenAIKey)) {
            Write-Verbose "No API key provided, attempting to load from configuration..."
            $Config = Get-VoiceCommanderConfig
            if ($null -eq $Config -or [string]::IsNullOrEmpty($Config.OpenAIKey)) {
                throw "OpenAI API Key not found. Please configure it using Set-OpenAIConfig first."
            }
            $OpenAIKey = $Config.OpenAIKey
        }

        # Ensure log directory exists
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
            Write-Verbose "Created log directory: $LogPath"
        }

        # Initialize speech recognition if not in text-only mode
        $SpeechEngine = $null
        if (-not $TextOnly) {
            try {
                Write-Verbose "Initializing speech recognition engine..."
                $SpeechEngine = Initialize-SpeechRecognition -ErrorAction Stop
                if ($null -eq $SpeechEngine) {
                    Write-Warning "Speech recognition initialization failed. Falling back to text-only mode."
                    $TextOnly = $true
                } else {
                    Write-Host "Voice recognition active! You can speak your commands." -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Speech recognition not available: $($_.Exception.Message)"
                Write-Warning "Falling back to text-only mode."
                $TextOnly = $true
            }
        }

        Write-Host "Voice Commander initialized successfully." -ForegroundColor Green
        Write-Host "Type 'exit' to quit or press Ctrl+C to terminate." -ForegroundColor Cyan
        Write-Host "`nAvailable commands examples:" -ForegroundColor Yellow
        Write-Host "- Show me all running processes" -ForegroundColor Cyan
        Write-Host "- List all services" -ForegroundColor Cyan
        Write-Host "- Get computer information" -ForegroundColor Cyan
        Write-Host "- Show Azure AD users" -ForegroundColor Cyan
        Write-Host "- Show content of README.md" -ForegroundColor Cyan
    }

    process {
        while ($true) {
            try {
                $InputText = $null

                if ($TextOnly) {
                    Write-Host "`nEnter your command (or 'exit' to quit):" -ForegroundColor Cyan
                    $InputText = Read-Host
                }
                else {
                    Write-Host "`nListening... (Say 'exit' to quit)" -ForegroundColor Cyan
                    $RecognitionResult = $SpeechEngine.Recognize()

                    if ($null -ne $RecognitionResult) {
                        $InputText = $RecognitionResult.Text
                        Write-Host "Recognized: $InputText" -ForegroundColor Yellow
                    }
                }

                if ([string]::IsNullOrEmpty($InputText)) {
                    if ($TextOnly) {
                        Write-Host "Please enter a command." -ForegroundColor Yellow
                    } else {
                        Write-Host "No speech detected, please try again." -ForegroundColor Yellow
                    }
                    continue
                }

                # Check for exit command
                if ($InputText.Trim().ToLower() -eq "exit") {
                    Write-Host "Exiting Voice Commander..." -ForegroundColor Yellow
                    break
                }

                # Convert input to PowerShell command
                Write-Verbose "Converting input to PowerShell command..."
                $CommandResult = Convert-SpeechToCommand -InputText $InputText -OpenAIKey $OpenAIKey

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

                # Execute the command with module auto-installation and output handling
                try {
                    Write-Verbose "Executing command..."
                    $MaxRetries = 2
                    $RetryCount = 0
                    $Success = $false

                    # Pre-execution module check for known modules
                    if ($CommandResult.Command -match 'Azure[AD]*') {
                        Write-Verbose "Azure AD command detected, checking module..."
                        $ModuleInstalled = Install-RequiredModule -ModuleName 'AzureAD'
                        if (-not $ModuleInstalled) {
                            throw "Failed to install AzureAD module"
                        }
                    }

                    while (-not $Success -and $RetryCount -lt $MaxRetries) {
                        try {
                            Write-Verbose "Execution attempt $($RetryCount + 1) of $MaxRetries"

                            # Determine command type and required modules
                            $IsFileOperation = $CommandResult.Command -match '(Get-Content|Out-File|Export-Csv)'
                            Write-Verbose "Is file operation: $IsFileOperation"

                            # Execute command
                            $ExecutionResult = $null
                            Write-Verbose "Executing command: $($CommandResult.Command)"
                            $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                            Write-Verbose "Command executed successfully"

                            # Handle the output based on command type
                            if ($null -ne $ExecutionResult) {
                                Handle-CommandOutput -Command $CommandResult.Command -Result $ExecutionResult -IsFileOperation:$IsFileOperation
                            } else {
                                Write-Host "Command executed successfully but returned no output." -ForegroundColor Yellow
                            }

                            $Success = $true
                            Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                        }
                        catch {
                            $ErrorMessage = $_.Exception.Message
                            Write-Verbose "Execution error: $ErrorMessage"
                            Write-Verbose "Exception type: $($_.Exception.GetType().Name)"

                            if ($ErrorMessage -match "The term '.*' is not recognized") {
                                Write-Verbose "Command not found, attempting module installation..."

                                # Extract module name from command
                                if ($CommandResult.Command -match '^(.*?)-') {
                                    $ModuleName = $Matches[1]
                                    Write-Verbose "Attempting to install module: $ModuleName"

                                    if (Install-RequiredModule -ModuleName $ModuleName) {
                                        Write-Host "Required module installed. Retrying command..." -ForegroundColor Yellow
                                        $RetryCount++
                                        continue
                                    }
                                }
                            }

                            Write-Host "Error executing command: $ErrorMessage" -ForegroundColor Red
                            Write-CommandLog -Command $CommandResult.Command -Success $false -Error $ErrorMessage -LogPath $LogPath
                            break
                        }
                    }
                }
                catch {
                    $ErrorMessage = "Error executing command: $($_.Exception.Message)"
                    Write-Host $ErrorMessage -ForegroundColor Red
                    Write-CommandLog -Command $CommandResult.Command -Success $false -Error $ErrorMessage -LogPath $LogPath
                }
            }
            catch {
                $ErrorMessage = "Error processing command: $($_.Exception.Message)"
                Write-Host $ErrorMessage -ForegroundColor Red
                Write-CommandLog -Command "Command Processing Error" -Success $false -Error $ErrorMessage -LogPath $LogPath
            }
        }
    }

    end {
        if ($null -ne $SpeechEngine) {
            Write-Verbose "Cleaning up speech recognition resources..."
            $SpeechEngine.Dispose()
        }
        Write-Host "Voice Commander terminated successfully." -ForegroundColor Green
    }
}