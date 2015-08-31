@echo off

set COPYCMD=/y

set prompt=$_%USERNAME% @ %COMPUTERNAME% : $P$_$G$S

DOSKEY ~=cd /d %USERPROFILE%
DOSKEY cd=cd $*$Tdir
DOSKEY ..=pushd ..
DOSKEY ...=pushd ..\..
DOSKEY l=dir /a /ogn /w $*
DOSKEY ll=dir /a /ogn $*
DOSKEY n=notepad.exe $*
DOSKEY ds=dir /s/b $*
DOSKEY fs=findstr /spin $1 $2
DOSKEY b=msbuild $*

rem Apps
if exist "%ProgramW6432%\Sublime Text 3\sublime_text.exe" (
    DOSKEY nn=start "" /B "%ProgramW6432%\Sublime Text 3\sublime_text.exe" $*
)
if exist "%ProgramFiles(x86)%\Git\bin\git.exe" (
    DOSKEY g="%ProgramFiles(x86)%\Git\bin\git.exe" $*
)

rem VS
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat" (
    echo Setting VS 2015 environment ...
    call "%ProgramFiles(x86)%\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 12.0\Common7\Tools\VsDevCmd.bat" (
    echo Setting VS 2013 environment ...
    call "%ProgramFiles(x86)%\Microsoft Visual Studio 12.0\Common7\Tools\VsDevCmd.bat"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 11.0\Common7\Tools\VsDevCmd.bat" (
    echo Setting VS 2012 environment ...
    call "%ProgramFiles(x86)%\Microsoft Visual Studio 11.0\Common7\Tools\VsDevCmd.bat"
)

cd /d %USERPROFILE%

if exist "%USERPROFILE%\profile.cmd" (
    call "%USERPROFILE%\profile.cmd"
)
