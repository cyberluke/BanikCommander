# Banik Commander

A PowerShell-based voice and text command assistant made for my father Tomas.

![Banik Commander Ostrava](banik.jpg)


## Features

- Voice command recognition (Windows only)
- Natural language to PowerShell command conversion
- Text-only mode for non-Windows platforms
- Command preview mode
- Automatic module installation
- Windows Start Menu integration

## Quick Installation

```powershell
# Download and run the installer
irm https://raw.githubusercontent.com/cyberluke/BanikCommander/main/install.ps1 | iex
```

## Manual Installation

1. Clone the repository:
```powershell
git clone https://github.com/cyberluke/BanikCommander.git
```

2. Import the module:
```powershell
Import-Module .\BanikCommander\BanikCommander.psm1 -Force
```

3. Configure your OpenAI API key:
```powershell
Set-NANOTRIKAIConfig -ApiKey "your-api-key-here"
```

## Usage

### Start the Commander

```powershell
# Start in normal mode (with voice recognition if available)
Start-Banik

# Start in text-only mode
Start-Banik -TextOnly

# Preview a command without executing
.\banik.ps1 "show all running processes"
```

### Voice Commands

1. Start speaking after "Listening..." appears
2. End your command with "banik" or "baník" to execute
3. Say "exit" to quit

Example: "Show me all running processes banik"

### Text Commands

In text-only mode, simply type your command and press Enter.

Example: "list all services that are running"

### Module Configuration
You can configure which PowerShell modules should be automatically imported when using BanikCommander. By default, no modules are imported automatically. To enable automatic module imports, modify the `$RequiredModules` array in `BanikCommander/Private/Initialize-RequiredModules.ps1`. For example, you can add modules like 'Microsoft.Graph', 'AzureAD', 'MSOnline', or 'MicrosoftTeams' based on your needs.

## Permanent Installation

Run the installation script and choose 'Y' when prompted to install permanently:
```powershell
.\install.ps1
```

This will:
1. Copy the module to your PowerShell modules directory
2. Add it to your PowerShell profile for automatic import
3. Create a Start Menu shortcut (optional)

## Requirements

- PowerShell 7.0 or later
- Windows (for voice recognition)
- NANOTRIK.AI API key
- Git (automatically installed if missing)
- Czech language pack (for Czech voice recognition)

## License

MIT License
