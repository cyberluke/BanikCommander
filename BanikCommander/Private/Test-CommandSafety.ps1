function Test-CommandSafety {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )

    Write-Verbose "Testing safety for command: $Command"
    
    # List of dangerous commands that should trigger a warning
    $DangerousCommands = @(
        'Remove-',
        'Delete-',
        'Stop-',
        'Kill-',
        'Disable-',
        'Uninstall-',
        'Reset-',
        'Clear-',
        'Suspend-',
        'Block-'
    )

    # List of safe formatting commands that should be excluded from warnings
    $SafeFormattingCommands = @(
        'Format-Table',
        'Format-List',
        'Format-Wide',
        'Format-Custom'
    )

    $IsSafe = $true
    $Reason = ""

    # Check for dangerous commands
    foreach ($dangerous in $DangerousCommands) {
        if ($Command -match $dangerous) {
            $IsSafe = $false
            $Reason = "Command contains potentially dangerous operation: $dangerous"
            Write-Verbose "Dangerous command detected: $dangerous"
            break
        }
    }

    # Return result
    @{
        IsSafe = $IsSafe
        Reason = $Reason
    }
}