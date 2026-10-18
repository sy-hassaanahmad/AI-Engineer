Set fso = CreateObject("Scripting.FileSystemObject")
repoPath = "F:\My Drive\Chronos  - Skill Leveling\AI Engineer"
scriptPath = repoPath & "\sync-to-github.ps1"

If fso.DriveExists("F:") Then
    If fso.FolderExists(repoPath) And fso.FileExists(scriptPath) Then
        Set WshShell = CreateObject("WScript.Shell")
        WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """", 0, False
    End If
End If
