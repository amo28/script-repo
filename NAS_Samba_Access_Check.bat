@ECHO OFF
::CHECKNAS
::This script will check for access to a shared folder every 5 minutes and log the results
::to a file in C:\Temp.
::The check will be done by mapping the shared folder using two different user credentials.
::If the mapping fails, the script will issue a reset to the Samba service, and then run the check
::again.

::This is designed to workaround an issue with the QNAP NAS where all users would be locked from
::access until either a system reboot or a Samba restart.
SETLOCAL EnableDelayedExpansion

:SETVARIABLES
SET SHARE=\\NAS1\Images
IF NOT EXIST C:\Temp\CheckNAS MKDIR C:\Temp\CheckNAS
SET TEMP=C:\Temp\CheckNAS
SET PUTTY=C:\Putty

::Set Filename
::Dynamically change the filename based on site specific data set above and the date.
FOR /F "tokens=2-4 delims=/ " %%A IN ('ECHO %DATE%') DO SET MMDDYYYY=%%A-%%B-%%C
FOR /F %%3 IN ('ECHO CheckNAS_%MMDDYYYY%') DO SET FILENAME=%%3
GOTO USER1

:RESETSAMBA
ECHO Share NOT FOUND. %DATE:~4,10%,%TIME:~0,5% >> %FILENAME%.txt
CD %PUTTY%
plink.exe -ssh -pw [PASSWORD] [USER]@[HOSTNAME/IP] /etc/init.d/smb.sh restart ok-1>>%FILENAME%.txt 2>>&1
TIMEOUT /T 30

:USER1
::Map the share using USER1 credentials
CD %TEMP%
NET USE Z: %SHARE% /USER:[USER1] [PASSWORD]
IF EXIST Z: (ECHO USER1 - Share OK. %DATE:~4,10%,%TIME:~0,5% >> %FILENAME%.txt) ELSE (GOTO RESETSAMBA)
NET USE /DELETE Z:
TIMEOUT /T 10

:USER2
::Map the share using USER2 credentials
CD %TEMP%
NET USE Z: %SHARE% /USER:[USER2] [PASSWORD]
IF EXIST Z: (ECHO USER2  - Share OK. %DATE:~4,10%,%TIME:~0,5% >> %FILENAME%.txt) ELSE (GOTO RESETSAMBA)
NET USE /DELETE Z:

:CLEANUP
::Cleans up temp files older than 14 days.
FORFILES /P %TEMP% /M *.txt /D -14 /C "cmd /c del @file" >nul

ECHO Check complete. Exiting.
EXIT
