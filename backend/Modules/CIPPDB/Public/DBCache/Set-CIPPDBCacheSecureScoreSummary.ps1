function Set-CIPPDBCacheSecureScoreSummary {
    <#
    .SYNOPSIS
        Caches the secure score summary for a tenant

    .DESCRIPTION
        The summary is derived from the score history and control profiles inside
        Set-CIPPDBCacheSecureScore. This collector runs it so the engine's on-miss
        Set-CIPPDBCache<Type> lookup resolves for 'SecureScoreSummary'.

    .PARAMETER TenantFilter
        The tenant to cache the secure score summary for

    .PARAMETER QueueId
        The queue ID to update with total tasks (optional)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter,
        [string]$QueueId
    )

    Set-CIPPDBCacheSecureScore @PSBoundParameters
}
