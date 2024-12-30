@{
    RootModule = 'VoiceCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'VoiceCommander'
    Description = 'A PowerShell voice command tool with OpenAI integration'
    PowerShellVersion = '5.1'
    RequiredAssemblies = @('System.Speech')
    FunctionsToExport = @('Start-VoiceCommand')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Voice', 'OpenAI', 'PowerShell', 'Automation', 'Speech', 'AI')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release'
        }
    }
}