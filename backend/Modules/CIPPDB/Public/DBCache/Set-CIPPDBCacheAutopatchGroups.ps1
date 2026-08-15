function Set-CIPPDBCacheAutopatchGroups {
    <#
    .SYNOPSIS
        Caches Windows Autopatch groups for a tenant

    .DESCRIPTION
        Caches the Autopatch group list (name, id and deploymentGroups settings) from the
        Microsoft Autopatch API proxy used by the AutopatchGroup standard. The proxy exists
        until native Graph API support for Autopatch groups is available.

    .PARAMETER TenantFilter
        The tenant to cache Autopatch groups for

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
        $TestResult = Test-CIPPStandardLicense -StandardName 'AutopatchGroupsCache' -TenantFilter $TenantFilter -Preset Intune -SkipLog
        if ($TestResult -eq $false) {
            Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message 'Tenant does not have Intune license, skipping Autopatch groups cache' -sev Debug
            return
        }

        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message 'Caching Autopatch groups' -sev Debug

        # Same URI and auth as the AutopatchGroup standard: the Microsoft-provided Autopatch API
        # proxy accepts the app-only Graph token issued by New-GraphGetRequest.
        $AutopatchProxyBase = 'https://intuneautopatchbeta-bwhtaqgefgcyaaa8.westeurope-01.azurewebsites.net/api/autoPatch'
        $AutopatchGroups = New-GraphGetRequest -uri $AutopatchProxyBase -tenantid $TenantFilter -AsApp $true
        if (-not $AutopatchGroups) { $AutopatchGroups = @() }

        Add-CIPPDbItem -TenantFilter $TenantFilter -Type 'AutopatchGroups' -Data @($AutopatchGroups) -AddCount

        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message "Cached $(($AutopatchGroups | Measure-Object).Count) Autopatch groups" -sev Debug
    } catch {
        Write-LogMessage -API 'CIPPDBCache' -tenant $TenantFilter -message "Failed to cache Autopatch groups: $($_.Exception.Message)" -sev Error
    }
}
