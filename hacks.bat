@echo off
pushd "%~dp0"

if [%1]==[] (	
	mame.exe
	goto exit
)

set rompath=%~dp1
set rompath=%rompath:~0,-1%
mame.exe -keyboardprovider dinput -skip_gameinfo -nowindow -rompath "%rompath%" %~n1

:exit
popd