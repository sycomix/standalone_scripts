:: Purpose:       Deploys a file to remote system(s)
:: Requirements:  1. Administrative rights on the target machines
::                2. The file you are deploying must be in the same directory as this file
::                3. The list of systems you are deploying to must be in the same directory as this file
:: Author:        vocatus.gate@gmail.com // github.com/bmrf // reddit.com/user/vocatus // PGP: 0x07d1490f82a211a2
:: Usage:         Run like this:  .\deploy_file_to_systems.bat
:: History:       1.0.1 * Create destination directory if it doesn't already exist
::                      + Add more complete logging
::                1.0.0 + Initial write



:::::::::::::::
:: VARIABLES :: ---- Set these to your desired values
:::::::::::::::
:: Rules for variables:
::  * NO quotes!                       (bad:  "%SystemDrive%\directory\path"       )
::  * NO trailing slashes on the path! (bad:   %SystemDrive%\directory\            )
::  * Spaces are okay                  (okay:  %SystemDrive%\my folder\with spaces )
::  * Network paths are okay           (okay:  \\server\share name      )
::                                     (       \\172.16.1.5\share name  )

:: Log settings
set LOGPATH=%SystemDrive%\logs
set LOGFILE=deploy_file_to_systems.log

:: Target information
set SYSTEMS=systems.txt
set FILE=Registry.pol
set FILE2=lgpo.exe

:: PSexec location
:: set PSEXEC=psexec.exe


:::::::::::::::::::::
:: PREP AND CHECKS ::
:::::::::::::::::::::
@echo off && cls
set FILE_VERSION=1.0.1
set FILE_UPDATED=2020-07-16
:: Get the date into ISO 8601 standard format (yyyy-mm-dd) so we can use it
FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: Set title
title Deploying %FILE% to targets...

:: Make log directory if it doesn't exist
if not exist "%LOGPATH%" mkdir "%LOGPATH%"

:: Check that the target list exists
if not exist "%SYSTEMS%" (
	echo.
	echo ERROR: Cannot find %SYSTEMS%
	echo.
	echo        Place %SYSTEMS% in the same
	echo        directory as this script.
	echo.
	pause
	goto :eof
)

:: Check that our FILE exists
if not exist "%FILE%" (
	echo.
	echo ERROR: Cannot find %FILE%
	echo.
	echo        Place %FILE% in the same
	echo        directory as this script.
	echo.
	pause
	goto :eof
)

:: Check that our FILE2 exists
if not exist "%FILE2%" (
	echo.
	echo ERROR: Cannot find %FILE2%
	echo.
	echo        Place %FILE2% in the same
	echo        directory as this script.
	echo.
	pause
	goto :eof
)

:: Check that psexec exists
::if not exist "%PSEXEC%" (
::	echo.
::	echo ERROR: Cannot find %PSEXEC%
::	echo.
::	echo        Place %PSEXEC% in the same
::	echo        directory as this script.
::	echo.
::	pause
::	goto :eof
::)



:::::::::::::
:: EXECUTE ::
:::::::::::::


echo %CUR_DATE% %TIME%   Deploying %FILE% to systems listed in %SYSTEMS%...
echo %CUR_DATE% %TIME%   Deploying %FILE% to systems listed in %SYSTEMS%...>> "%LOGPATH%\%LOGFILE%" 2>&1

:: Upload the file to the remote system(s)
SETLOCAL ENABLEDELAYEDEXPANSION
for /f %%i in (%SYSTEMS%) do (
	ping %%i -n 1 >nul
	if /i not !ERRORLEVEL!==0 (
		echo %CUR_DATE% %TIME%  ^! %%i seems to be offline, skipping...
		echo %CUR_DATE% %TIME%  ^! %%i seems to be offline, skipping...>> "%LOGPATH%\%LOGFILE%" 2>&1
	) else (
		if not exist "\\%%i\c$\temp" mkdir "\\%%i\c$\temp" >> "%LOGPATH%\%LOGFILE%" 2>&1
		copy %FILE% /y "\\%%i\c$\temp\" >> "%LOGPATH%\%LOGFILE%" 2>&1
		copy %FILE2% /y "\\%%i\c$\temp\" >> "%LOGPATH%\%LOGFILE%" 2>&1
		echo %CUR_DATE% %TIME%    Uploaded to %%i.
		echo %CUR_DATE% %TIME%    Uploaded to %%i.>> "%LOGPATH%\%LOGFILE%" 2>&1
		
		:: wait for process to finish - DISABLED, was only used once
		:: we use cmd /c prefix to allow us to capture remote system output in the local log file
		:: %PSEXEC% -accepteula -nobanner -n 3 \\%%i cmd /c "c:\temp\lgpo.exe /v /m c:\temp\Registry.pol" >> "%LOGPATH%\%LOGFILE%" 2>&1
		
		:: don't wait for process to finish
		:: %PSEXEC% -accepteula -nobanner -n 3 -d \\%%i cmd /c "c:\temp\lgpo.exe /v /m c:\temp\Registry.pol" >> "%LOGPATH%\%LOGFILE%" 2>&1

		:: Cleanup
		echo %CUR_DATE% %TIME%   Cleaning up on %%i...
		echo %CUR_DATE% %TIME%   Cleaning up on %%i...>> "%LOGPATH%\%LOGFILE%" 2>&1
		del /f /q "\\%%i\c\$\temp\%FILE%"
		del /f /q "\\%%i\c\$\temp\%FILE2%"
		echo %CUR_DATE% %TIME%   Cleanup done, moving to next system.
		echo %CUR_DATE% %TIME%   Cleanup done, moving to next system.>> "%LOGPATH%\%LOGFILE%" 2>&1
	)
)
ENDLOCAL


:: Done
echo.
echo %CUR_DATE% %TIME%   Done.
echo %CUR_DATE% %TIME%   Done.>> "%LOGPATH%\%LOGFILE%" 2>&1




:eof
