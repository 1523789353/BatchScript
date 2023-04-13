@echo off
set "targetDir=%~1"


if "%targetDir%" == "" (
    set "targetDir=%cd%"
)

if not exist "%targetDir%" (
    >&2 echo=错误: 目标文件夹不存在
    exit /b 1
)

echo 清理目录: %targetDir%

for /f "delims=" %%i in ('dir "%targetDir%" /A:-DH /B /S^|findstr /R /C:"\Folder.jpg$" /C:"\AlbumArt.*.jpg$"') do (
    2>nul del /F /S /Q /A:H "%%i"
)

exit /b 0
