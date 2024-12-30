function Handle-CommandOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter()]
        [object]$Result,
        
        [Parameter()]
        [switch]$IsFileOperation
    )

    try {
        Write-Verbose "Handling output for command: $Command"
        
        if ($null -eq $Result) {
            Write-Host "Command executed successfully but returned no output." -ForegroundColor Yellow
            return
        }

        if ($IsFileOperation) {
            Write-Host "`nFile Content:" -ForegroundColor Green
            # Convert to string and write directly to host
            $Result | Out-String -Width 4096 | Write-Host
        } else {
            Write-Host "`nCommand Output:" -ForegroundColor Green
            # For regular commands, try to format as table first
            try {
                $FormattedOutput = $Result | Format-Table -AutoSize | Out-String -Width 4096
                if (-not [string]::IsNullOrWhiteSpace($FormattedOutput)) {
                    Write-Host $FormattedOutput
                } else {
                    # If table format fails, try direct string output
                    $Result | Out-String -Width 4096 | Write-Host
                }
            } catch {
                # Fallback to direct string output
                $Result | Out-String -Width 4096 | Write-Host
            }
        }
    } catch {
        Write-Warning "Error handling command output: $_"
        # Fallback to basic output
        Write-Host $Result
    }
}
