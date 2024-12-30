# Create Assets directory
New-Item -ItemType Directory -Path "BanikCommander/Assets" -Force

# Create ASCII art banner file
$banner = @'
    ____              _ _    
   |  _ \            (_) |   
   | |_) | __ _ _ __  _| | __
   |  _ < / _' | '_ \| | |/ /
   | |_) | (_| | | | | |   < 
   |____/ \__,_|_| |_|_|_|\_\
   Commander v1.0
'@

Set-Content -Path "BanikCommander/Assets/banik.txt" -Value $banner 