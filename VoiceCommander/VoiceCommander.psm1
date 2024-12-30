# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Get the module path
$ModulePath = $PSScriptRoot
Write-Verbose "Module Path: $ModulePath"

# Verify directory structure
$PublicPath = Join-Path $ModulePath 'Public'
$PrivatePath = Join-Path $ModulePath 'Private'

if (-not (Test-Path -Path $PublicPath)) {
    Write-Error "Public directory not found at: $PublicPath"
    throw "Module directory structure is invalid"
}

if (-not (Test-Path -Path $PrivatePath)) {
    Write-Error "Private directory not found at: $PrivatePath"
    throw "Module directory structure is invalid"
}

# Import functions with timeouts
$TimeoutSeconds = 30
$Job = Start-Job -ScriptBlock {
    param($PublicPath, $PrivatePath)
    $Public = @(Get-ChildItem -Path $PublicPath\*.ps1 -ErrorAction SilentlyContinue)
    $Private = @(Get-ChildItem -Path $PrivatePath\*.ps1 -ErrorAction SilentlyContinue)
    return @{
        Public = $Public
        Private = $Private
    }
} -ArgumentList $PublicPath, $PrivatePath

$Result = $Job | Wait-Job -Timeout $TimeoutSeconds | Receive-Job
Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue

if ($null -eq $Result) {
    Write-Error "Timeout while loading module files"
    throw "Module loading timed out after $TimeoutSeconds seconds"
}

$Public = $Result.Public
$Private = $Result.Private

Write-Verbose "Found $($Public.Count) public and $($Private.Count) private functions"

if ($Public.Count -eq 0 -and $Private.Count -eq 0) {
    Write-Error "No PowerShell scripts found in module directories"
    throw "Module contains no functions"
}

# Dot source the files
foreach ($Import in @($Private + $Public)) {
    try {
        Write-Verbose "Importing $($Import.FullName)"
        . $Import.FullName
        Write-Verbose "Successfully imported $($Import.BaseName)"
    }
    catch {
        Write-Error "Failed to import function $($Import.FullName): $_"
        throw
    }
}

# Export public functions
$PublicFunctions = $Public.BaseName
Write-Verbose "Exporting public functions: $($PublicFunctions -join ', ')"

if ($PublicFunctions.Count -gt 0) {
    Export-ModuleMember -Function $PublicFunctions -Verbose:$VerbosePreference
} else {
    Write-Warning "No public functions found to export"
}

# Run environment tests
Write-Verbose "Testing module environment..."
$EnvTest = Test-ModuleEnvironment -Verbose
Write-Verbose "Environment test results:"
Write-Verbose "PowerShell Version: $($EnvTest.PowerShellVersion)"
Write-Verbose "Is Windows: $($EnvTest.IsWindows)"
Write-Verbose "Platform: $($EnvTest.Platform)"
Write-Verbose "Speech Available: $($EnvTest.SpeechAvailable)"
Write-Verbose "OpenAI Key Present: $($EnvTest.OpenAIKeyPresent)"