# Host-side dev watcher for the CIPP PowerShell modules.
#
# Compiles the CIPP modules into build/.devmodules (via build-dev-modules.ps1),
# then watches backend/Modules for source changes. When a compiled module's
# source changes it recompiles ONLY that module and restarts the Craft
# container, so the change goes live without a full image rebuild.
#
# Pair with docker-compose-no-frontend.yml, which overlays build/.devmodules/<mod>
# over the bind-mounted source for each module in the list below. Run this in its
# own terminal alongside `docker compose ... up`.
#
# NOTE: the overlay dirs must exist before `docker compose up`, otherwise Docker
# creates empty dirs that shadow the source. Start-Cipp-Dev-Windows-docker.ps1
# performs the initial blocking compile first and launches this with
# -SkipInitialBuild. When run standalone, leave -SkipInitialBuild off.
param(
    [string]   $SourceModules   = "$PSScriptRoot\..\..\backend\Modules",
    [string]   $OutputModules   = "$PSScriptRoot\..\.devmodules",
    [string[]] $Modules         = @('CIPPCore','CIPPHTTP','CIPPStandards','CIPPDB','CIPPAlerts','CIPPActivityTriggers','CippExtensions'),
    [string]   $Container       = 'cipp-api',
    [int]      $DebounceMs      = 750,
    [switch]   $SkipInitialBuild
)

$ErrorActionPreference = 'Stop'
$buildScript = Join-Path $PSScriptRoot 'build-dev-modules.ps1'

Write-Host "`n=== CIPP Dev Module Watcher ===" -ForegroundColor Cyan
Write-Host "  Source : $SourceModules"
Write-Host "  Output : $OutputModules"
Write-Host "  Modules: $($Modules -join ', ')"
Write-Host "  Restart: $Container`n"

if (-not $SkipInitialBuild) {
    & $buildScript -SourceModules $SourceModules -OutputModules $OutputModules -Modules $Modules
}

$sourceModulesPath = (Resolve-Path $SourceModules).Path

# One watcher over backend/Modules; a changed path is mapped back to its
# top-level module dir so we only recompile that module. Editors emit several
# events per save, so changes are queued by module name and debounced below.
$queue = [System.Collections.Concurrent.ConcurrentDictionary[string,datetime]]::new()
$fsw = [System.IO.FileSystemWatcher]::new($sourceModulesPath)
$fsw.IncludeSubdirectories = $true
$fsw.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

$action = {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -notmatch '\.(ps1|psd1|psm1)$') { return }
    $root = $Event.MessageData.Root
    $mods = $Event.MessageData.Modules
    $q    = $Event.MessageData.Queue
    $rel  = $path.Substring($root.Length).TrimStart('\', '/')
    $mod  = ($rel -split '[\\/]')[0]
    if ($mods -contains $mod) { $q[$mod] = [DateTime]::UtcNow }
}
$msgData = [pscustomobject]@{ Root = $sourceModulesPath; Modules = $Modules; Queue = $queue }
$subs = @(
    Register-ObjectEvent $fsw Changed -Action $action -MessageData $msgData
    Register-ObjectEvent $fsw Created -Action $action -MessageData $msgData
    Register-ObjectEvent $fsw Renamed -Action $action -MessageData $msgData
)
$fsw.EnableRaisingEvents = $true

Write-Host "Watching for changes (Ctrl+C to stop)..." -ForegroundColor Green
try {
    while ($true) {
        Start-Sleep -Milliseconds 250
        if ($queue.Count -eq 0) { continue }

        # Collect modules whose last change has settled past the debounce window.
        $now = [DateTime]::UtcNow
        $due = foreach ($mod in @($queue.Keys)) {
            $ts = [datetime]::MinValue
            if ($queue.TryGetValue($mod, [ref]$ts) -and ($now - $ts).TotalMilliseconds -ge $DebounceMs) { $mod }
        }
        if (-not $due) { continue }
        $removed = [datetime]::MinValue
        foreach ($mod in $due) { $queue.TryRemove($mod, [ref]$removed) | Out-Null }

        Write-Host "`n[$(Get-Date -Format HH:mm:ss)] recompiling: $($due -join ', ')" -ForegroundColor Cyan
        try {
            & $buildScript -SourceModules $SourceModules -OutputModules $OutputModules -Modules $due
            Write-Host "  restarting $Container ..." -NoNewline
            docker restart $Container | Out-Null
            Write-Host " done" -ForegroundColor Green
        } catch {
            Write-Host "  FAILED: $_" -ForegroundColor Red
        }
    }
} finally {
    $subs | Unregister-Event -ErrorAction SilentlyContinue
    $fsw.EnableRaisingEvents = $false
    $fsw.Dispose()
}
