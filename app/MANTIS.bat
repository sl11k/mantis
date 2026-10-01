@echo off
rem MANTIS dashboard: starts the local server and opens it in Chrome (or the default browser)
cd /d "%~dp0"
set URL=http://localhost:8765
set CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe
if exist "%CHROME%" (start "" "%CHROME%" %URL%) else (start "" %URL%)
node serve.js
