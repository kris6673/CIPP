# The scheduler reads backend/Config/alerts.json for each alert's minimumRunInterval; the UI reads the frontend copy.
# Edit frontend/src/data/alerts.json and run build/tools/Update-AlertsJson.ps1 to sync the backend copy.

BeforeAll {
    $BackendRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    $script:Frontend = Join-Path (Split-Path -Parent $BackendRoot) 'frontend/src/data/alerts.json'
    $script:Backend = Join-Path $BackendRoot 'Config/alerts.json'
}

Describe 'alerts.json copies' {
    It 'keeps the backend copy identical to the frontend catalog' {
        $Read = { param($Path) [System.IO.File]::ReadAllText($Path).Replace("`r`n", "`n") }
        & $Read $script:Backend | Should -BeExactly (& $Read $script:Frontend) -Because 'run build/tools/Update-AlertsJson.ps1 after editing frontend/src/data/alerts.json'
    }

    It 'gives every minimumRunInterval a recurrence the scheduler understands' {
        $Catalog = Get-Content -Path $script:Frontend -Raw | ConvertFrom-Json
        foreach ($Alert in $Catalog.Where({ $_.minimumRunInterval })) {
            $Alert.minimumRunInterval | Should -Match '^\d+[mhd]$' -Because "$($Alert.name) is gated on it"
        }
    }
}
