@echo off
:: Download the PowerShell script
powershell -Command "iwr https://raw.githubusercontent.com/James-Tarran/autopilot/refs/heads/main/autopilot.ps1 -outfile C:\autopilot.ps1"

:: Set the execution policy
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope Process -Force"

:: Run the downloaded PowerShell script
powershell -Command "C:\autopilot.ps1"
