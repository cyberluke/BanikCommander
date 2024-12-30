# VoiceCommander

A PowerShell voice command tool with OpenAI integration for automated PowerShell and AzureAD tasks.

## Requirements

- Windows Platform (Windows 10 or later recommended)
- PowerShell 5.1 or later
- OpenAI API Key
- System.Speech assembly (included with Windows)

## Installation

1. Clone or download this repository
2. Import the module:
```powershell
Import-Module .\VoiceCommander\VoiceCommander.psm1
```

## Usage

### Basic Usage
```powershell
Start-VoiceCommand -OpenAIKey "your-openai-key"
```

### Text-Only Mode
```powershell
Start-VoiceCommand -OpenAIKey "your-openai-key" -TextOnly
```

### With Custom Log Path
```powershell
Start-VoiceCommand -OpenAIKey "your-openai-key" -LogPath "C:\Logs\VoiceCommander"
```

## Features

- Voice command recognition using Windows Speech Recognition
- Text input fallback when voice recognition is unavailable
- Natural language processing using OpenAI
- Command safety validation
- Comprehensive logging
- Support for both PowerShell and Azure AD commands

## Example Commands

You can speak or type commands like:
- "Show me all running processes"
- "List all services"
- "Get computer information"
- "Show Azure AD users"

## Notes

- Voice recognition is only available on Windows platforms
- The module will automatically fall back to text input if voice recognition is unavailable
- Commands are validated for safety before execution
- All command executions are logged for auditing
