@echo off
title Pokemon Red - EDICION DEFINITIVA
cd /d "%~dp0"

rem pokered-plus: re-apply the Pokemon Yellow battle sprites over the Red
rem cache before every launch, so they survive a Red re-import. No-op if
rem Yellow is not imported or LuaJIT is missing.
set LUAJIT=%LOCALAPPDATA%\Programs\LuaJIT\bin\luajit.exe
if not exist "%LUAJIT%" for %%L in (luajit.exe) do set "LUAJIT=%%~$PATH:L"
if exist "%LUAJIT%" "%LUAJIT%" "scripts\pokered_plus_yellow_gfx.lua" >nul 2>&1

set LOVE=%ProgramFiles%\LOVE\love.exe
if not exist "%LOVE%" set LOVE=love
start "" "%LOVE%" "%~dp0." --game=red
