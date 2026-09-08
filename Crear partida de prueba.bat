@echo off
title Crear partida de prueba (eventos Mew / Oak)
cd /d "%~dp0"
set LOVE=%ProgramFiles%\LOVE\love.exe
if not exist "%LOVE%" set LOVE=love
set POKEPORT_DRIVER=scripts\make_test_save.lua
echo Escribiendo partida de prueba de post-game...
"%LOVE%" "%~dp0." --game=red
echo.
echo Listo. Abri "Jugar Pokemon Red.bat" y elegi CONTINUAR.
echo Apareces en Pueblo Paleta con la Liga vencida y 150 registrados.
echo   - Evento de Oak : entra al laboratorio de Oak (el rival esta dentro).
echo   - Evento de Mew : ve a la Mansion Pokemon 3F en Isla Canela.
echo Para reiniciar los eventos, volve a ejecutar este .bat.
pause
