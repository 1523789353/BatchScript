:: coding: gb2312
@echo off
title �������
mode con: cols=20 lines=5
:main
    cls
    Color 0A
    echo=      �������
    echo=1.����/ж��Z��
    echo=2.�Ƴ�����(����!)
    echo=
    choice /n /c 12 /m ������ѡ��:
    cls
    if %errorlevel%==1 call :switch
    if %errorlevel%==2 call :clear
goto main
:switch <����/ж��>
    if not exist "%cd%\Disk..\" (
        call :creat
    )
    if exist Z:\ (
        call :umount
    ) else (
        call :mount
    )
exit /b
:creat <��������>
    md "%cd%\Disk..\"
    md "%cd%\Disk..\.{645FF040-5081-101B-9F08-00AA002F954E}"
    call :set-pwd
    cls
exit /b
:mount <���ش���>
    call :auth
    if %errorlevel% == 1 (
        echo=�������!
        pause
        exit /b
    )
    subst Z: "%cd%\Disk..\.{645FF040-5081-101B-9F08-00AA002F954E}"
    start Z:\
exit /b
:umount <ж�ش���>
    subst /D Z:
exit /b
:clear <�������>
    if not exist "%cd%\Disk..\" exit /b 0
    call :auth
    if %errorlevel% == 1 (
        echo=�������!
        pause
        exit /b
    )
    cls
    echo=ɾ�����̼������ļ�?
    echo=    ��ȷ��[Y/N]
    echo=
    choice /n /c yn /m ������ѡ��:
    cls
    if %errorlevel%==2 exit /b
    if exist Z:\ subst /D Z:
    >nul 2>nul rd /s /q "%cd%\Disk..\"
exit /b
:set-pwd <��������>
    set /p "pwd=���趨����:"
    call :hash %pwd%
    set "pwd="
    echo %hash%>"%cd%\Disk..:secret"
exit /b
:auth <��֤����>
    set /p "pwd=����������:"
    call :hash %pwd%
    set "pwd="
    <"%cd%\Disk..:secret" set /p "secret="
    if not "%hash%" == "%secret%" (
        exit /b 1
    )
exit /b 0
:hash <�ַ�����ϣ>
    set "rfile=%temp%\%random%.tmp"
    >"%rfile%" echo %*
    call :eval certutil -hashfile "%rfile%" sha512
    >nul del /s /f /q "%rfile%"
    set "hash=%eval.result[1]%"
exit /b 0
:eval
    :: ����ϴεĽ��
    if defined eval.line (
        for /l %%i in (0,1,%eval.line%) do (
            set "eval.result[%%i]="
        )
    )
    set eval.line=0
    for /f "delims=" %%i in ('%*') do (
        call set "eval.result[%%eval.line%%]=%%i"
        set /a eval.line+=1
    )
exit /b 0
