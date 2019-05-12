@echo off
set nvram=C:\Users\Heads\OneDrive\SAVEDG~1\Mess\nvram
set romPath="roms;R:\Arcade\MAME Roms\Others;R:\MAME Assets\Devices;R:\MAME Assets\Software;R:\MAME Assets\Non Arcade System Clones"

if [%1]==[gnw] goto :callMessWithDummyMachineArg
if [%1]==[electronic] goto :callMessWithDummyMachineArg
if [%1]==[a2600] goto :a2600
if [%1]==[a7800] goto :a7800
if [%1]==[coleco] goto :coleco
if [%1]==[odyssey2] goto :odyssey2
if [%1]==[pce] goto :pce
if [%1]==[famicom] goto :famicom
if [%1]==[genesis] goto :genesis
if [%1]==[gamegear] goto :gamegear
if [%1]==[sms] goto :sms
if [%1]==[plus4] goto :plus4
if [%1]==[pico] goto :pico
if [%1]==[vsmile] goto :vsmile
if [%1]==[svision] goto :svision
if [%1]==[a800] goto :a800

:callMess
pushd "%~dp0"
powershell -File .\mess.ps1 %* -skip_gameinfo -rompath %romPath% -nvram_directory %nvram%
popd
goto :end

:callMessWithDummyMachineArg
pushd "%~dp0"
set dir="%~dp2"
set rom=%~n2
powershell -File .\mess.ps1 %1 %rom% -skip_gameinfo -rompath %romPath%;%dir% -nvram_directory %nvram%
popd
goto :end

:a2600
set rom="%~nx3"

if not %rom:(PAL)=%==%rom% (
	%0 a2600p %2 %3
)

goto :callMess

:a7800
set rom="%~nx3"

if not %rom:(Europe)=%==%rom% (
	%0 a7800p %2 %3
)

goto :callMess

:coleco
set rom="%~nx3"

if not %rom:(Europe)=%==%rom% (
	%0 colecop %2 %3
)

goto :callMess

:odyssey2
set rom="%~nx3"

if not %rom:(Euro=%==%rom% (
	if %rom:USA)=%==%rom% (
		%0 videopac %2 %3
	)
)

goto :callMess

:pce
7z l %3 | find "(japan)" >nul

if %errorlevel%==1 (
	%0 tg16 %2 %3
)

goto :callMess

:famicom
if [%5]==[] goto :callMess
set rom=%~n5
set romPath=%~dp5
set romPath="%romPath:~0,-1%"
call :callMess %1 %2 %3 %4 %rom%
goto :end

:genesis
set rom="%~nx3"
set specialPart=%rom:*(=%
set specialPart=%specialPart:"=%

if "%specialPart%"==%rom% goto :callMess
set endSpecialPart=%specialPart:*)=%
call set specialPart=%%specialPart:)%endSpecialPart%=%%

if "%specialPart%"=="1" (
	%0 megadrij %2 %3
)

if "%specialPart%"=="8" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="As" (
	%0 megadrij %2 %3
)

if "%specialPart%"=="B" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="Ch" (
	%0 megadrij %2 %3
)

if "%specialPart%"=="D" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="F" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="G" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="Gr" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="HK" (
	%0 megadrij %2 %3
)

if "%specialPart%"=="I" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="K" (
	%0 megadrij %2 %3
)

if "%specialPart%"=="Nl" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="No" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="S" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="Sw" (
	%0 megadriv %2 %3
)

if "%specialPart%"=="UK" (
	%0 megadriv %2 %3
)

set specialPartCheck=%specialPart:U=%
if not "%specialPartCheck%"=="" set specialPartCheck=%specialPartCheck:J=%
if not "%specialPartCheck%"=="" set specialPartCheck=%specialPartCheck:E=%

if not "%specialPartCheck%"=="" goto :callMess

if "%specialPart:U=%"=="%specialPart%" (
	if "%specialPart:E=%"=="%specialPart%" (
		%0 megadrij %2 %3
	)
		
	%0 megadriv %2 %3
)

goto :callMess

:gamegear
set rom="%~nx3"

if not %rom:(Jpn)=%==%rom% (
	%0 gamegeaj %2 %3
)

goto :callMess

:sms
set rom="%~nx3"

if not %rom:(Kor)=%==%rom% (
	%0 smskr %2 %3
)

if not %rom:(Bra)=%==%rom% (
	%0 smspal %2 %3
)

if not %rom:(Euro=%==%rom% (
	%0 smspal %2 %3
)

if not %rom:(Jpn)=%==%rom% (
	%0 smsj %2 %3
)

goto :callMess

:plus4
set rom="%~nx3"

if not %rom:(PAL)=%==%rom% (
	%0 plus4p %2 %3
)

goto :callMess

:pico
set rom="%~nx3"

if not %rom:(USA=%==%rom% (
	%0 picou %2 %3
)

if not %rom:(Jpn=%==%rom% (
	%0 picoj %2 %3
)

goto :callMess

:vsmile

if [%3]==[] goto :callMess

set extension=%~x3
set rom="%~nx3"

if not %rom:(Ger=%==%rom% (
	if "%extension%"==".zip" (
		%0 vsmileg %3
	) else (
		%0 vsmileg %2 %3
	)
)

if %rom:(USA=%==%rom% (
	if "%extension%"==".zip" (
		%0 vsmilef %3
	) else (
		%0 vsmilef %2 %3
	)
)

if "%extension%"==".zip" (
	%0 vsmile %3
) else (
	goto :callMess
)

:svision
set rom="%~nx3"

if not %rom:(Euro=%==%rom% (
	%0 svisionp %2 %3
)

%0 svisionn %2 %3

:a800
set rom="%~nx2"

if not %rom:(PAL)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(PL)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(DE)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(GB)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(SW)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(FW)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(CS)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(FR)=%==%rom% (
	%0 a800pal %2
)

if not %rom:(ES)=%==%rom% (
	%0 a800pal %2
)

goto :callMess

:end
