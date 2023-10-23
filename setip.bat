:: Purpose:       Allows you to quickly change your IP address without using the GUI
:: Requirements:  Windows XP and up
:: Author:        reddit.com/user/vocatus ( vocatus.gate at gmail ) // PGP key: 0x07d1490f82a211a2
:: Version:       3.6.3 * Improve robustness of IPCONFIG output
::                3.6.2 * Updated preloaded DNS servers to use dns.watch's DNS instead of Google's
::                3.6.1 * Updated preloaded DNS servers to use Google's DNS instead of OpenDNS due to their stupid DNS hijacking
::                      - Removed some TITLE commands
::                3.6.0 * Reworked CUR_DATE variable to handle more than one Date/Time format
::                        Can now handle ISO standard dates (yyyy-mm-dd) and Windows default dates (e.g. "Fri 01/24/2014")
::                3.5.0 * Major re-write:
::                         -- Updated command-line argument ability. Can now specify DHCP or static after adapter name
::                         -- Added help section that will spit out when run from the command line
::                         -- Code cleanup and restructure
::                3.1.0 - Removed warning, fixed error when deleting temp file
::                3.0.0 * Major re-write:
::                         -- Added support for command-line invocation, with [optional] name of adapter to be changed
::                         -- Combined both scripts into one, and added warning to the beginning
::                         -- Script can now be invoked with adapter name to be changed. If not it will prompt for it.
::                         -- Re-wrote entire menu structure and added new options (DHCP, Quit)
::                         -- Now using %TEMP% variable for storing the working text files (for menus) instead of C:\
::                         -- Script now offers to use the OpenDNS servers as backup to the default gateway (for DNS)
::                2.0.0 / Changed hard-coded adapter name to a script-wide variable and cleaned up menus
::                1.5.0 + Created basic (ugly) menu structure
::                1.0.0   Initial write
@echo off
SETLOCAL


:::::::::::::::
:: VARIABLES :: --------------- These are the defaults. Change them if you so desire. -------- ::
:::::::::::::::
:: Rules for variables:
::  * NO quotes!                       (bad:  "c:\directory\path"       )
::  * NO trailing slashes on the path! (bad:   c:\directory\            )
::  * Spaces are okay                  (okay:  c:\my folder\with spaces )
::  * Network paths are okay           (okay:  \\server\share name      )
::                                     (       \\172.16.1.5\share name  )
:: \/ The first argument passed to the script becomes the adapter to be changed. \/
set ADAPTER_NAME=%1
set IP=
set GATEWAY=
set MASK=
set DNS1=
set DNS2=84.200.69.80
set DNS3=84.200.70.40




:: --------------------------- Don't edit anything below this line --------------------------- ::



:::::::::::::::::::::
:: Prep and checks ::
:::::::::::::::::::::

set SCRIPT_VERSION=3.6.3
set SCRIPT_UPDATED=2020-07-16
:: Get the date into ISO 8601 standard format (yyyy-mm-dd) so we can use it
FOR /f %%a in ('WMIC OS GET LocalDateTime ^| find "."') DO set DTS=%%a
set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%

:: Get IP information (excluding VMware adapters)
if exist "%TEMP%\temp_ethernet_adapter_config1.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config1.txt" >nul
if exist "%TEMP%\temp_ethernet_adapter_config.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config.txt" >nul
if exist "%TEMP%\tmpip.txt" del /f /q "%TEMP%\tmpip.txt" >nul
:: Get all non-VMWare adapters
netsh interface show interface | findstr /v VMware | findstr Enabled > "%TEMP%\tmpip.txt" && @for /f "tokens=4" %%a in (%TEMP%\tmpip.txt) do @netsh interface ip show config name=%%a >> "%TEMP%\temp_ethernet_adapter_config1.txt"
:: Strip out the terms "metric" "WINS" and "suffix"
findstr /i /v "metric WINS suffix" <"%TEMP%\temp_ethernet_adapter_config1.txt" >"%TEMP%\temp_ethernet_adapter_config.txt"


:::::::::::::::::::::
:: Check arguments ::
:::::::::::::::::::::
:: Catch the most common "help" arguments
if '%1%'=='h' goto help
if '%1%'=='-h' goto help
if '%1%'=='/h' goto help
if '%1%'=='?' goto help
if '%1%'=='-?' goto help
if '%1%'=='/?' goto help


:: Normal Argument catching
:: 1. Did the user pass an argument upon invocation? If not, go to the menu
:: 2. Did the user say to use DHCP? If so, skip directly to DHCP
:: 3. Did the user say to use Static? If so, skip directly to asking for the values
if '%1%'=='' goto specify_adapter
if '%2%'=='dhcp' goto dhcp
if '%2%'=='static' goto enter_values
goto start


::::::::::
:: Help ::
::::::::::
:help
echo.
echo  %~nx0 v%SCRIPT_VERSION% -- Set your IP address from the command line. 
echo.
echo  USAGE: 
echo    %~nx0 ^["adapter name"^] ^[dhcp ^| static^]
echo.
echo  where:
echo      adapter name -- Optional: specify which adapter to modify
echo      dhcp         -- Optional: specify to attempt to get an IP address via DHCP
echo      static       -- Optional: specify you want to set a static IP address
echo.
echo  If you run the script with no arguments it will go to the interactive menu.
echo  If the adapter name has spaces in it, surround it with quotes "like this"
echo.
goto end


:::::::::::::::::::::
:: Specify Adapter :: - Only called if the user didn't pass an adapter name as the first argument
:::::::::::::::::::::
:specify_adapter
cls
title TCP/IP Configuration for LAN

