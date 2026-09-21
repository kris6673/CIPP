function Get-CIPPSecuritySimulationCatalog {
    <#
    .SYNOPSIS
        Lists the scenarios with a cheap per-tenant readiness summary.
    .DESCRIPTION
        Nothing is evaluated here: the counts come from the tenant's existing BaselineAlignment rows only
        (assigned standards compliant / drifted) plus a license check for the scenario's required
        capabilities.
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
    if ($TenantFilter -and $TenantFilter -ne 'AllTenants') {
        $AlignmentTable = Get-CippTable -tablename 'BaselineAlignment'
        $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter
        $AlignmentRows = @(Get-CIPPAzDataTableEntity @AlignmentTable -Filter "PartitionKey eq '$SafeTenant'")
        $Capabilities = $(try { Get-CIPPTenantCapabilities -TenantFilter $TenantFilter } catch { $null })
    }

    foreach ($Scenario in ($Scenarios | Sort-Object -Property category, title)) {
        $ScenarioId = "$($Scenario.id)"
        $Entries = [System.Collections.Generic.List[object]]::new()
        if ($StandardMap.ContainsKey($ScenarioId)) {
            foreach ($StepId in $StandardMap[$ScenarioId].Keys) {
                foreach ($Entry in $StandardMap[$ScenarioId][$StepId]) { $Entries.Add($Entry) }
            }
        }
        $States = @(foreach ($Entry in $Entries) {
                Get-CIPPSimulationStandardState -TenantFilter $TenantFilter -Definition $Entry.Definition -Role $Entry.Role -AlignmentRows $AlignmentRows -RowsOnly
            })
        $Required = @($Scenario.requiredCapabilities | Where-Object { $_ })
        $Licensed = $null
        if ($Capabilities -and $Required.Count -gt 0) {
            $Licensed = @($Required | Where-Object { $Capabilities.$_ -eq $true }).Count -gt 0
        }

        [PSCustomObject]@{
            id                 = $ScenarioId
            title              = "$($Scenario.title)"
            category           = "$($Scenario.category)"
            severity           = "$($Scenario.severity)"
            summary            = "$($Scenario.summary)"
            stepCount          = @($Scenario.steps).Count
            usesWhatIf         = @($Scenario.steps | Where-Object { $_.whatIf }).Count -gt 0
            standardsTotal     = $States.Count
            standardsCompliant = @($States | Where-Object { $_.compliant -eq $true }).Count
            standardsGap       = @($States | Where-Object { $_.compliant -eq $false }).Count
            standardsUnknown   = @($States | Where-Object { $null -eq $_.compliant }).Count
            licensed           = $Licensed
            requiredCapabilities = @($Required)
        }
    }
}
