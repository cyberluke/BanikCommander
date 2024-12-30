function Install-RequiredModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    try {
        Write-Verbose "Checking for module: $ModuleName"

        # Map common command prefixes to module names
        $ModuleMapping = @{
            'Azure' = 'AzureAD'
            'AzureAD' = 'AzureAD'
            'MSOnline' = 'MSOnline'
            'Graph' = 'Microsoft.Graph'
            'AD' = 'ActiveDirectory'
            'Exchange' = 'ExchangeOnlineManagement'
            'Teams' = 'MicrosoftTeams'
        }

        # If we have a mapping, use it
        if ($ModuleMapping.ContainsKey($ModuleName)) {
            $ModuleName = $ModuleMapping[$ModuleName]
            Write-Verbose "Mapped to module: $ModuleName"
        }

        # Check if module is already installed
        $ExistingModule = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
        if ($ExistingModule) {
            Write-Verbose "Module $ModuleName is already installed (Version: $($ExistingModule.Version))"

            # Try to import the module
            Import-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Verbose "Module $ModuleName imported successfully"
            return $true
        }

        # Module not installed, attempt to install it
        Write-Host "Required module '$ModuleName' not found. Installing..." -ForegroundColor Yellow

        # Set PSGallery as trusted to avoid prompts
        if ((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
            Write-Verbose "Setting PSGallery as trusted repository..."
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }

        # Install the module
        Write-Progress -Activity "Installing Module" -Status "Installing $ModuleName..."
        Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Progress -Activity "Installing Module" -Completed

        # Import the newly installed module
        Write-Progress -Activity "Importing Module" -Status "Importing $ModuleName..."
        Import-Module -Name $ModuleName -Force -ErrorAction Stop
        Write-Progress -Activity "Importing Module" -Completed

        Write-Host "Successfully installed and imported module: $ModuleName" -ForegroundColor Green
        return $true
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Failed to install/import module $ModuleName : $ErrorMessage"
        Write-Verbose "Full error details: $($_ | Format-List -Force | Out-String)"

        # Provide more helpful error messages
        if ($ErrorMessage -match "Unable to resolve package source") {
            Write-Warning "Could not connect to PowerShell Gallery. Please check your internet connection."
        }
        elseif ($ErrorMessage -match "Access to the path.*is denied") {
            Write-Warning "Access denied. Try running PowerShell as Administrator."
        }

        return $false
    }
}