@{
    RootModule = 'BanikCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'Lukas Satin'
    CompanyName = 'NANOTRIK.cz'
    Description = 'A PowerShell voice command tool with OpenAI integration for automated PowerShell and AzureAD tasks. Requires Windows platform for voice recognition.'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    FunctionsToExport = @(
        'Start-Banik',
        'Set-NANOTRIKAIConfig',
        'Get-BanikCommanderConfig'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAI', 'PowerShell', 'Automation', 'AI', 'NLP', 'Voice', 'Speech')
            LicenseUri = ''
            ProjectUri = 'https://www.nanotrik.ai'
            ReleaseNotes = 'Added secure configuration management for OpenAI API key'
        }
    }
    RequiredAssemblies = @('System.Speech')
    NestedModules = @()
    FileList = @(
        'BanikCommander.psm1',
        'BanikCommander.psd1',
        'Public\Start-Banik.ps1',
        'Public\Set-NANOTRIKAIConfig.ps1',
        'Private\Convert-SpeechToCommand.ps1',
        'Private\Get-BanikCommanderConfig.ps1',
        'Private\Handle-CommandOutput.ps1',
        'Private\Initialize-SpeechRecognition.ps1',
        'Private\Install-RequiredModule.ps1',
        'Private\Invoke-OpenAIRequest.ps1',
        'Private\Set-VoiceCommanderConfig.ps1',
        'Private\Test-CommandSafety.ps1',
        'Private\Test-ModuleEnvironment.ps1',
        'Private\Write-CommandLog.ps1'
    )
}