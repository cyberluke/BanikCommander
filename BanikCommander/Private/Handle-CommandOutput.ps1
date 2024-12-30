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

        # Check if command is a file export operation
        if ($Command -match 'Export-Csv|Out-File|Set-Content|Add-Content') {
            # For export commands, check if the file was created
            if ($Command -match '-Path\s+["'']?([^"'']+)["'']?') {
                $filePath = $Matches[1].Trim('"').Trim("'")
                if (Test-Path $filePath) {
                    Write-Host "`nFile operation completed successfully." -ForegroundColor Green
                    Write-Host "Output saved to: $filePath" -ForegroundColor Cyan
                    return
                }
            }
        }

        # For non-export commands or if file path not found
        if ($null -eq $Result) {
            Write-Host "Command executed successfully but returned no output." -ForegroundColor Yellow
            return
        }

        # Check if command is Azure AD related and ensure required modules are installed
        if ($Command -match "AzureAD|AAD") {
            try {
                # Check for AzureAD module
                Install-RequiredModule -ModuleName "AzureAD"
                
                # For newer commands, also check for Microsoft.Graph module
                if ($Command -match "Graph") {
                    Install-RequiredModule -ModuleName "Microsoft.Graph"
                }
            }
            catch {
                Write-Warning "Failed to install required Azure modules: $_"
                return
            }
        }

        Write-Verbose "Result type: $($Result.GetType().FullName)"

        if ($IsFileOperation) {
            Write-Host "`nFile Content:" -ForegroundColor Green

            # Handle different types of file content
            switch ($Result.GetType().FullName) {
                "System.String" {
                    $Result -split "`n" | ForEach-Object {
                        Write-Host $_.TrimEnd()
                    }
                }
                "System.Object[]" {
                    $Result | ForEach-Object {
                        Write-Host $_.TrimEnd()
                    }
                }
                default {
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
        # Only show warning if it's not a successful file operation
        if (-not ($Command -match 'Export-Csv|Out-File|Set-Content|Add-Content') -or 
            -not ($_.Exception.Message -match 'null-valued expression')) {
            Write-Warning "Error handling command output: $_"
            Write-Verbose "Error details: $($_.Exception | Format-List -Force | Out-String)"
        }
    }
}