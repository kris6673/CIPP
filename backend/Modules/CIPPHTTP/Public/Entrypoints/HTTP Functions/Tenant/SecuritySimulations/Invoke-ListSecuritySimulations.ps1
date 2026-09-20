function Invoke-ListSecuritySimulations {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.SecuritySimulations.Read
    .DESCRIPTION
        Lists the security scenarios that can be simulated, with a per-tenant summary of how many
        of the standards each scenario relies on are already in place (from the tenant's baseline
        alignment - nothing is evaluated here). Pass ?tenantFilter= for the summary.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    try {
        $Results = @(Get-CIPPSecuritySimulationCatalog -TenantFilter $Request.Query.tenantFilter)
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        Write-LogMessage -headers $Request.Headers -API $APIName -message "Failed to list security simulations: $($_.Exception.Message)" -Sev 'Error'
        $Results = @{ Results = "Failed to list security simulations: $($_.Exception.Message)" }
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    return ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Results
        })
}
