function Get-CIPPSecuritySimulationStandardMap {
    <#
    .SYNOPSIS
        Inverts the simulatorScenarios tags on the Baseline standard definitions into
        scenario -> step -> standards.
    .DESCRIPTION
        A definition declares where it matters: "simulatorScenarios": [ { "scenario": "StolenTokenReplay",
        "step": "Persistence", "role": "prevents" } ] The scenario files stay narrative-only; this map is
        the single place the two meet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($Definitions)

    if (-not $Definitions) {
        $Definitions = @(Get-CIPPBaselineDefinition)
    }

    $Map = @{}
    foreach ($Definition in $Definitions) {
        foreach ($Tag in @($Definition.simulatorScenarios | Where-Object { $_ })) {
            $ScenarioId = "$($Tag.scenario)"
            $StepId = "$($Tag.step)"
            if (-not $ScenarioId -or -not $StepId) { continue }
            if (-not $Map.ContainsKey($ScenarioId)) { $Map[$ScenarioId] = @{} }
            if (-not $Map[$ScenarioId].ContainsKey($StepId)) {
                $Map[$ScenarioId][$StepId] = [System.Collections.Generic.List[object]]::new()
            }
            $Map[$ScenarioId][$StepId].Add([PSCustomObject]@{
                    Definition = $Definition
                    Role       = $(if ("$($Tag.role)") { "$($Tag.role)" } else { 'prevents' })
                })
        }
    }
    $Map
}
