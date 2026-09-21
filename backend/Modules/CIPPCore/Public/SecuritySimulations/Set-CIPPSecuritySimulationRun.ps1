function Set-CIPPSecuritySimulationRun {
    <#
    .SYNOPSIS
        Stores the outcome of one scenario run so the catalog and the run view can show it without
        re-evaluating.
    .DESCRIPTION
        Two rows per scenario in the SecuritySimulationRuns table: a summary row (partition = tenant) the
        catalog reads for every scenario at once, and a full-result row (partition = result_<tenant>) the
        run view reads for one scenario.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$TenantFilter,
        [Parameter(Mandatory = $true)]$Result
    )

    $Table = Get-CippTable -tablename 'SecuritySimulationRuns'
    $ScenarioId = "$($Result.scenario.id)"
    $LastRun = [int64]($Result.lastRun ?? [datetimeoffset]::UtcNow.ToUnixTimeSeconds())

    Add-CIPPAzDataTableEntity @Table -Force -Entity @{
        PartitionKey = "$TenantFilter"
        RowKey       = $ScenarioId
        LastRun      = $LastRun
        Summary      = (ConvertTo-Json -Compress -Depth 10 -InputObject $Result.summary)
    }
    Add-CIPPAzDataTableEntity @Table -Force -Entity @{
        PartitionKey = "result_$TenantFilter"
        RowKey       = $ScenarioId
        LastRun      = $LastRun
        Result       = (ConvertTo-Json -Compress -Depth 20 -InputObject $Result)
    }
}
