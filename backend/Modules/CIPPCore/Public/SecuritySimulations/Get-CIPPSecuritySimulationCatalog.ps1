function Get-CIPPSecuritySimulationCatalog {
    <#
    .SYNOPSIS
        Lists the scenarios with what the last stored run found for this tenant.
    .DESCRIPTION
        Nothing is evaluated here. Each scenario carries the summary of its last stored run (outcome, when
        it ran, how many controls are missing). A scenario that has never been run reports outcome NotRun,
        with the standards counted from the tenant's existing BaselineAlignment rows only.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($TenantFilter)

    $Scenarios = @(Get-CIPPSecuritySimulationDefinition)
    $Definitions = @(Get-CIPPBaselineDefinition)
    $StandardMap = Get-CIPPSecuritySimulationStandardMap -Definitions $Definitions

    $AlignmentRows = @()
    $Capabilities = $null
    $Runs = @{}
    if ($TenantFilter -and $TenantFilter -ne 'AllTenants') {
        $AlignmentTable = Get-CippTable -tablename 'BaselineAlignment'
        $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter
        $AlignmentRows = @(Get-CIPPAzDataTableEntity @AlignmentTable -Filter "PartitionKey eq '$SafeTenant'")
        $Capabilities = $(try { Get-CIPPTenantCapabilities -TenantFilter $TenantFilter } catch { $null })
        foreach ($Run in @(Get-CIPPSecuritySimulationRun -TenantFilter $TenantFilter)) { $Runs["$($Run.scenarioId)"] = $Run }
    }

    foreach ($Scenario in ($Scenarios | Sort-Object -Property category, title)) {
        $ScenarioId = "$($Scenario.id)"
        $Required = @($Scenario.requiredCapabilities | Where-Object { $_ })
        $Licensed = $null
        if ($Capabilities -and $Required.Count -gt 0) {
            $Licensed = @($Required | Where-Object { $Capabilities.$_ -eq $true }).Count -gt 0
        }

        $Run = $Runs[$ScenarioId]
        $Summary = $Run.summary
        if ($Run) {
            $Total = [int]($Summary.standardsTotal ?? 0)
            $Compliant = [int]($Summary.standardsCompliant ?? 0)
            $Gap = [int]($Summary.standardsGap ?? 0)
            $Unknown = [int]($Summary.standardsUnknown ?? 0)
        } else {
            $Entries = [System.Collections.Generic.List[object]]::new()
            if ($StandardMap.ContainsKey($ScenarioId)) {
                foreach ($StepId in $StandardMap[$ScenarioId].Keys) {
                    foreach ($Entry in $StandardMap[$ScenarioId][$StepId]) { $Entries.Add($Entry) }
                }
            }
            $States = @(foreach ($Entry in $Entries) {
                    Get-CIPPSimulationStandardState -TenantFilter $TenantFilter -Definition $Entry.Definition -Role $Entry.Role -AlignmentRows $AlignmentRows -RowsOnly
                })
            $Total = $States.Count
            $Compliant = @($States | Where-Object { $_.compliant -eq $true }).Count
            $Gap = @($States | Where-Object { $_.compliant -eq $false }).Count
            $Unknown = @($States | Where-Object { $null -eq $_.compliant }).Count
        }

        $Outcome = if (-not $Run) { 'NotRun' }
        elseif ($Summary.prevented -eq $true) { 'Prevented' }
        elseif ($Summary.detected -eq $true) { 'Detected' }
        else { 'NotPrevented' }

        [PSCustomObject]@{
            id                   = $ScenarioId
            title                = "$($Scenario.title)"
            category             = "$($Scenario.category)"
            severity             = "$($Scenario.severity)"
            summary              = "$($Scenario.summary)"
            stepCount            = @($Scenario.steps).Count
            usesWhatIf           = @($Scenario.steps | Where-Object { $_.whatIf }).Count -gt 0
            licensed             = $Licensed
            requiredCapabilities = @($Required)
            outcome              = $Outcome
            lastRun              = $(if ($Run) { [int64]$Run.lastRun } else { $null })
            prevented            = [bool]($Summary.prevented -eq $true)
            preventedWhenFixed   = [bool]($Summary.preventedWhenFixed -eq $true)
            detected             = [bool]($Summary.detected -eq $true)
            fixCount             = [int]($Summary.fixCount ?? 0)
            standardsTotal       = $Total
            standardsCompliant   = $Compliant
            standardsGap         = $Gap
            standardsUnknown     = $Unknown
        }
    }
}
