@echo off
setlocal
rem sync-plugin-docs.cmd - regenerate plugin/setup-dsh-plugins.cmd PLUGINS list
rem and the installed-plugin list inside PLUGIN-SYNC.md from the active dsh
rem "web" profile. Run after installing or uninstalling any plugin through the
rem marketplace. It does NOT touch git - commit and push separately.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-plugin-docs.ps1"
exit /b %errorlevel%
