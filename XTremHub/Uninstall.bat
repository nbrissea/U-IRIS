ECHO OFF
if EXIST commloader.exe GOTO START
ECHO You must run this batch file from the directory where your agent is installed.
pause
GOTO DONE
:START
CommLoader.exe -unenroll
net stop MCAgent
CommLoader.exe -uninstall -delete
del McAgtInst.log /F 2>NUL
del CommLoader.exe /F 2>NUL
del McHook.dll /F  2>NUL
del McHook64.dll /F 2>NUL
del Mchookhelper.exe /F 2>NUL
del WinMCKiosk.exe /F 2>NUL
del McRes*.dll /F 2>NUL
del vcredist_x86.exe /F 2>NUL
del pdb.ini /F 2>NUL
del CertCache\*.* /F /Q 2>NUL
del PdbInfo\*.* /F /Q 2>NUL
del PdbPkg\*.* /F /Q 2>NUL
del temp\*.* /F /Q 2>NUL
rmdir CertCache 2>NUL
rmdir PdbInfo 2>NUL
rmdir PdbPkg 2>NUL
rmdir temp 2>NUL
del MCAgent*.exe /F 2>NUL
del Readme.txt /F 2>NUL
del MobiControl.log /F 2>NUL
netsh http delete sslcert ipport=0.0.0.0:9143
cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
:DONE
