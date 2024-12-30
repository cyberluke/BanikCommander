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
        }

        # If we have a mapping, use it
        if ($ModuleMapping.ContainsKey($ModuleName)) {
            $ModuleName = $ModuleMapping[$ModuleName]
            Write-Verbose "Mapped to module: $ModuleName"
        }

        # Check if module is already installed
        if (Get-Module -ListAvailable -Name $ModuleName) {
            Write-Verbose "Module $ModuleName is already installed"

            # Try to import the module
            Import-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Verbose "Module $ModuleName imported successfully"
            return $true
        }

        # Module not installed, attempt to install it
        Write-Host "Installing required module: $ModuleName..." -ForegroundColor Yellow

        # Set PSGallery as trusted to avoid prompts
        if ((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }

        # Install the module
        Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop

        # Import the newly installed module
        Import-Module -Name $ModuleName -Force -ErrorAction Stop

        Write-Host "Successfully installed and imported module: $ModuleName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to install/import module $ModuleName : $_"
        return $false
    }
}