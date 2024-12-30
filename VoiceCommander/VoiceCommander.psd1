@{
    RootModule = 'VoiceCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'VoiceCommander'
    CompanyName = 'VoiceCommander'
    Description = 'A PowerShell voice command tool with OpenAI integration for automated PowerShell and AzureAD tasks. Requires Windows platform for voice recognition.'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    FunctionsToExport = @('Start-VoiceCommand', 'Set-OpenAIConfig', 'Get-VoiceCommanderConfig')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAI', 'PowerShell', 'Automation', 'AI', 'NLP', 'Voice', 'Speech')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Added secure configuration management for OpenAI API key'
        }
    }
    RequiredAssemblies = @('System.Speech')
    FileList = @(
        'VoiceCommander.psm1'
        'VoiceCommander.psd1'
        'Public\Start-VoiceCommand.ps1'
        'Public\Set-OpenAIConfig.ps1'
        'Private\Convert-SpeechToCommand.ps1'
        'Private\Get-VoiceCommanderConfig.ps1'
        'Private\Initialize-SpeechRecognition.ps1'
        'Private\Invoke-OpenAIRequest.ps1'
        'Private\Set-VoiceCommanderConfig.ps1'
        'Private\Test-CommandSafety.ps1'
        'Private\Test-ModuleEnvironment.ps1'
        'Private\Write-CommandLog.ps1'
        'Private\Handle-CommandOutput.ps1'
        'Private\Install-RequiredModule.ps1'
    )
}