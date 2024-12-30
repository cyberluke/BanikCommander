@{
    RootModule = 'VoiceCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'VoiceCommander'
    Description = 'A PowerShell voice command tool with OpenAI integration for automated PowerShell and AzureAD tasks. Requires Windows platform for voice recognition.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-VoiceCommand')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAI', 'PowerShell', 'Automation', 'AI', 'NLP', 'Voice', 'Speech')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release with voice recognition and text fallback support'
        }
    }
    RequiredAssemblies = @('System.Speech')
}