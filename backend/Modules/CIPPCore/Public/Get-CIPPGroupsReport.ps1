function Get-CIPPGroupsReport {
    <#
    .SYNOPSIS
        Generates a groups report from the CIPP Reporting database

    .PARAMETER TenantFilter
        The tenant to generate the report for, or 'AllTenants' for all tenants

    .PARAMETER PageSize
        When set, returns one page of at most this many rows as @{ Items; NextToken }, in table walk order.

    .PARAMETER ContinuationToken
        NextToken from the previous page. Only meaningful together with PageSize.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [int]$PageSize,
        [string]$ContinuationToken
    )

    if ($PageSize -gt 0) {
        $Page = Get-CIPPDbItemPage -TenantFilter $TenantFilter -Type 'Groups' -PageSize $PageSize -ContinuationToken $ContinuationToken
        if ($TenantFilter -ne 'AllTenants' -and -not $ContinuationToken -and @($Page.Items).Count -eq 0 -and -not $Page.NextToken) {
            throw "No groups data found in reporting database for $TenantFilter. Sync the report data first."
        }
        $Results = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($Item in $Page.Items) {
            try {
                $Group = $Item.Data | ConvertFrom-Json -Depth 10 -ErrorAction Stop
                if ($Group.members -and -not $Group.membersCsv) {
                    $Group | Add-Member -NotePropertyName 'membersCsv' -NotePropertyValue ($Group.members.userPrincipalName -join ',') -Force
                }
                if ($Group.owners -and -not $Group.ownersCsv) {
                    $Group | Add-Member -NotePropertyName 'ownersCsv' -NotePropertyValue ($Group.owners.userPrincipalName -join ',') -Force
                }
                # Per-item timestamp: a page may span tenants.
                $Group | Add-Member -NotePropertyName 'CacheTimestamp' -NotePropertyValue $Item.Timestamp -Force
                if ($TenantFilter -eq 'AllTenants') {
                    $Group | Add-Member -NotePropertyName 'Tenant' -NotePropertyValue $Item.PartitionKey -Force
                }
                $Results.Add($Group)
            } catch {
                Write-LogMessage -API 'GroupsReport' -tenant $Item.PartitionKey -message "Failed to parse group item: $($_.Exception.Message)" -sev Warning
            }
        }
        return [PSCustomObject]@{
            Items     = $Results
            NextToken = $Page.NextToken
        }
    }

    if ($TenantFilter -eq 'AllTenants') {
        $AnyItems = Get-CIPPDbItem -TenantFilter 'allTenants' -Type 'Groups'
        $Tenants = @($AnyItems | Where-Object { $_.RowKey -notlike '*-Count' } | Select-Object -ExpandProperty PartitionKey -Unique)
        $TenantList = Get-Tenants -IncludeErrors
        $Tenants = $Tenants | Where-Object { $TenantList.defaultDomainName -contains $_ }

        $AllResults = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($Tenant in $Tenants) {
            try {
                $TenantResults = Get-CIPPGroupsReport -TenantFilter $Tenant
                foreach ($Result in $TenantResults) {
                    $Result | Add-Member -NotePropertyName 'Tenant' -NotePropertyValue $Tenant -Force
                    $AllResults.Add($Result)
                }
            } catch {
                Write-LogMessage -API 'GroupsReport' -tenant $Tenant -message "Failed to get groups report: $($_.Exception.Message)" -sev Warning
            }
        }
        return $AllResults
    }

    $Items = Get-CIPPDbItem -TenantFilter $TenantFilter -Type 'Groups' | Where-Object { $_.RowKey -notlike '*-Count' }
    if (-not $Items) {
        throw "No groups data found in reporting database for $TenantFilter. Sync the report data first."
    }

    $CacheTimestamp = ($Items | Where-Object { $_.Timestamp } | Sort-Object Timestamp -Descending | Select-Object -First 1).Timestamp

    $Results = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($Item in $Items) {
        try {
            $Group = $Item.Data | ConvertFrom-Json -Depth 10 -ErrorAction Stop
            if ($Group.members -and -not $Group.membersCsv) {
                $Group | Add-Member -NotePropertyName 'membersCsv' -NotePropertyValue ($Group.members.userPrincipalName -join ',') -Force
            }
            if ($Group.owners -and -not $Group.ownersCsv) {
                $Group | Add-Member -NotePropertyName 'ownersCsv' -NotePropertyValue ($Group.owners.userPrincipalName -join ',') -Force
            }
            $Group | Add-Member -NotePropertyName 'CacheTimestamp' -NotePropertyValue $CacheTimestamp -Force
            $Results.Add($Group)
        } catch {
            Write-LogMessage -API 'GroupsReport' -tenant $TenantFilter -message "Failed to parse group item: $($_.Exception.Message)" -sev Warning
        }
    }

    return ($Results | Sort-Object displayName)
}
