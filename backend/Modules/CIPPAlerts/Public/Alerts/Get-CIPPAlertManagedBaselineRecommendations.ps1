function Get-CIPPAlertManagedBaselineRecommendations {
    <#
    .FUNCTIONALITY
        Entrypoint
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Alias('input')]
        $InputValue,
        $TenantFilter
    )

    try {
        $Tenant = @(Get-Tenants -TenantFilter $TenantFilter -SkipDomains)[0]
        if (-not $Tenant.customerId) { throw "$TenantFilter is not a tenant in this CIPP." }

        $Table = Get-CIPPTable -TableName 'BaselineRecommendations'
        $Rows = @(Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq '$($Tenant.customerId)'" -Property PartitionKey, RowKey, Status, Title, Standard, Impact, Reason, FinishedAt)

        # A tenant that was never scanned has nothing to report, and nothing to clear either.
        $Scan = $Rows.Where({ $_.RowKey -eq 'scan' }, 'First')[0]
        if (-not $Scan -or [int64]($Scan.FinishedAt ?? 0) -le 0) { return }

        $AlertData = foreach ($Row in $Rows) {
            if ("$($Row.Status)" -ne 'Recommended') { continue }
            $Name = "$($Row.Title)" ? "$($Row.Title)" : "$($Row.Standard)"
            [PSCustomObject]@{
                Id             = $Row.RowKey
                Recommendation = $Name
                Standard       = $Row.Standard
                Impact         = $Row.Impact
                Reason         = $Row.Reason
                Message        = 'New managed baseline recommendation: {0}' -f $Name
                Tenant         = $TenantFilter
            }
        }
        Write-AlertTrace -cmdletName $MyInvocation.MyCommand -tenantFilter $TenantFilter -data $AlertData
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -API 'Alerts' -tenant $TenantFilter -message "Failed to check managed baseline recommendations for $($TenantFilter): $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
    }
}
