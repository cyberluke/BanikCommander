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
            'AzureRM' = 'AzureRM'
            'AzureADPreview' = 'AzureADPreview'
            'Az' = 'Az'
            # Add more specific Azure module mappings
            'AzureRmAccount' = 'AzureRM'
            'AzAccount' = 'Az'
            'AzureADSync' = 'AzureADSync'
            'AzureInformationProtection' = 'AIPService'
            'MSGraph' = 'Microsoft.Graph'
            'Office365' = 'MSOnline'
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
                # For Azure modules, ensure we're using TLS 1.2
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Write-Verbose "Set TLS 1.2 for Azure module installation"

                Install-Module -Name $ModuleName -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to install Azure module directly. Attempting alternative installation..."
                # Try alternative installation methods
                switch ($ModuleName) {
                    'AzureAD' {
                        # Try AzureAD Preview if regular AzureAD fails
                        try {
                            Write-Verbose "Attempting to install AzureADPreview as alternative..."
                            Install-Module -Name 'AzureADPreview' -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                            $ModuleName = 'AzureADPreview'
                            Write-Verbose "Successfully installed AzureADPreview as alternative"
                        }
                        catch {
                            Write-Error "Failed to install both AzureAD and AzureADPreview modules"
                            Write-Verbose "Full error details: $($_ | Format-List -Force | Out-String)"
                            return $false
                        }
                    }
                    'Az' {
                        # For Az module, try installing core module first
                        try {
                            Write-Verbose "Installing Az.Accounts core module..."
                            Install-Module -Name 'Az.Accounts' -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                            Write-Verbose "Successfully installed Az.Accounts core module"
                            Install-Module -Name $ModuleName -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                        }
                        catch {
                            Write-Error "Failed to install Az module and its dependencies"
                            Write-Verbose "Full error details: $($_ | Format-List -Force | Out-String)"
                            return $false
                        }
                    }
                    default {
                        Write-Verbose "Attempting to install module with basic Azure dependencies..."
                        try {
                            # Try installing Microsoft.PowerShell.Security first
                            Install-Module -Name 'Microsoft.PowerShell.Security' -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction SilentlyContinue
                            Install-Module -Name $ModuleName -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
                        }
                        catch {
                            Write-Error "Failed to install Azure module $ModuleName"
                            Write-Verbose "Full error details: $($_ | Format-List -Force | Out-String)"
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
        switch -Regex ($ErrorMessage) {
            "Unable to resolve package source" {
                Write-Warning "Could not connect to PowerShell Gallery. Please check your internet connection."
                Write-Warning "You can also try running: [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
            }
            "Access to the path.*is denied" {
                Write-Warning "Access denied. Try running PowerShell as Administrator."
                Write-Warning "Alternatively, try installing with -Scope CurrentUser flag."
            }
            "assembly.*System.Management.Automation" {
                Write-Warning "PowerShell version compatibility issue. Try using PowerShell 5.1 or newer."
                Write-Warning "Current PowerShell version: $($PSVersionTable.PSVersion)"
            }
            "Could not install.*AzureAD" {
                Write-Warning "Failed to install AzureAD module. Trying alternative installation..."
                Write-Warning "You can try manually installing the preview version: Install-Module AzureADPreview -AllowClobber"
            }
            "Could not load type.*Microsoft.Open.Azure" {
                Write-Warning "Azure module dependency issue. Try installing Az.Accounts module first."
                Write-Warning "Run: Install-Module -Name Az.Accounts -Force -AllowClobber"
            }
            "A parameter cannot be found that matches parameter name 'AllowPrerelease'" {
                Write-Warning "Your PowerShellGet version might be outdated."
                Write-Warning "Try updating it: Install-Module PowerShellGet -Force"
            }
            default {
                Write-Warning "Installation failed with an unexpected error. Please check the error message and try again."
                Write-Warning "If the issue persists, try manually installing the module: Install-Module $ModuleName -Scope CurrentUser"
            }
        }

        return $false
    }
}