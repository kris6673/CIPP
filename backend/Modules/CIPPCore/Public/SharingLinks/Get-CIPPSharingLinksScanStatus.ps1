function Get-CIPPSharingLinksScanStatus {
    <#
    .SYNOPSIS
        Whether a tenant's sharing-links scan is still running, and the queue tracking it.
    .DESCRIPTION
        A scan is in progress from its 'scan' state row until it writes its 'final' marker. One that
        has not finalised within 24 hours is treated as abandoned, so a lost run cannot block new scans.
    .FUNCTIONALITY
        Internal
    #>
    param([Parameter(Mandatory = $true)][string]$TenantFilter)

    $TenantFilter = @(Get-Tenants -TenantFilter $TenantFilter -IncludeErrors)[0].defaultDomainName ?? $TenantFilter
    $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter -Type String
    $StateTable = Get-CippTable -tablename 'CippSharingLinksState'
    $Scan = Get-CIPPAzDataTableEntity @StateTable -Filter "PartitionKey eq '$SafeTenant' and RowKey eq 'scan'"
    $Final = Get-CIPPAzDataTableEntity @StateTable -Filter "PartitionKey eq '$SafeTenant' and RowKey eq 'final'"
    $Finalised = [bool]$Final -and [string]$Final.ScanId -eq [string]$Scan.ScanId
    $Started = $(try { [DateTimeOffset]::Parse([string]$Scan.StartedUtc) } catch { [DateTimeOffset]::MinValue })
    [PSCustomObject]@{
        inProgress = [bool]$Scan -and -not $Finalised -and $Started -gt [DateTimeOffset]::UtcNow.AddHours(-24)
        queueId    = [string]$Scan.QueueId
        startedUtc = [string]$Scan.StartedUtc
    }
}
