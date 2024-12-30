function Test-CommandSafety {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )

    # List of potentially dangerous commands
    $DangerousCommands = @(
        'Remove-',
        'Delete',
        'Set-',
        'New-',
        'Stop-',
        'Disable-',
        'Enable-',
        'Reset-',
        'Clear-',
        'Update-',
        'Format-',
        'Move-',
        'Rename-'
    )

    # List of safe commands that don't require confirmation
    $SafeCommands = @(
        'Get-',
        'Find-',
        'Search-',
        'Test-',
        'Show-',
        'Read-',
        'Install-Module',
        'Import-Module'
    )

    # List of safe file operations
    $SafeFileOperations = @(
        'Get-Content',
        'Out-File',
        'Export-Csv',
        'Import-Csv'
    )

    $Result = @{
        IsSafe = $true
        Reason = "Command appears safe"
    }

    # Check for explicitly safe file operations
    foreach ($SafeOp in $SafeFileOperations) {
        if ($Command -match "^$SafeOp") {
            return $Result
        }
    }

    # Check for dangerous commands
    foreach ($DangerousCmd in $DangerousCommands) {
        if ($Command -match $DangerousCmd) {
            # Special case for Install-Module and Import-Module
            if ($Command -match '^(Install-Module|Import-Module)') {
                return $Result
            }
            $Result.IsSafe = $false
            $Result.Reason = "Command contains potentially dangerous operation: $DangerousCmd"
            return $Result
        }
    }

    # Check if it's explicitly a safe command
    $IsSafeCommand = $false
    foreach ($SafeCmd in $SafeCommands) {
        if ($Command -match "^$SafeCmd") {
            $IsSafeCommand = $true
            break
        }
    }

    if (-not $IsSafeCommand) {
        $Result.IsSafe = $false
        $Result.Reason = "Command is not explicitly marked as safe"
    }

    return $Result
}