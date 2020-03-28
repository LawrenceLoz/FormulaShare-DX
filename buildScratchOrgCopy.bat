@echo off
setlocal EnableDelayedExpansion

set X=
for /f "skip=1 delims=" %%x in ('wmic os get localdatetime') do if not defined X set X=%%x
set month=%X:~4,2%
set day=%X:~6,2%

set monthList=JanFebMarAprMayJunJulAugSepOctNovDec
set /a monthPos=(%month%-1)*3
set monthName=!monthList:~%monthPos%,3!

set orgName=%day%%monthName%FS
echo Username for default org: %orgName%