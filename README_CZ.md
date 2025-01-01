# Banik Commander

Hlasový a textový asistent pro PowerShell využívající NANOTRIK.AI.

## Funkce

- Rozpoznávání hlasových příkazů (pouze Windows)
- Převod přirozeného jazyka na PowerShell příkazy
- Textový režim pro ostatní platformy
- Režim náhledu příkazů
- Automatická instalace modulu
- Integrace do nabídky Start systému Windows

## Rychlá instalace

```powershell
# Stažení a spuštění instalátoru
irm https://raw.githubusercontent.com/cyberluke/BanikCommander/main/install.ps1 | iex
```

## Manuální instalace

1. Klonování repozitáře:
```powershell
git clone https://github.com/cyberluke/BanikCommander.git
```

2. Import modulu:
```powershell
Import-Module .\BanikCommander\BanikCommander.psm1 -Force
```

3. Nastavení NANOTRIK.AI API klíče:
```powershell
Set-NANOTRIKAIConfig -ApiKey "váš-api-klíč"
```

## Použití

### Spuštění Commanderu

```powershell
# Spuštění v normálním režimu (s hlasovým ovládáním, pokud je dostupné)
Start-Banik

# Spuštění v textovém režimu
Start-Banik -TextOnly

# Náhled příkazu bez spuštění
.\banik.ps1 "ukaž všechny běžící procesy"
```

### Hlasové příkazy

1. Začněte mluvit po zobrazení "Listening..."
2. Ukončete příkaz slovem "banik" nebo "baník" pro provedení
3. Řekněte "exit" pro ukončení

Příklad: "Ukaž mi všechny běžící procesy banik"

### Textové příkazy

V textovém režimu jednoduše napište příkaz a stiskněte Enter.

Příklad: "seznam všechny běžící služby"

### Konfigurace modulů
Můžete nakonfigurovat, které PowerShell moduly se mají automaticky importovat při použití BanikCommander. Ve výchozím nastavení nejsou automaticky importovány žádné moduly. Pro povolení automatického importu modulů upravte pole `$RequiredModules` v souboru `BanikCommander/Private/Initialize-RequiredModules.ps1`. Například můžete přidat moduly jako 'Microsoft.Graph', 'AzureAD', 'MSOnline' nebo 'MicrosoftTeams' podle vašich potřeb.

## Trvalá instalace

Spusťte instalační skript a zvolte 'Y' při dotazu na trvalou instalaci:
```powershell
.\install.ps1
```

Toto provede:
1. Zkopírování modulu do adresáře PowerShell modulů
2. Přidání do PowerShell profilu pro automatický import
3. Vytvoření zástupce v nabídce Start (volitelné)

## Požadavky

- PowerShell 7.0 nebo novější
- Windows (pro hlasové ovládání)
- NANOTRIK.AI API klíč
- Git (automaticky nainstalován, pokud chybí)
- Český jazykový balíček (pro české hlasové ovládání)

## Licence

MIT License 