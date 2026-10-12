$ws = New-Object -ComObject WScript.Shell
$desk = [Environment]::GetFolderPath('Desktop')

$s1 = $ws.CreateShortcut("$desk\Samsung DeX.lnk")
$s1.TargetPath = 'D:\programs\scrcpy-win64-v3.3.4\Samsung DeX Pro.bat'
$s1.WorkingDirectory = 'D:\programs\scrcpy-win64-v3.3.4'
$s1.IconLocation = 'D:\programs\scrcpy-win64-v3.3.4\samsungdex.ico,0'
$s1.Description = 'Samsung DeX Pro - Control Menu (Galaxy A55)'
$s1.Save()

$s2 = $ws.CreateShortcut("$desk\Samsung DeX (USB Fast).lnk")
$s2.TargetPath = 'D:\programs\scrcpy-win64-v3.3.4\Samsung DeX Pro.bat'
$s2.Arguments = '1'
$s2.WorkingDirectory = 'D:\programs\scrcpy-win64-v3.3.4'
$s2.IconLocation = 'D:\programs\scrcpy-win64-v3.3.4\samsungdex.ico,0'
$s2.Description = 'Samsung DeX Pro - Fast USB Launch (Galaxy A55)'
$s2.Save()

Write-Host "SHORTCUTS_OK"
