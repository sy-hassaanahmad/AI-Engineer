Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""F:\My Drive\Chronos  - Skill Leveling\AI Engineer\sync-to-github.ps1""", 0, False
