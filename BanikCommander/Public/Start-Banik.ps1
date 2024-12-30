function Start-Banik {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$OpenAIKey,

        [Parameter()]
        [string]$LogPath = "$env:USERPROFILE\BanikCommander\logs",

        [Parameter()]
        [switch]$TextOnly

    )

    begin {
        Write-Verbose "Starting BANIK Commander..."

        

        # Initialize required modules and track connection state
        Write-Verbose "Initializing required modules..."
        Initialize-RequiredModules
        $script:GraphConnected = $false

        # Get API key from parameter or config
        if ([string]::IsNullOrEmpty($OpenAIKey)) {
            Write-Verbose "No API key provided, attempting to load from configuration..."
            $Config = Get-BanikCommanderConfig
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

        # Display image using terminal graphics

                # Fallback to ASCII art
                Write-Host @"
    ____              _ _    
   |  _ \            (_) |   
   | |_) | __ _ _ __  _| | __
   |  _ < / _' | '_ \| | |/ /
   | |_) | (_| | | | | |   < 
   |____/ \__,_|_| |_|_|_|\_\
   Commander v1.0
"@ -ForegroundColor Cyan
          
        Write-Host "BANIK Commander initialized successfully." -ForegroundColor Green
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
                    Write-Host "Exiting BANIK Commander..." -ForegroundColor Yellow
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

                try {
                    Write-Verbose "Executing command..."
                    $MaxRetries = 2
                    $RetryCount = 0
                    $Success = $false

                    while (-not $Success -and $RetryCount -lt $MaxRetries) {
                        try {
                            Write-Verbose "Execution attempt $($RetryCount + 1) of $MaxRetries"
                            $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                            
                            # Check if the result contains an authentication error
                            if (-not $script:GraphConnected -and $ExecutionResult -match "Authentication needed|Please call Connect-MgGraph|Get-Mg\w+_\w+: Authentication needed") {
                                Write-Host "Authentication required. Attempting to connect..." -ForegroundColor Yellow
                                
                                # Disconnect existing session first
                                Write-Host "Disconnecting existing Graph session..." -ForegroundColor Cyan
                                Disconnect-MgGraph -ErrorAction SilentlyContinue
                                
                                $graphScopes = @(
                                    "User.Read.All",
                                    "Directory.Read.All",
                                    "Group.Read.All",
                                    "Organization.Read.All",
                                    "Application.Read.All",
                                    "Directory.AccessAsUser.All",
                                    "User.ReadWrite.All",
                                    "Directory.ReadWrite.All",
                                    "Group.ReadWrite.All",
                                    "Application.ReadWrite.All",
                                    "RoleManagement.ReadWrite.Directory"
                                )
                                Connect-MgGraph -Scopes $graphScopes
                                $script:GraphConnected = $true
                                Write-Host "Successfully connected to Microsoft Graph with enhanced permissions" -ForegroundColor Green
                                
                                # Retry the command
                                Write-Host "Retrying command..." -ForegroundColor Yellow
                                $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                            }

                            Write-Verbose "Command executed successfully"
                            $Success = $true

                            # Handle the output
                            Handle-CommandOutput -Command $CommandResult.Command -Result $ExecutionResult
                            Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                        }
                        catch {
                            $ErrorMessage = $_.Exception.Message
                            $ErrorType = $_.Exception.GetType().Name
                            Write-Verbose "Execution error: $ErrorMessage"
                            Write-Verbose "Exception type: $ErrorType"

                            # Handle different types of errors
                            switch -Regex ($ErrorMessage) {
                                # Missing module/cmdlet error
                                "The term '([\w\-\.]+)' is not recognized" {
                                    $CommandName = $Matches[1]
                                    Write-Verbose "Analyzing unrecognized command: $CommandName"

                                    # If it's an Azure AD command and we're in PowerShell Core, convert the command
                                    if ($PSVersionTable.PSEdition -eq 'Core' -and ($CommandResult.Command -match 'AzureAD' -or $CommandName -match 'AzureAD')) {
                                        Write-Host "Converting AzureAD command to Microsoft.Graph equivalent..." -ForegroundColor Yellow
                                        $graphCommand = Convert-SpeechToCommand -InputText "Convert this Azure AD command to Microsoft Graph equivalent: $($CommandResult.Command)" -OpenAIKey $OpenAIKey
                                        if ($graphCommand) {
                                            $CommandResult.Command = $graphCommand.Command
                                            Write-Host "Converted command: $($CommandResult.Command)" -ForegroundColor Cyan
                                            
                                            # Update the command name for module detection
                                            $CommandName = if ($graphCommand.Command -match '(Get-Mg\w+)') { $Matches[1] } else { $CommandName }
                                            
                                            # Ensure we're connected to Graph before executing
                                            try {
                                                if ($script:GraphConnected -eq $false) {
                                                    Write-Host "Ensuring Graph connection..." -ForegroundColor Yellow
                                                    Disconnect-MgGraph -ErrorAction SilentlyContinue
                                                    $graphScopes = @(
                                                        "User.Read.All",
                                                        "Directory.Read.All",
                                                        "Group.Read.All",
                                                        "Organization.Read.All",
                                                        "Application.Read.All",
                                                        "Directory.AccessAsUser.All",
                                                        "User.ReadWrite.All",
                                                        "Directory.ReadWrite.All",
                                                        "Group.ReadWrite.All",
                                                        "Application.ReadWrite.All",
                                                        "RoleManagement.ReadWrite.Directory"
                                                    )
                                                    Connect-MgGraph -Scopes $graphScopes
                                                    $script:GraphConnected = $true
                                                }
                                                # Execute the converted command
                                                Write-Host "Executing converted command..." -ForegroundColor Yellow
                                                $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                                                $Success = $true
                                                
                                                # Handle the output
                                                Handle-CommandOutput -Command $CommandResult.Command -Result $ExecutionResult
                                                Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                                                continue
                                            }
                                            catch {
                                                Write-Warning "Failed to execute converted command: $_"
                                                $Success = $false
                                            }
                                        }
                                    }

                                    $ModuleName = switch -Regex ($CommandName) {
                                        'Get-Mg.*|Connect-Mg.*' { 'Microsoft.Graph'; break }
                                        'Msol.*' { 'MSOnline'; break }
                                        'Graph.*' { 'Microsoft.Graph'; break }
                                        'Team.*' { 'MicrosoftTeams'; break }
                                        'SPO.*' { 'Microsoft.Online.SharePoint.PowerShell'; break }
                                        default { $null }
                                    }

                                    if ([string]::IsNullOrEmpty($ModuleName)) {
                                        Write-Host "Detected missing module: $ModuleName" -ForegroundColor Yellow
                                        Write-Host "Attempting to install required module..." -ForegroundColor Cyan
                                        
                                        try {
                                            # First try to import if already installed
                                            if (Get-Module -ListAvailable -Name $ModuleName) {
                                                Import-Module -Name $ModuleName -Force -ErrorAction Stop
                                                Write-Host "Successfully imported existing module: $ModuleName" -ForegroundColor Green
                                            } else {
                                                Install-RequiredModule -ModuleName $ModuleName -ErrorAction Stop
                                                Write-Host "Successfully installed module: $ModuleName" -ForegroundColor Green
                                            }
                                            Write-Host "Retrying command..." -ForegroundColor Yellow
                                            $RetryCount++
                                            # Rerun the original command
                                            $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                                            $Success = $true
                                            
                                            # Handle the output
                                            Handle-CommandOutput -Command $CommandResult.Command -Result $ExecutionResult
                                            Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                                            continue
                                        }
                                        catch {
                                            $ErrorMessage = $_.Exception.Message
                                            Write-Verbose "Module error: $ErrorMessage"
                                            
                                            # Check if it's a connection required error
                                            if ($ErrorMessage -match "Authentication needed|You must call the Connect-\w+ cmdlet") {
                                                Write-Host "Authentication required. Attempting to connect..." -ForegroundColor Yellow
                                                
                                                try {
                                                    switch ($ModuleName) {
                                                        'Microsoft.Graph' {
                                                            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
                                                            Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
                                                            Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
                                                        }
                                                        'AzureAD' {
                                                            Write-Host "Connecting to Azure AD..." -ForegroundColor Cyan
                                                            Connect-AzureAD
                                                            Write-Host "Successfully connected to Azure AD" -ForegroundColor Green
                                                        }
                                                        'MSOnline' {
                                                            Write-Host "Connecting to Microsoft Online..." -ForegroundColor Cyan
                                                            Connect-MsolService
                                                            Write-Host "Successfully connected to Microsoft Online" -ForegroundColor Green
                                                        }
                                                        'MicrosoftTeams' {
                                                            Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
                                                            Connect-MicrosoftTeams
                                                            Write-Host "Successfully connected to Microsoft Teams" -ForegroundColor Green
                                                        }
                                                        default {
                                                            # Fallback to OpenAI for unknown connection requirements
                                                            $NewCommand = Convert-SpeechToCommand -InputText "How to connect to $ModuleName service?" -OpenAIKey $OpenAIKey
                                                            if ($NewCommand) {
                                                                Write-Host "Executing connection command..." -ForegroundColor Cyan
                                                                Invoke-Expression -Command $NewCommand.Command
                                                            }
                                                        }
                                                    }

                                                    # After successful connection, retry the original command
                                                    Write-Host "Retrying original command..." -ForegroundColor Yellow
                                                    $ExecutionResult = Invoke-Expression -Command $CommandResult.Command
                                                    $Success = $true
                                                    
                                                    # Handle the output
                                                    Handle-CommandOutput -Command $CommandResult.Command -Result $ExecutionResult
                                                    Write-CommandLog -Command $CommandResult.Command -Success $true -LogPath $LogPath
                                                }
                                                catch {
                                                    Write-Warning "Failed to connect to $ModuleName : $_"
                                                    $Success = $false
                                                }
                                            } else {
                                                Write-Warning "Failed to install/import module $ModuleName : $_"
                                                $Success = $false
                                            }
                                        }
                                    }
                                }

                                # Authentication/Connection errors
                                "You must call the Connect-\w+ cmdlet" {
                                    Write-Host "Authentication required. Generating connection command..." -ForegroundColor Yellow
                                    
                                    # Get new command from OpenAI that includes connection step
                                    $NewCommand = Convert-SpeechToCommand -InputText "How to connect to service for command: $($CommandResult.Command)" -OpenAIKey $OpenAIKey
                                    if ($NewCommand) {
                                        Write-Host "`nPlease run this command first:" -ForegroundColor Cyan
                                        Write-Host $NewCommand.Command -ForegroundColor Yellow
                                    }
                                    
                                    $Success = $false
                                }

                                # Other execution errors
                                default {
                                    Write-Host "Error executing command: $ErrorMessage" -ForegroundColor Red
                                    
                                    # Create a more specific prompt for property errors
                                    $promptText = if ($ErrorMessage -match "property '([^']+)' cannot be found") {
                                        @"
Fix this Microsoft Graph command that has property error. 
Original command: $($CommandResult.Command)
Error: $ErrorMessage

Requirements:
1. Use proper Microsoft Graph properties
2. Keep the command simple and avoid long property lists
3. For CSV operations:
   - First store CSV data in variable
   - Then process each user in a separate loop
   Example:
   ```
   `$users = Import-Csv -Path 'test.csv'
   foreach (`$user in `$users) {
       Get-MgUser -UserId `$user.UserPrincipalName | Select-Object DisplayName, UserPrincipalName, Mail
   }
   ```
"@
                                    } else {
                                        "Fix this error for command ($($CommandResult.Command)): $ErrorMessage. Keep the command simple and avoid long property lists."
                                    }
                                    
                                    $NewCommand = Convert-SpeechToCommand -InputText $promptText -OpenAIKey $OpenAIKey

                                    if ($NewCommand) {
                                        Write-Host "`nTrying alternative command:" -ForegroundColor Cyan
                                        Write-Host $NewCommand.Command -ForegroundColor Yellow
                                        
                                        # Execute the alternative command
                                        try {
                                            $ExecutionResult = Invoke-Expression -Command $NewCommand.Command
                                            $Success = $true
                                            
                                            # Handle the output
                                            Handle-CommandOutput -Command $NewCommand.Command -Result $ExecutionResult
                                            Write-CommandLog -Command $NewCommand.Command -Success $true -LogPath $LogPath
                                            continue
                                        }
                                        catch {
                                            Write-Warning "Alternative command also failed: $_"
                                            $Success = $false
                                        }
                                    }
                                    
                                    $Success = $false
                                }
                            }

                            if (-not $Success) {
                                Write-CommandLog -Command $CommandResult.Command -Success $false -Error $ErrorMessage -LogPath $LogPath
                                break
                            }
                        }
                    }
                }
                catch {
                    $ErrorMessage = "Error in command execution loop: $($_.Exception.Message)"
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
        Write-Host "BANIK Commander terminated successfully." -ForegroundColor Green
    }
}