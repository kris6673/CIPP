# Start CIPP local dev environment for windows.
#
# Runs docker compose up which starts:
#   1. Azurite (local Azure Storage emulator)
#   2. Craft API container (mounts ./backend for PS modules)
#   3. Next.js frontend started in ps directly since bind mounts are really slow in Docker for Windows
#
# Prerequisites:
#   - Docker Desktop running
#
# Access everything via http://localhost:5196

Write-Host "`n=== CIPP Dev Environment ===" -ForegroundColor Cyan
# Verify Windows Terminal is available
Get-Command wt -ErrorAction Stop | Out-Null
# Stop any existing node processes
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'
$RepoRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$frontendPath = Join-Path -Path $repoRoot -ChildPath 'frontend'
$dockerpath = Join-Path -Path $repoRoot -ChildPath 'build'
$frontendCommand = 'try { yarn install --network-timeout 500000; yarn run dev } catch { Write-Error $_.Exception.Message } finally { Read-Host "Press Enter to exit" }'
$frontendEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($frontendCommand))
$dockerCommand = 'try { ./tools/build-dev-modules.ps1; docker compose -f docker-compose-no-frontend.yml up --pull always --watch } catch { Write-Error $_.Exception.Message } finally { Read-Host "Press Enter to exit" }'
$dockerEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($dockerCommand))
$watcherCommand = 'try { ./tools/Watch-Cipp-Dev-Modules.ps1 -SkipInitialBuild } catch { Write-Error $_.Exception.Message } finally { Read-Host "Press Enter to exit" }'
$watcherEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($watcherCommand))
docker volume create cipp-ng_azurite-data
wt --title CIPP-Docker -d $dockerpath pwsh -EncodedCommand $dockerEncoded`; new-tab --title 'CIPP Modules' -d $dockerpath pwsh -EncodedCommand $watcherEncoded`; new-tab --title 'CIPP Frontend' -d $frontendPath pwsh -EncodedCommand $frontendEncoded

Write-Host "`n  API + Frontend: http://localhost:5196" -ForegroundColor Green
