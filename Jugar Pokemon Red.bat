@echo off
title Pokemon Red
cd /d "%~dp0"
set LOVE=%ProgramFiles%\LOVE\love.exe
if not exist "%LOVE%" set LOVE=love
start "" "%LOVE%" "%~dp0." --game=red
