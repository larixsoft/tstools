@echo off
:: current working direcotry
set build_root=%CD%

::set default build params
set build_config=Debug
set build_type=all
set build_target=all
set build_platform=x64

:: parse arguments
:initial
if "%1"=="" goto done
set aux=%1
if "%aux:~0,1%"=="-" (
   set nome=%aux:~1,250%
) else (
   set "%nome%=%1"
   set nome=
)
shift
goto initial
:done

:: check if we have cmake.exe on path
where /q cmake.exe >nul 2>&1
IF %errorlevel% NEQ 0 (
    echo setting up cmake enviroment ...
    call set_cmake_path.bat
) else (
    echo find cmake.exe in your path settings.
)

:: check if we have msbuild.exe on path
where /q msbuild.exe >nul 2>&1
IF %errorlevel% NEQ 0 (
    echo setting up msbuild enviroment ...
    call set_msbuild_path.bat
) else (
    echo find msbuild.exe in your path settings.
)

:: set Qt5 path
:: check if we have cmake.exe on path
where /q qmake.exe >nul 2>&1
IF %errorlevel% NEQ 0 (
    echo setting up Qt5 enviroment ...
    if /I %build_platform%==win32 (
        call set_qt5_32_path.bat
    ) else if /I %build_platform%==x64 (
        call set_qt5_64_path.bat
    )
) else (
    echo find qmake.exe in your path settings.
)

:: set cygwin path
:: check if we have pkg-config.exe on path
where /q pkg-config.exe >nul 2>&1
IF %errorlevel% NEQ 0 (
    echo setting up cygwin enviroment ...
    call set_cygwin_path.bat
    )
) else (
    echo find pkg-config.exe in your path settings.
)

:: set GStreamer path
:: check if we have gst-play-1.0.exe on path
where /q gst-play-1.0.exe >nul 2>&1
IF %errorlevel% NEQ 0 (
    echo setting up GStreamer-1.0 enviroment ...
    if /I %build_platform%==win32 (
        call set_gstreamer_32.bat
    ) else if /I %build_platform%==x64 (
        call set_gstreamer_64.bat
    )
) else (
    echo find gst-play-1.0.exe in your path settings.
)


:: Configuration summaries
set build_dir=%build_root%\build\%build_platform%\%build_config%
set build_solution=%build_dir%\tstools.sln
echo ================================================================================
echo build_config   = %build_config%
echo build_platform = %build_platform%
echo build_type     = %build_type%
echo build_target   = %build_target%
echo working_dir    = %build_root%
echo build_dir      = %build_dir%
echo build_solution = %build_solution%
echo ================================================================================

::sanity check for build_platform
if /I %build_platform%==Win32 (
    if not exist "%build_root%\build\win32" mkdir "%build_root%\build\win32"
) else if /I %build_platform%==x64 (
    if not exist "%build_root%\build\x64" mkdir "%build_root%\build\x64"
) else (
    echo unsupported build_platform: %build_platform%.
    echo options are:
    echo       Win32: for 32bit applications, default value.
    echo         x64: for 64bit applications
    goto error
)

:: sanity check for build_config
if /I %build_config%==debug (
    if not exist "%build_root%\build\%build_platform%\debug" mkdir "%build_root%\build\%build_platform%\debug"
) else if /I %build_config%==release (
    if not exist "%build_root%\build\%build_platform%\release" mkdir "%build_root%\build\%build_platform%\release"
) else if /I %build_config%==MinSizeRel (
    if not exist "%build_root%\build\%build_platform%\MinSizeRel" mkdir "%build_root%\build\%build_platform%\MinSizeRel"
)else if /I %build_config%==RelWithDebInfo (
    if not exist "%build_root%\build\%build_platform%\RelWithDebInfo" mkdir "%build_root%\build\%build_platform%\RelWithDebInfo"
)else (
    echo unsupported build_config: %build_config%.
    echo Options are:
    echo            debug: for debug version, default value.
    echo          release: for release version
    echo   RelWithDebInfo: for release version with debug info
    echo       MinSizeRel: for release version with minisize
    goto error
)

:: sanity check for build_type
if /I %build_type%==all (
    if exist "%build_root%\build\%build_platform%\%build_config%" (
        rmdir /s /q "%build_root%\build\%build_platform%\%build_config%"
    )
    mkdir "%build_root%\build\%build_platform%\%build_config%"
    goto cstart
) else if /I %build_type%==dev (
    if not exist "%build_root%\build\%build_platform%\%build_config%" (
        mkdir "%build_root%build\%build_platform%\%build_config%"
        goto cstart
    ) else (
        goto cend
    )
) else (
    echo unsupported build_type: %build_type%.
    echo Options are:
    echo         all: to start a new build from scratch, default value.
    echo         dev: to build the newly updated code only
    goto error
)

:: start the cmake build process
:cstart

if not exist "%build_root%\build\%build_platform%\%build_config%" (
    echo cannot find "%build_root%\build\%build_platform%\%build_config%"
    goto error
)

cd "%build_root%\build\%build_platform%\%build_config%"
echo %CD%
echo "start the cmake build process ..."
if /I %build_platform%==win32 (
    cmake -DCMAKEbuild_TYPE=%build_config% -DBUILD_PLATFORM=%build_platform% -G "Visual Studio 14 2015" %build_root%
) else if /I %build_platform%==x64 (
    cmake -DCMAKEbuild_TYPE=%build_config% -DBUILD_PLATFORM=%build_platform% -G "Visual Studio 14 2015 Win64" %build_root%
)
IF %errorlevel% NEQ 0 (
    cd %build_root%
    goto error
)
:cend
cd "%build_root%\build\%build_platform%\%build_config%"

:: start the msbuild build process
if /I %build_target%==all (
    msbuild /p:Configuration=%build_config% /p:platform=%build_platform% %build_solution%
    IF %errorlevel% NEQ 0 (
        cd %build_root%
        goto error
    )
) else (
    for /r %build_dir% %%a in (*.vcxproj) do (
        if "%%~nxa"=="%build_target%.vcxproj" (
            echo start to build %%~dpnxa ...
            echo call "msbuild /m /p:Configuration=%build_config% /p:platform=%build_platform% %%~dpnxa"
            msbuild /p:Configuration=%build_config% /p:platform=%build_platform% %%~dpnxa
            IF %errorlevel% NEQ 0 (
                goto error
            )
            goto success
        )
    )
    echo error: cannot find %build_target%.vcxproj in current build
    goto error
)

:: summaries
:success
cd %build_root%
echo build for build_config: %build_config%, build_platform: %build_platform%, build_type: %build_type%, build_target: %build_target% done.
EXIT /B 0

:error
echo build for build_config: %build_config%, build_platform: %build_platform%, build_type: %build_type%, build_target: %build_target% failed.
cd %build_root%
goto halt 2>nul
