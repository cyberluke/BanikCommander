# Banik Commander

A PowerShell-based AI assistant that converts natural language into PowerShell commands.

## Installation

ONE LINE INSTALLATION
```powershell
iwr -useb https://raw.githubusercontent.com/cyberluke/BanikCommander/main/BanikCommander/install.ps1 | iex
```

OR

# Clone the repository
```powershell
# Clone the repository
git clone https://github.com/cyberluke/BanikCommander.git

# Import the module
Import-Module .\BanikCommander\BanikCommander.psm1 -Force
```

## Configuration

```powershell
# Set your OpenAI API key
Set-OpenAIConfig -ApiKey "your-api-key-here"
```

## Usage

```powershell
# Start Banik Commander in text mode
Start-Banik -TextOnly

# Start with voice recognition (BETA)
Start-Banik
```

# ... rest of the README content ...