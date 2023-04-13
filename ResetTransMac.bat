@echo off
cd /d "%~dp0"
fsutil dirty query %systemdrive% 2>nul >nul
if not "%ErrorLevel%" == "0" (
    start "" mshta VBScript:CreateObject^("shell.application"^).ShellExecute^("%~0","%*","","runas",0^)^(Close^)
    exit /b
)
set "temp_file=%temp%\%random%.tmp"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved" /f "{*}" /k|>"%temp_file%" findstr \
set /p "regKey="<%temp_file%
2>&1 >nul del /s /f /q "%temp_file%"
reg delete "%regKey%" /f
start "" "%cd%\TransMac.exe"
exit /b
