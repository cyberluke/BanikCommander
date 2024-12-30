@{
    RootModule = 'VoiceCommander.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8deb611-9bb0-4dbd-9345-401fe6762fb2'
    Author = 'VoiceCommander'
    Description = 'A PowerShell voice command tool with OpenAI integration'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-VoiceCommand')
    PrivateData = @{
        PSData = @{
            Tags = @('Voice', 'OpenAI', 'PowerShell', 'Automation')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = 'Initial release'
        }
    }
}
