function Invoke-ListCASituations {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.SecuritySimulations.Read
    .DESCRIPTION
        Evaluates every predefined sign-in situation (admin, user and guest personas under
        unmanaged devices, foreign locations, legacy clients, device-code flow, risk levels and
        more) live against the tenant's Conditional Access through the What If API, and names the
        control missing wherever a sign-in gets through. Read-only: no sign-in occurs and nothing
        changes in the tenant. Pass ?tenantFilter=.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    try {
        $TenantFilter = $Request.Query.tenantFilter
        if (-not $TenantFilter -or $TenantFilter -in @('AllTenants', 'allTenants')) { throw 'Select a single tenant to evaluate the sign-in situations.' }

        $Licensed = Test-CIPPStandardLicense -StandardName 'ConditionalAccessCache' -TenantFilter $TenantFilter -Preset Entra -SkipLog
        $Battery = $null
        if ($Licensed -ne $false) {
            $Battery = Invoke-CIPPCASituationBattery -TenantFilter $TenantFilter
        }

        $Results = [PSCustomObject]@{
            tenantFilter = $TenantFilter
            licensed     = $Licensed -ne $false
            identities   = $Battery.identities
            situations   = @($Battery.situations)
            summary      = $Battery.summary
        }
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        Write-LogMessage -headers $Request.Headers -API $APIName -message "Failed to evaluate the sign-in situations: $($_.Exception.Message)" -Sev 'Error'
        $Results = @{ Results = "Failed to evaluate the sign-in situations: $($_.Exception.Message)" }
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    return ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Results
        })
}
