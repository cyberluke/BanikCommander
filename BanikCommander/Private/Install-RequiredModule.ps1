function Install-RequiredModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [Parameter()]
        [switch]$AllowPrerelease
    )

    try {
        if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
            Write-Host "Installing required module: $ModuleName..." -ForegroundColor Yellow
            $installParams = @{
                Name = $ModuleName
                Force = $true
                Scope = 'CurrentUser'
            }
            
            if ($AllowPrerelease) {
                $installParams['AllowPrerelease'] = $true
            }
            
            Install-Module @installParams
            Write-Host "Successfully installed $ModuleName module." -ForegroundColor Green
        }
        
        # Import the module
        Import-Module -Name $ModuleName -Force
        Write-Verbose "Successfully imported $ModuleName module."
    }
    catch {
        Write-Warning "Failed to install or import module $ModuleName : $_"
        throw
    }
}