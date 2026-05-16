@echo off
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:4173/' -TimeoutSec 2; if ($r.StatusCode -eq 200 -and $r.Content -like '*DawnRiseCamp*') { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>nul
if errorlevel 1 (
  start "DawnRiseCamp local server" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
  for /l %%i in (1,1,10) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:4173/' -TimeoutSec 2; if ($r.StatusCode -eq 200 -and $r.Content -like '*DawnRiseCamp*') { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>nul
    if not errorlevel 1 goto open_site
    timeout /t 1 /nobreak >nul
  )
  echo Could not start the local server at http://127.0.0.1:4173/.
  pause
  exit /b 1
)

:open_site
start "" "http://127.0.0.1:4173/"