echo.
echo ------------------------------
echo  Current TCP/IP Configuration
echo ------------------------------
type "%TEMP%\temp_ethernet_adapter_config.txt"
echo.
echo  ************************************************************
echo  Which adapter do you want to change? (eth0, wlan0, etc)
echo.
echo  (To save time, run the script with the name of the adapter 
echo  you want changed)
echo.
echo  Examples:  %~nx0 "Local Area Connection 1"
echo             %~nx0 eth0 static
echo             %~nx0 eth1 dhcp
echo  ************************************************************
echo.
set /p ADAPTER_NAME=Enter the name of the ADAPTER to change: 
goto start

		
:::::::::::::::::
:: Main Screen ::
:::::::::::::::::
:start
title TCP/IP Config for "%ADAPTER_NAME%" & cls
echo.
echo ------------------------------
echo  Current TCP/IP Configuration
echo ------------------------------
echo.
type "%TEMP%\temp_ethernet_adapter_config.txt"
echo. 
echo. 
echo    Adapter to be changed is: "%ADAPTER_NAME%"
echo    -----------------------------------
echo    Enter "1" to change the IP address manually.
echo    Enter "2" to set the adapter to DHCP and attempt to acquire an address.
echo    Enter "3" to pick a different adapter to change.
echo    Enter "4" to quit.
:menu
set choice=
echo.
set /p choice=Choice: 
if not '%choice%'=='' set choice=%choice:~0,1%
	if '%choice%'=='1' goto enter_values
	if '%choice%'=='2' goto dhcp
	if '%choice%'=='3' goto specify_adapter
	if '%choice%'=='4' goto cancel
echo.
echo  "%choice%" is not valid, please try again
echo.
goto menu 
pause

::::::::::::::::::
:: Enter Values ::
::::::::::::::::::
:enter_values
echo.
echo  Modifying adapter "%ADAPTER_NAME%"
echo.
set /p IP=Enter the new IP address:        
set /p MASK=Enter the new subnet mask:       
set /p GATEWAY=Enter the new default gateway:   
	set DNS1=%GATEWAY%
	
echo.
echo These default DNS servers will be loaded:
echo Primary:   %GATEWAY% (default gateway)
echo Secondary: %DNS2% (OpenDNS)
echo Tertiary:  %DNS3% (OpenDNS)
echo.
	set /p CHOICE=Is this okay? [Y/n]: 
	if '%CHOICE%'=='y' goto execute_prompt
	if '%CHOICE%'=='n' goto enter_dns

:::::::::::::
:: EXECUTE ::
:::::::::::::
:execute_prompt
color f0
cls
echo.
echo About to apply this configuration:
echo.
echo IP Address:      %IP%
echo Subnet Mask:     %MASK%
echo Default Gateway: %GATEWAY%
echo DNS Servers:     %DNS1% (Primary)
echo                  %DNS2%
echo                  %DNS3%
echo.
set /p CHOICE=Apply this configuration? [Y/n]: 
	if '%CHOICE%'=='y' goto execute_do
	if '%CHOICE%'=='n' goto start

:execute_do
color & cls
echo.
echo Applying the TCP/IP configuration.
echo This could take up to 30 seconds, please be patient...
echo.
echo Setting IP address to %IP%...
	netsh interface ip set address name="%ADAPTER_NAME%" source=static %IP% %MASK% %GATEWAY% 1
echo Setting the default gateway %GATEWAY% as primary DNS...
	netsh interface ip set dns name="%ADAPTER_NAME%" static %DNS1% primary
echo Setting %DNS2% and %DNS3% as the alternate DNS servers...
	netsh interface ip add dns name="%ADAPTER_NAME%" %DNS2% index=2
	netsh interface ip add dns name="%ADAPTER_NAME%" %DNS3% index=3
goto done


::::::::::
:: DHCP ::
::::::::::
:dhcp
echo.
echo Using DHCP to acquire IP address for adapter "%ADAPTER_NAME%"...
echo.
netsh interface ip set address name="%ADAPTER_NAME%" source=dhcp
echo Using DHCP to acquire DNS servers...
netsh interface ip set dns name="%ADAPTER_NAME%" source=dhcp
ipconfig /renew
goto done


::::::::::::::::
:: Manual DNS :: Only used when user isn't okay with default DNS settings. Is skipped most of the time.
::::::::::::::::
:enter_dns
set /p DNS1=Enter IP address of first DNS server:  
set /p DNS2=Enter IP address of second DNS server: 
set /p DNS3=Enter IP address of third DNS server:  
goto execute_prompt

::::::::::
:: DONE ::
::::::::::
:done
cls
:: Show user the results. We output IP config information to a file, strip out some stuff, then present the results. Finally, we delete the temp file. 
echo.
echo   Results:
echo   --------
ipconfig /all > "%TEMP%\tempLANconfig.txt"
findstr /R "IPv4 IPv6 Subnet DHCP Dhcp IP.A Default Ethernet DNS.Ser" <"%TEMP%\tempLANconfig.txt" >"%TEMP%\tempLANconfig2.txt"
echo.
type "%TEMP%\temp_ethernet_adapter_config.txt"
echo.
if exist "%TEMP%\temp_ethernet_adapter_config1.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config1.txt" >nul
if exist "%TEMP%\temp_ethernet_adapter_config.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config.txt" >nul
if exist "%TEMP%\tmpip.txt" del /f /q "%TEMP%\tmpip.txt" >nul
pause
goto end

:cancel
cls
echo.
echo Canceled! Goodbye.

:end
if exist "%TEMP%\temp_ethernet_adapter_config1.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config1.txt" >nul
if exist "%TEMP%\temp_ethernet_adapter_config.txt" del /f /q "%TEMP%\temp_ethernet_adapter_config.txt" >nul
if exist "%TEMP%\tmpip.txt" del /f /q "%TEMP%\tmpip.txt" >nul
ENDLOCAL
