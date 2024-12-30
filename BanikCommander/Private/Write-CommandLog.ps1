function Write-CommandLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter(Mandatory)]
        [bool]$Success,
        
        [Parameter()]
        [string]$Error = "",
        
        [Parameter()]
        [string]$LogPath
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogFile = Join-Path -Path $LogPath -ChildPath "VoiceCommander_$(Get-Date -Format 'yyyyMMdd').log"

    $LogEntry = [PSCustomObject]@{
        Timestamp = $Timestamp
        Command = $Command
        Success = $Success
        Error = $Error
        User = $env:USERNAME
    }

    $LogEntry | ConvertTo-Json | Add-Content -Path $LogFile
}
