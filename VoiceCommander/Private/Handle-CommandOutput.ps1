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
        Write-Verbose "Result type: $($Result.GetType().FullName)"

        if ($null -eq $Result) {
            Write-Host "Command executed successfully but returned no output." -ForegroundColor Yellow
            return
        }

        if ($IsFileOperation) {
            Write-Host "`nFile Content:" -ForegroundColor Green

            # Handle different types of file content
            switch ($Result.GetType().FullName) {
                "System.String" {
                    # For simple string content, split and display line by line
                    $Result -split "`n" | ForEach-Object {
                        Write-Host $_.TrimEnd()
                    }
                }
                "System.Object[]" {
                    # For array of objects (like Get-Content -Raw), format each line
                    $Result | ForEach-Object {
                        Write-Host $_.TrimEnd()
                    }
                }
                default {
                    # For other types, try to convert to string with maximum width
                    $Result | Out-String -Width 4096 | ForEach-Object {
                        if (-not [string]::IsNullOrWhiteSpace($_)) {
                            Write-Host $_.TrimEnd()
                        }
                    }
                }
            }
        } else {
            Write-Host "`nCommand Output:" -ForegroundColor Green

            try {
                # Try to format as table first
                $FormattedOutput = $Result | Format-Table -AutoSize | Out-String -Width 4096
                if (-not [string]::IsNullOrWhiteSpace($FormattedOutput)) {
                    Write-Host $FormattedOutput.TrimEnd()
                } else {
                    # If table format fails, try direct string output
                    $Result | Out-String -Width 4096 | ForEach-Object {
                        if (-not [string]::IsNullOrWhiteSpace($_)) {
                            Write-Host $_.TrimEnd()
                        }
                    }
                }
            } catch {
                # Fallback to basic output
                $Result | Out-String -Width 4096 | Write-Host
            }
        }
    } catch {
        Write-Warning "Error handling command output: $_"
        Write-Verbose "Error details: $($_.Exception | Format-List -Force | Out-String)"
        # Fallback to basic output
        Write-Host $Result
    }
}