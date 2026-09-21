function Get-CIPPSecuritySimulationDefinition {
    <#
    .SYNOPSIS
        Returns the Security Simulation scenario catalog.
    .DESCRIPTION
        One scenario file per event at Config/SecuritySimulations/Scenarios/<id>.json.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($Id)

    $ScenarioPath = Join-Path $env:CIPPRootPath 'Config/SecuritySimulations/Scenarios'
    $Files = Get-ChildItem -Path $ScenarioPath -Filter '*.json' -ErrorAction SilentlyContinue
    if ($Id) {
        $Files = $Files | Where-Object { $_.BaseName -eq $Id }
    }

    foreach ($File in $Files) {
        try {
            $Scenario = [System.IO.File]::ReadAllText($File.FullName) | ConvertFrom-Json -ErrorAction Stop
            if (-not $Scenario.id) {
                $Scenario | Add-Member -NotePropertyName id -NotePropertyValue $File.BaseName
            }
            $Scenario
        } catch {
            Write-Information "Get-CIPPSecuritySimulationDefinition: failed to parse $($File.Name): $($_.Exception.Message)"
        }
    }
}
