@echo off

if not exist %~dp0DrawDog.exe goto NODOG

goto ADMIN


:NODOG
echo No DrawDog.exe found!
pause >nul
exit

:ADMIN
:: https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights   
net session >nul 2>&1
if %errorLevel% == 0 (
    goto REGISTER
) else (
    goto NOADMIN
)

:NOADMIN
echo Admin Permission Required!
pause >nul
exit

:REGISTER
@echo on
reg add HKEY_CLASSES_ROOT\DrawDogOnline /t REG_SZ /d "DrawDogOnline protocol" /f
reg add HKEY_CLASSES_ROOT\DrawDogOnline /v "URL Protocol" /t REG_SZ /d "" /f
reg add HKEY_CLASSES_ROOT\DrawDogOnline\shell /f
reg add HKEY_CLASSES_ROOT\DrawDogOnline\shell\open /f
reg add HKEY_CLASSES_ROOT\DrawDogOnline\shell\open\command /t REG_EXPAND_SZ /d "%~dp0DrawDog.exe \"%%1\"" /f
@echo off
echo.
echo Done!
pause >nul
