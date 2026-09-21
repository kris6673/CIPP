function Get-CIPPSecuritySimulationRun {
    <#
    .SYNOPSIS
        Reads stored scenario runs for a tenant.
    .DESCRIPTION
        Without -ScenarioId returns one summary object per scenario that has been run (scenarioId, lastRun,
        summary). With -ScenarioId returns that scenario's full stored result, or nothing when it has never
        been run.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$TenantFilter,
        [string]$ScenarioId
    )

    $Table = Get-CippTable -tablename 'SecuritySimulationRuns'
    if ($ScenarioId) {
        $SafePartition = ConvertTo-CIPPODataFilterValue -Value "result_$TenantFilter"
        $SafeRow = ConvertTo-CIPPODataFilterValue -Value $ScenarioId
        $Row = Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq '$SafePartition' and RowKey eq '$SafeRow'" | Select-Object -First 1
        if (-not $Row -or -not $Row.Result) { return }
        $Result = $(try { $Row.Result | ConvertFrom-Json -Depth 20 -ErrorAction Stop } catch { $null })
        if ($null -eq $Result) { return }
        if (-not $Result.lastRun) { $Result | Add-Member -NotePropertyName lastRun -NotePropertyValue ([int64]($Row.LastRun ?? 0)) -Force }
        return $Result
    }

    $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter
    foreach ($Row in @(Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq '$SafeTenant'")) {
        if (-not $Row.RowKey) { continue }
        [PSCustomObject]@{
            scenarioId = "$($Row.RowKey)"
            lastRun    = [int64]($Row.LastRun ?? 0)
            summary    = $(try { $Row.Summary | ConvertFrom-Json -ErrorAction Stop } catch { $null })
        }
    }
}
