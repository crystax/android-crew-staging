@echo off

setlocal

set GEM_HOME=
set GEM_PATH=

set CREWFILEDIR=%~dp0
set CREWHOSTOS=windows
if not defined SSL_CERT_FILE (
    set SSL_CERT_FILE=%CREWFILEDIR%etc\ca-certificates.crt
)

if not defined CREW_NDK_DIR (
    set CREW_NDK_DIR=%CREWFILEDIR%..
)

set POSTPONEDIR=%CREW_NDK_DIR%\postpone
if exist %POSTPONEDIR% (
    echo Found postpone dir %POSTPONEDIR%
    echo Please, cleanup manually before continuing
    exit /b 1
)


set CREWHOSTCPU=-x86_64
if not exist %CREW_NDK_DIR%\prebuilt\windows%CREWHOSTCPU% (
   set CREWHOSTCPU=
)

if not defined CREW_TOOLS_DIR (
   set CREW_TOOLS_DIR=%CREW_NDK_DIR%\prebuilt\windows%CREWHOSTCPU%
)

rem set CREW
rem set GIT

set PATH=%CREW_TOOLS_DIR%\bin;%PATH%
%CREW_TOOLS_DIR%\bin\ruby.exe -W0 %CREWFILEDIR%crew.rb %*

if exist %CREWFILEDIR%\crew.new (
    %CREWFILEDIR%\bin\update-crew-script.cmd %CREWFILEDIR%
)


if exist %POSTPONEDIR% (
    echo Start postponed upgrade process
    call %POSTPONEDIR%\upgrade.cmd
    echo = Copying new files
    xcopy %POSTPONEDIR%\prebuilt %CREW_NDK_DIR%\prebuilt /e/q
    echo = Cleaning up
    rd /q/s %CREW_NDK_DIR%\postpone
)

endlocal

exit /b %errorlevel%
