@{
    RootModule = 'VoiceCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'VoiceCommander'
    Description = 'A PowerShell command tool with OpenAI integration for natural language processing'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-VoiceCommand')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAI', 'PowerShell', 'Automation', 'AI', 'NLP')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release with text-based input support'
        }
    }
}