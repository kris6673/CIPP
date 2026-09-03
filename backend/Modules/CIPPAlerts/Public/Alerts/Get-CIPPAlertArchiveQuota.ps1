function Get-CIPPAlertArchiveQuota {
    <#
    .FUNCTIONALITY
        Entrypoint
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Alias('input')]
        $InputValue,
        [Parameter(Mandatory)]
        $TenantFilter
    )

    $Threshold = if ($InputValue.ArchiveQuotaThreshold) { [int]$InputValue.ArchiveQuotaThreshold } else { 90 }
    $ExcludedRaw = Get-CIPPTextReplacement -TenantFilter $TenantFilter -Text ([string]$InputValue.ArchiveQuotaExcludedMailboxes)
    $Excluded = @($ExcludedRaw -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })

    try {
        # -Archive limits the result to mailboxes that actually have an online archive, and the quota
        # fields ride along in the same call so only the per-mailbox usage needs a second lookup.
        $ArchiveMailboxes = @(New-ExoRequest -tenantid $TenantFilter -cmdlet 'Get-Mailbox' -cmdParams @{ Archive = $true } -Select 'UserPrincipalName,RecipientTypeDetails,ArchiveQuota,ArchiveWarningQuota,ArchiveGuid' -useSystemMailbox $true)
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -API 'Alerts' -tenant $TenantFilter -message "Archive quota Alert: Unable to get archive mailboxes: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
        return
    }

    $ArchiveMailboxes = @($ArchiveMailboxes | Where-Object {
            $_.UserPrincipalName -and ($Excluded -notcontains $_.UserPrincipalName.ToLower())
        })
    if ($ArchiveMailboxes.Count -eq 0) { return }

    # Archive size only comes from Get-MailboxStatistics. Batch it with an operation guid per mailbox
    # so each result maps back to its mailbox, the same pattern the reporting-DB cache uses.
    $MailboxByRequestId = @{}
    $StatsRequests = @(foreach ($Mailbox in $ArchiveMailboxes) {
            $OperationGuid = [Guid]::NewGuid().ToString()
            $MailboxByRequestId[$OperationGuid] = $Mailbox
            @{
                CmdletInput   = @{
                    CmdletName = 'Get-MailboxStatistics'
                    Parameters = @{ Identity = $Mailbox.UserPrincipalName; Archive = $true }
                }
                OperationGuid = $OperationGuid
            }
        })

    try {
        $StatsResults = New-ExoBulkRequest -tenantid $TenantFilter -cmdletArray $StatsRequests -useSystemMailbox $true
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -API 'Alerts' -tenant $TenantFilter -message "Archive quota Alert: Unable to get archive statistics: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
        return
    }

    $OverQuota = foreach ($Stat in @($StatsResults)) {
        if (-not $Stat.OperationGuid -or -not $MailboxByRequestId.ContainsKey($Stat.OperationGuid) -or $Stat.error) { continue }
        $Mailbox = $MailboxByRequestId[$Stat.OperationGuid]
        # ArchiveQuota reads 'Unlimited' when no quota applies; Get-ExoOnlineStringBytes then returns
        # 0 and the mailbox is skipped rather than dividing by zero.
        $QuotaBytes = Get-ExoOnlineStringBytes -SizeString ([string]$Mailbox.ArchiveQuota)
        if ($QuotaBytes -le 0) { continue }
        $UsedBytes = Get-ExoOnlineStringBytes -SizeString ([string]$Stat.TotalItemSize)
        $UsagePercent = [math]::Round(($UsedBytes / $QuotaBytes) * 100)
        if ($UsagePercent -ge $Threshold) {
            [PSCustomObject]@{
                Message           = "$($Mailbox.UserPrincipalName): Online archive is more than $($Threshold)% full. Archive is $UsagePercent% full"
                Owner             = $Mailbox.UserPrincipalName
                RecipientType     = $Mailbox.RecipientTypeDetails
                UsagePercent      = $UsagePercent
                ArchiveUsedBytes  = $UsedBytes
                ArchiveQuotaBytes = $QuotaBytes
                Tenant            = $TenantFilter
            }
        }
    }

    if ($OverQuota) {
        Write-AlertTrace -cmdletName $MyInvocation.MyCommand -tenantFilter $TenantFilter -data $OverQuota
    }
}
