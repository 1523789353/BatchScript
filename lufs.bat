@echo off
call :main %*
exit /b %ErrorLevel%

:main
    :: ����/̸��: -18 LUFS
    :: ��������: -16 LUFS
    :: ��ϸ�ʽ: -17 LUFS
    :: �����˶�: -17 LUFS
    :: Ϸ��: -17 LUFS

    :: ��������루lossy encoding��֮ǰ�����ֵ��Ӧ����-1dBTP��
    :: ������Ϊ����������״�����ֵ���壨peak overshoot��������һ������Խ�͹���Ŀ��ܷ���Խ��

    :: �ۺ���ȡ����ֵ����ȷ�Χ
    set loudness=-16
    set truepeak=-0.5
    set loudrange=11

    if "%~1" == "" (
        echo=�÷�: %~n0 ^<��Ƶ�ļ�^>
        exit /b 1
    )

    if not exist "%~1" (
        echo=�ļ� "%~1" ������
        exit /b 1
    )

    echo=���ڴ����ļ� "%~1"
    echo=

    call :eval ffprobe -v error -select_streams a:0 -show_entries "stream=bits_per_sample,bits_per_raw_sample" -of "default=noprint_wrappers=1:nokey=1" "%~1"
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
    echo ʹ�� %bit_pcm% λ���й淶������

    :: ��һ�飺������Ƶ������ȡ�淶������
    set "eval.cmdline=ffmpeg -hide_banner -i "%~1" -c:a:0 pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:print_format=json" -f null - 2>&1 | findstr "\{ \"\ \:\ \" }" | find /v "#""
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

    echo=
    echo �����ۺ����: %II% LUFS
    echo �������ֵ:   %ITP% dBTP
    echo ������ȷ�Χ: %ILRA% LU
    echo ������ֵ:     %IT% LUFS
    echo ����ۺ����: %OI% LUFS
    echo ������ֵ:   %OTP% dBTP
    echo �����ȷ�Χ: %OLRA% LU
    echo �����ֵ:     %OT% LUFS
    echo ��׼������:   %NT%
    echo Ŀ��ƫ��:     %TO% LU
    echo=

    :: �ڶ��飺Ӧ�ò�������Ƶ�����й淶��
    :: ������ڶ�̬ģʽ�������ʽ�Ϊ 192kHz
    :: ��������� QAAC ���б���
    :: �Զ�ͨ������ SoX �������²����� 48kHz
    ffmpeg -hide_banner -y -i "%~1" -c:a pcm_s%bit_pcm%le -af "loudnorm=I=%loudness%:TP=%truepeak%:LRA=%loudrange%:measured_I=%II%:measured_tp=%ITP%:measured_LRA=%ILRA%:measured_thresh=%IT%:offset=%TO%:print_format=summary" -f wav "%~dpn1_%loudness%LUFS.wav" -v quiet
    echo=
exit /b

:readVal <in> <out>
    call set "readVal.pair=%%%~1%%"
    set "readVal.pair=%readVal.pair:*:=%"
    set "readVal.pair=%readVal.pair:*"=%"
    set "readVal.pair=%readVal.pair:"=%"
    set "%~2=%readVal.pair:,=%"
exit /b

:eval
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
exit /b
