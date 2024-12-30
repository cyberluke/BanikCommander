# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Get the module path
$ModulePath = $PSScriptRoot
Write-Verbose "Module Path: $ModulePath"

# Verify System.Speech assembly
try {
    Write-Verbose "Checking System.Speech assembly..."
    if (-not ('System.Speech.Recognition.SpeechRecognitionEngine' -as [Type])) {
        Write-Verbose "Loading System.Speech assembly..."
        Add-Type -AssemblyName System.Speech
        Write-Verbose "System.Speech assembly loaded successfully"
    }
} catch {
    Write-Error "Failed to load System.Speech assembly: $($_.Exception.Message)"
    throw
}

# Import all public/private functions
Write-Verbose "Importing functions from $ModulePath"
$Public = @(Get-ChildItem -Path $ModulePath\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $ModulePath\Private\*.ps1 -ErrorAction SilentlyContinue)

Write-Verbose "Found $($Public.Count) public and $($Private.Count) private functions"

# Dot source the files
foreach ($Import in @($Public + $Private)) {
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
Write-Verbose "Exporting public functions: $($Public.BaseName -join ', ')"
Export-ModuleMember -Function $Public.BaseName -Verbose:$VerbosePreference