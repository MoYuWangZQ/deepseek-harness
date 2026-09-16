@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem setup-dsh-plugins.cmd - install the user plugins listed below into the local
rem dsh "web" profile. Idempotent: safe to re-run on any machine (clone -> run).
rem The PLUGINS line below is auto-maintained by sync-plugin-docs.cmd after any
rem marketplace install/uninstall - do not edit it by hand.
rem Usage: setup-dsh-plugins.cmd

set "PROFILE=web"
set "PLUGINS=dsh-plugin dsh-ui-appearance dsh-whale-widget"

if defined DSH_HOME (
  set "PROFILE_DIR=%DSH_HOME%\profiles\%PROFILE%"
) else (
  set "PROFILE_DIR=%USERPROFILE%\.dsh\profiles\%PROFILE%"
)

if not exist "%PROFILE_DIR%" (
  echo [dsh-plugins] profile "%PROFILE_DIR%" not found.
  echo Boot "dsh web" once on this machine first, then re-run this script.
  exit /b 1
)

set "MISSING="
for %%p in (%PLUGINS%) do (
  findstr /C:"%%p" "%PROFILE_DIR%\package.json" >nul 2>&1
  if errorlevel 1 set "MISSING=!MISSING! %%p"
)

if not defined MISSING (
  echo [dsh-plugins] all plugins already registered in profile "%PROFILE%":
  for %%p in (%PLUGINS%) do echo   - %%p
  exit /b 0
)

echo [dsh-plugins] installing:%MISSING%
where dsh >nul 2>&1
if not errorlevel 1 (
  call dsh plugin --profile "%PROFILE%" add%MISSING%
  goto :check
)

if exist "%~dp0..\apps\cli\lib\bin.js" (
  echo [dsh-plugins] installing via the local dsh build...
  call node "%~dp0..\apps\cli\lib\bin.js" plugin --profile "%PROFILE%" add%MISSING%
  goto :check
)

echo [dsh-plugins] no dsh CLI found on PATH and no local build under apps\cli\lib.
echo Run "pnpm install" (and "pnpm run build") in this checkout, or install dsh
echo globally (npm i -g @deepseek-ai/dsh), then re-run this script.
exit /b 1

:check
set "STILL="
for %%p in (%PLUGINS%) do (
  findstr /C:"%%p" "%PROFILE_DIR%\package.json" >nul 2>&1
  if errorlevel 1 set "STILL=!STILL! %%p"
)
if defined STILL (
  echo [dsh-plugins] still missing after install:%STILL%
  echo Check the output above and your network / registry settings.
  exit /b 1
)
echo [dsh-plugins] done. Restart "dsh web" to activate the plugins.
exit /b 0
