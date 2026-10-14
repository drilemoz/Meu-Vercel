@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gradle-bootstrap.ps1" %*
exit /b %ERRORLEVEL%
