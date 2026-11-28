function Set-CIPPDBCacheExoMailboxAuditBypass {
    <#
    .SYNOPSIS
        Caches the accounts with mailbox audit bypass enabled for a tenant

    .DESCRIPTION
        Actions performed by an account with audit bypass enabled are not written to any mailbox
        audit log. The flag lives on the bypass association, not on the mailbox, and almost
        every association has it off, so only the enabled ones are cached: that set is what the
        EnableMailboxAuditing baseline and the CIS 6.1.3 test grade.

    .PARAMETER TenantFilter
        The tenant to cache audit bypass associations for

    .PARAMETER QueueId
        The queue ID to update with total tasks (optional)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [string]$QueueId
    )

    try {
        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message 'Caching mailbox audit bypass associations' -sev Debug
        $Bypassed = @(New-ExoRequest -tenantid $TenantFilter -cmdlet 'Get-MailboxAuditBypassAssociation' -cmdParams @{ ResultSize = 'Unlimited' } -Select 'Name,Guid,AuditBypassEnabled' -useSystemMailbox $true -StreamPages |
            & { process { foreach ($Association in $_.Value) { if ($Association.AuditBypassEnabled -eq $true) { $Association } } } })
        Add-CIPPDbItem -TenantFilter $TenantFilter -Type 'ExoMailboxAuditBypass' -Data $Bypassed -AddCount -ClearOnEmpty

        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message 'Cached mailbox audit bypass associations successfully' -sev Debug
    } catch {
        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message "Failed to cache mailbox audit bypass associations: $($_.Exception.Message)" -sev Error
    }
}
