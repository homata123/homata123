@echo off
:loop
echo Service1 is running
timeout /T 5 /nobreak >nul
goto loop