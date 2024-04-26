:: coding: gb2312
:: �μ�: https://www.bilibili.com/read/cv17301168/
@setlocal
@if not defined debug set "debug=0"
@if "%debug%" == "0" echo off
if "%~1" == "" goto :usage
if "%~1" == "-h" goto :usage
if "%~1" == "--help" goto :usage
if "%~1" == "/?" goto :usage
call :main %*
@endlocal
exit /b %ErrorLevel%

:main <��Ƶ�ļ�·��> [Ŀ�����]
    :: �ۺ���ȡ����ֵ����ȷ�Χ
    set loudness=%~2
    set truepeak=-0.5
    set loudrange=11
    :: ��������루lossy encoding��֮ǰ�����ֵ��Ӧ����-1dBTP��
    :: ������Ϊ����������״�����ֵ���壨peak overshoot��������һ������Խ�͹���Ŀ��ܷ���Խ��

    if "%loudness%" == "" set loudness=-16

    if not exist "%~1" (
        echo=�Ҳ����ļ� "%~1"
        exit /b 1
    )

    echo=���ڴ����ļ� "%~1"
    echo=

    set "eval.cmdline=ffprobe -threads 0 -i "%~1" -select_streams a:0 -show_entries "stream=bits_per_sample,bits_per_raw_sample" -of "default=noprint_wrappers=1:nokey=1" -v error"
    call :eval %%%%eval.cmdline%%%%
    set bits=%eval.result[0]%
    set bits_raw=%eval.result[1]%

    if "%bits%" == "N/A" set bits=0
    if "%bits_raw%" == "N/A" set bits_raw=0

    if "%bits%" == "%bits_raw%" (
        set "bit_depth=%bits%"
    ) else (
        set /a "bit_depth=%bits% + %bits_raw%"
    )

    if "%bit_depth%" == "0" (
        echo ԭʼ��Ƶλ��Ϊ N/A
    ) else (
        echo ԭʼ��Ƶλ��Ϊ %bit_depth%
    )

    :: ת�������� 24 λ PCM �Խ��д���
    if %bit_depth% leq 24 (
        set bit_pcm=24
    ) else (
        set bit_pcm=%bit_depth%
    )
    echo=ʹ�� %bit_pcm% λ���б�׼������
    echo=
    echo=1-pass: ������Ƶ������ȡ��׼������

    :: ��һ�飺������Ƶ������ȡ��׼������
    set "eval.cmdline=ffmpeg -threads 0 -hwaccel auto -i "%~1" -c:a:0 pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:print_format=json" -f null - -nostdin -hide_banner 2>&1 | findstr "\{ \"\ \:\ \" }" | find /v "#""
    call :eval %%%%eval.cmdline%%%%

    call :readVal "eval.result[1]" II
    call :readVal "eval.result[2]" ITP
    call :readVal "eval.result[3]" ILRA
    call :readVal "eval.result[4]" IT
    call :readVal "eval.result[5]" OI
    call :readVal "eval.result[6]" OTP
    call :readVal "eval.result[7]" OLRA
    call :readVal "eval.result[8]" OT
    call :readVal "eval.result[9]" NT
    call :readVal "eval.result[10]" TO

    echo �����ۺ����:  %II.align% LUFS
    echo �������ֵ:    %ITP.align% dBTP
    echo ������ȷ�Χ:  %ILRA.align% LU
    echo ������ֵ:      %IT.align% LUFS
    echo ����ۺ����:  %OI.align% LUFS
    echo ������ֵ:    %OTP.align% dBTP
    echo �����ȷ�Χ:  %OLRA.align% LU
    echo �����ֵ:      %OT.align% LUFS
    echo ��׼������:    %NT.align%
    echo Ŀ��ƫ��:      %TO.align% LU
    echo=


    :: �ڶ��飺Ӧ�ò�������Ƶ�����б�׼��
    :: ������ڶ�̬ģʽ�������ʽ�Ϊ 192kHz
    echo=2-pass: ��Ƶ��׼��
    ffmpeg -y -threads 0 -hwaccel auto -i "%~1" -c:a pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:measured_I=%II%:measured_tp=%ITP%:measured_LRA=%ILRA%:measured_thresh=%IT%:offset=%TO%:print_format=summary" -copyts -map_chapters -1 -map_metadata -1 -f wav "%~dpn1_%loudness%LUFS.wav" -nostdin -hide_banner -v quiet
    echo=���.
    explorer /select,"%~dpn1_%loudness%LUFS.wav"
exit /b

:usage
    echo=�÷�: %~n0 ^<��Ƶ�ļ�·��^> [Ŀ�����:Ĭ��-16]
    echo=
    echo=��Ƚ���:
    echo=����/̸��:  -18 LUFS
    echo=��������:   -16 LUFS
    echo=��ϸ�ʽ:   -17 LUFS
    echo=�����˶�:   -17 LUFS
    echo=Ϸ��:       -17 LUFS
exit /b

:readVal <in> <out>
    :: ��ȡjson key:value�е�value
    call set "readVal.pair=%%%~1%%"
    set "readVal.pair=%readVal.pair:*:=%"
    set "readVal.pair=%readVal.pair:*"=%"
    set "readVal.pair=%readVal.pair:"=%"
    set "%~2=%readVal.pair:,=%"
    :: �ı������, ������ʾ
    if "%readVal.pair:~0,1%" == "-" (
        call set "%~2.align=%%%~2%%        "
    ) else (
        call set "%~2.align= %%%~2%%       "
    )
    call set "%~2.align=%%%~2.align:~0,8%%"
exit /b

:align <var-name> <length>
exit /b

:eval <...cmdline>
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
    if not "%debug%" == "0" set eval
exit /b
