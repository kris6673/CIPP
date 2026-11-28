function Invoke-CIPPBaselineEnableMailboxAuditing {
    <#
    .SYNOPSIS
        Executor for EnableMailboxAuditing: sets the tenant-level audit flag, turns auditing on
        for the mailboxes the prepare hook found with it off and clears audit bypass.
    .DESCRIPTION
        Mailbox audit settings must be written on the mailbox's own server, so each of those
        writes is anchored to its mailbox (see Invoke-CIPPBaselineMailboxDefaultAuditSet).

        The caches are not refreshed here: Exchange takes a while to return the new value, so a
        refresh straight after the write caches the old one. The definition's
        read.freshnessType keeps the row pending until the next mailbox collection.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($Remediate, $TenantFilter, $Current)

    $Disabled = [bool]($Remediate.auditDisabled -eq $true)
    $FlagDiffers = [bool]$Current.AuditDisabled -ne $Disabled
    if ($FlagDiffers) {
        $null = New-ExoRequest -tenantid $TenantFilter -cmdlet 'Set-OrganizationConfig' -cmdParams @{ AuditDisabled = $Disabled } -useSystemMailbox $true
    }

    $Mailboxes = if ($Disabled) { @() } else { @(@($Current.MailboxesWithoutAuditing).Where({ $_ })) }
    $Bypassed = if ($Disabled) { @() } else { @(@($Current.bypassTargets).Where({ $_.id })) }
    $Total = $Mailboxes.Count + $Bypassed.Count
    if ($Total -eq 0) {
        if (-not $FlagDiffers) { return [PSCustomObject]@{ Changed = $false } }
        return
    }

    # A write counts only when Exchange answered for it without an error
    $Answers = @{}
    if ($Mailboxes.Count -gt 0) {
        $Requests = foreach ($UPN in $Mailboxes) {
            @{ CmdletInput = @{ CmdletName = 'Set-Mailbox'; Parameters = @{ Identity = $UPN; AuditEnabled = $true } }; OperationGuid = $UPN }
        }
        try {
            foreach ($Answer in @(New-ExoBulkRequest -tenantid $TenantFilter -cmdletArray @($Requests) -AnchorPerMailbox -MaxConcurrency 10)) {
                if ($Answer.OperationGuid) { $Answers["$($Answer.OperationGuid)"] = "$($Answer.error)" }
            }
        } catch {
            foreach ($UPN in $Mailboxes) { $Answers[$UPN] = "$($_.Exception.Message)" }
        }
    }
    if ($Bypassed.Count -gt 0) {
        $Requests = foreach ($Account in $Bypassed) {
            @{ CmdletInput = @{ CmdletName = 'Set-MailboxAuditBypassAssociation'; Parameters = @{ Identity = $Account.id; AuditBypassEnabled = $false } }; OperationGuid = $Account.id }
        }
        try {
            foreach ($Answer in @(New-ExoBulkRequest -tenantid $TenantFilter -cmdletArray @($Requests))) {
                if ($Answer.OperationGuid) { $Answers["$($Answer.OperationGuid)"] = "$($Answer.error)" }
            }
        } catch {
            foreach ($Account in $Bypassed) { $Answers[$Account.id] = "$($_.Exception.Message)" }
        }
    }

    $Failures = @(
        foreach ($UPN in $Mailboxes) {
            if (-not $Answers.ContainsKey($UPN)) { "$UPN -> no response from Exchange" } elseif ($Answers[$UPN]) { "$UPN -> $($Answers[$UPN])" }
        }
        foreach ($Account in $Bypassed) {
            if (-not $Answers.ContainsKey($Account.id)) { "$($Account.name) (audit bypass) -> no response from Exchange" } elseif ($Answers[$Account.id]) { "$($Account.name) (audit bypass) -> $($Answers[$Account.id])" }
        }
    )

    if ($Failures.Count -gt 0) {
        Write-LogMessage -API 'Baselines' -tenant $TenantFilter -message "EnableMailboxAuditing: $($Failures.Count) of $Total mailbox writes failed. $(($Failures | Select-Object -First 10) -join ' | ')" -Sev 'Warning'
    }
    if ($Failures.Count -ge $Total -and -not $FlagDiffers) {
        throw "EnableMailboxAuditing: all $Total writes failed. $($Failures[0])"
    }
}
