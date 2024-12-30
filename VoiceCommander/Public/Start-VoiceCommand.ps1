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
        Write-Verbose "Starting Command Processor..."

        # Validate OpenAI API Key
        if ([string]::IsNullOrEmpty($OpenAIKey)) {
            throw "OpenAI API Key is required. Please provide a valid API key."
        }

        # Ensure log directory exists
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
            Write-Verbose "Created log directory: $LogPath"
        }

        Write-Host "Command Processor initialized successfully." -ForegroundColor Green
        Write-Host "Type your commands in natural language. Type 'exit' to quit." -ForegroundColor Cyan
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "- Show me all running processes" -ForegroundColor Cyan
        Write-Host "- List all services" -ForegroundColor Cyan
        Write-Host "- Get computer information" -ForegroundColor Cyan
        Write-Host "- Show Azure AD users" -ForegroundColor Cyan
    }

    process {
        while ($true) {
            try {
                # Get text input
                Write-Host "`nEnter your command (or 'exit' to quit):" -ForegroundColor Cyan
                $InputText = Read-Host

                if ([string]::IsNullOrEmpty($InputText)) {
                    Write-Host "Please enter a command." -ForegroundColor Yellow
                    continue
                }

                # Check for exit command
                if ($InputText.Trim().ToLower() -eq "exit") {
                    Write-Host "Exiting Command Processor..." -ForegroundColor Yellow
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
                $ErrorMessage = "Error processing command: $($_.Exception.Message)"
                Write-Host $ErrorMessage -ForegroundColor Red
                Write-CommandLog -Command "Command Processing Error" -Success $false -Error $ErrorMessage -LogPath $LogPath
            }
        }
    }

    end {
        Write-Host "Command Processor terminated successfully." -ForegroundColor Green
    }
}