function Get-CIPPBaselineEnableMailboxAuditingState {
    <#
    .SYNOPSIS
        Prepare hook for EnableMailboxAuditing: joins the tenant-level audit flag with the
        mailboxes that keep their own AuditEnabled flag and the accounts with audit bypass on.
    .DESCRIPTION
        Mailbox auditing on by default covers user, shared and group mailboxes only. Room,
        equipment, discovery and Bookings mailboxes need AuditEnabled set per mailbox, and
        Secure Score grades that flag. Public folder mailboxes are not in the mailbox cache.
        An account with audit bypass enabled is not audited whatever the other settings say.

        Both lists are only graded when auditing is enforced: an operator who keeps tenant
        auditing off has not asked for mailboxes to be switched on.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($Item, $TenantFilter)

    $OrgConfig = @(@(New-CIPPDbRequest -TenantFilter $TenantFilter -Type 'ExoOrganizationConfig').Where({ $_ }))[0]
    if ($null -eq $OrgConfig) { return @{ Current = $null; NoDataReason = 'the Exchange organization settings could not be read for this tenant' } }

    $ExpectedDisabled = "$($Item.Variables.auditDisabled)" -in @('True', '1')
    $Expected = [PSCustomObject]@{ AuditDisabled = $ExpectedDisabled }
    $Current = [PSCustomObject]@{ AuditDisabled = "$($OrgConfig.AuditDisabled)" -eq 'True' }

    if (-not $ExpectedDisabled) {
        $Types = @('RoomMailbox', 'EquipmentMailbox', 'DiscoveryMailbox', 'SchedulingMailbox')
        $Mailboxes = @(Get-CIPPBaselineCacheRows -TenantFilter $TenantFilter -Type 'Mailboxes' -CollectorArgs @{ Types = 'None' } -Fields 'UPN', 'recipientTypeDetails', 'AuditEnabled')
        if ($Mailboxes.Count -eq 0) { return @{ Current = $null; NoDataReason = 'the mailbox list could not be read for this tenant, so per-mailbox auditing cannot be checked' } }
        $Unaudited = @($Mailboxes.Where({ $_.UPN -and $_.recipientTypeDetails -in $Types -and "$($_.AuditEnabled)" -eq 'False' }).UPN | Sort-Object)

        # Empty is the normal answer here, so only a list that was never collected is No Data
        $Bypassed = @(@(Get-CIPPBaselineCacheRows -TenantFilter $TenantFilter -Type 'ExoMailboxAuditBypass' -Fields 'Name', 'Guid').Where({ $_ }))
        if ($Bypassed.Count -eq 0 -and -not (Test-CIPPBaselineCacheCollected -TenantFilter $TenantFilter -Type 'ExoMailboxAuditBypass')) {
            return @{ Current = $null; NoDataReason = 'the audit bypass list could not be read for this tenant' }
        }

        $Expected.PSObject.Properties.Add([psnoteproperty]::new('MailboxesWithoutAuditing', @()))
        $Expected.PSObject.Properties.Add([psnoteproperty]::new('AccountsWithAuditBypass', @()))
        $Current.PSObject.Properties.Add([psnoteproperty]::new('MailboxesWithoutAuditing', $Unaudited))
        $Current.PSObject.Properties.Add([psnoteproperty]::new('AccountsWithAuditBypass', @($Bypassed.ForEach({ "$($_.Name ?? $_.Guid)" }) | Sort-Object)))
        # Not graded: the executor writes by Guid, since a bypass association name is not unique
        $Current.PSObject.Properties.Add([psnoteproperty]::new('bypassTargets', @($Bypassed.Where({ $_.Guid }).ForEach({ [PSCustomObject]@{ id = "$($_.Guid)"; name = "$($_.Name ?? $_.Guid)" } }))))
    }

    @{ Expected = $Expected; Current = $Current }
}
