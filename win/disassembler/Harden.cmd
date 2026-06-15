:: Harden.cmd — parallels Default.cmd. Reuses the Win10.ps1 runner, loads both
:: libraries (Disassembler's + this one), and applies Harden.preset.
:: Place next to Win10.ps1 and Win10.psm1, then double-click (UAC will elevate).

@powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Win10.ps1" -include "%~dp0Win10.psm1" -include "%~dpn0.psm1" -preset "%~dpn0.preset" -log run.log
