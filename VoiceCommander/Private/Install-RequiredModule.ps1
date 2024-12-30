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
            'SharePoint' = 'Microsoft.Online.SharePoint.PowerShell'
            'SQL' = 'SQLServer'
            'SPO' = 'Microsoft.Online.SharePoint.PowerShell'
            'PnP' = 'PnP.PowerShell'
            # Add additional Azure module mappings
            'AzureRM' = 'AzureRM'
            'AzureADPreview' = 'AzureADPreview'
            'Az' = 'Az'
        }

        # If we have a mapping, use it
        if ($ModuleMapping.ContainsKey($ModuleName)) {
            $OriginalModule = $ModuleName
            $ModuleName = $ModuleMapping[$ModuleName]
            Write-Verbose "Mapped '$OriginalModule' to module: $ModuleName"
        }

        # Check if module is already installed
        $ExistingModule = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
        if ($ExistingModule) {
            Write-Verbose "Module $ModuleName is already installed (Version: $($ExistingModule.Version))"

            # Try to import the module even if it's already installed
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

        # Install the module with progress display
        Write-Progress -Activity "Installing Module" -Status "Installing $ModuleName..."

        # Special handling for Azure modules
        if ($ModuleName -like '*Azure*') {
            # Ensure NuGet provider is available
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Write-Verbose "Installing NuGet package provider..."
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            }

            # For Azure modules, use -AllowClobber and -SkipPublisherCheck
            Write-Verbose "Installing Azure module with special handling..."
            try {
                Install-Module -Name $ModuleName -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to install Azure module directly. Attempting alternative installation..."
                # Try alternative installation methods
                switch ($ModuleName) {
                    'AzureAD' {
                        # Try AzureAD Preview if regular AzureAD fails
                        try {
                            Install-Module -Name 'AzureADPreview' -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                            $ModuleName = 'AzureADPreview'
                            Write-Verbose "Successfully installed AzureADPreview as alternative"
                        }
                        catch {
                            Write-Error "Failed to install both AzureAD and AzureADPreview modules"
                            return $false
                        }
                    }
                    'Az' {
                        # For Az module, try installing core module first
                        try {
                            Install-Module -Name 'Az.Accounts' -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                            Write-Verbose "Successfully installed Az.Accounts core module"
                            Install-Module -Name $ModuleName -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                        }
                        catch {
                            Write-Error "Failed to install Az module and its dependencies"
                            return $false
                        }
                    }
                }
            }
        } else {
            Write-Verbose "Installing non-Azure module..."
            Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        }
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
        elseif ($ErrorMessage -match "assembly.*System.Management.Automation") {
            Write-Warning "PowerShell version compatibility issue. Try using a newer PowerShell version."
        }

        return $false
    }
}