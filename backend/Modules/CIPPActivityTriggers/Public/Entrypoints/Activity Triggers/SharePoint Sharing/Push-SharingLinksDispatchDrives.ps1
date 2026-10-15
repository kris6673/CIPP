function Push-SharingLinksDispatchDrives {
    <#
    .SYNOPSIS
        Post-execution for a tenant's sharing-links site run and each drive run: queues the scan's unfinished drives

    .DESCRIPTION
        Every drive of the scan without a completion marker is queued as one run of at most three at
        a time, whose post-execution is this function again. A drive task killed at the platform limit
        or throttled out mid-scan resumes from its checkpoint in the next round. After 20 drive rounds
        the drives still unfinished give up and keep their existing rows.

        A tenant's drive tasks share one SharePoint throttle budget; three keep the lowest licence band
        busy without throttling and leave background slots for other work.

    .FUNCTIONALITY
        Entrypoint
    #>
    param($Item)

    $Parameters = $Item.Parameters
    $TenantFilter = [string]$Parameters.TenantFilter
    $ScanId = [string]$Parameters.ScanId
    $Round = [int]$Parameters.Round
    $MaxRounds = 20
    try {
        $StateTable = Get-CippTable -tablename 'CippSharingLinksState'
        $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter -Type String
        $Scan = Get-CIPPAzDataTableEntity @StateTable -Filter "PartitionKey eq '$SafeTenant' and RowKey eq 'scan'"
        if ([string]$Scan.ScanId -ne $ScanId) { return }

        $Done = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($Row in @(Get-CIPPAzDataTableEntity @StateTable -Filter "PartitionKey eq '$SafeTenant' and RowKey ge 'ddone-' and RowKey lt 'ddone-~'" -Property @('PartitionKey', 'RowKey', 'ScanId'))) {
            if ([string]$Row.ScanId -eq $ScanId) { [void]$Done.Add([string]$Row.RowKey) }
        }

        $Drives = foreach ($Site in @(Get-CIPPAzDataTableEntity @StateTable -Filter "PartitionKey eq '$SafeTenant' and RowKey ge 'drives-' and RowKey lt 'drives-~'")) {
            if ([string]$Site.ScanId -ne $ScanId -or -not $Site.DrivesJson) { continue }
            $SiteKey = ([string]$Site.RowKey).Substring('drives-'.Length)
            foreach ($Drive in @(ConvertFrom-Json -InputObject ([string]$Site.DrivesJson))) {
                if ($Done.Contains("ddone-$SiteKey~$([string]$Drive.id -replace '[/\\#?]', '_' -replace '[\u0000-\u001F\u007F-\u009F]', '')")) { continue }
                [PSCustomObject]@{
                    FunctionName    = 'DBCacheSharePointSiteSharingLinks'
                    TenantFilter    = $TenantFilter
                    SiteId          = [string]$Site.SiteId
                    SiteName        = [string]$Site.SiteName
                    SiteUrl         = [string]$Site.SiteUrl
                    IsPersonalSite  = [bool]$Site.IsPersonalSite
                    InternalDomains = @($Parameters.InternalDomains)
                    ScanId          = $ScanId
                    DriveId         = [string]$Drive.id
                    DriveName       = [string]$Drive.name
                    ReadRoot        = $Drive.readRoot -ne $false
                    ForceFull       = [bool]$Parameters.ForceFull
                    QueueId         = $Parameters.QueueId
                    QueueName       = "Sharing Links - $($Drive.name) - $($Site.SiteUrl)"
                    GiveUp          = $Round -ge $MaxRounds
                }
            }
        }
        $Drives = @($Drives)
        if ($Drives.Count -eq 0) { return }

        if ($Round -ge $MaxRounds) {
            foreach ($Drive in $Drives) { $null = Push-DBCacheSharePointSiteSharingLinks -Item $Drive }
            return
        }
        if ($Round -gt 0) {
            Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message "Sharing links: $($Drives.Count) drives unfinished after round $Round; queuing round $($Round + 1) of $MaxRounds" -sev Info
        }
        $NextParameters = @{
            TenantFilter    = $TenantFilter
            ScanId          = $ScanId
            InternalDomains = @($Parameters.InternalDomains)
            ForceFull       = [bool]$Parameters.ForceFull
            QueueId         = $Parameters.QueueId
            Round           = $Round + 1
        }
        $null = Start-CIPPOrchestrator -InputObject ([PSCustomObject]@{
                Batch            = $Drives
                OrchestratorName = "SharingLinksDrives_$($TenantFilter)_r$($Round + 1)"
                MaxConcurrency   = 3
                SkipLog          = $true
                PostExecution    = @{
                    FunctionName = 'SharingLinksDispatchDrives'
                    Parameters   = $NextParameters
                }
            })
    } catch {
        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message "Sharing links: failed queuing drive scans (round $($Round + 1)): $($_.Exception.Message)" -sev Error -LogData (Get-CippException -Exception $_)
    }
}
