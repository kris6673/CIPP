function Invoke-ListSecuritySimulations {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.SecuritySimulations.Read
    .DESCRIPTION
        Lists the security scenarios that can be simulated with the outcome and time of each scenario's
        last stored run for the tenant. With scenarioId it returns that scenario's last stored run in full
        (cached true/false plus the result), so the run view can show it without evaluating again.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    try {
        $TenantFilter = $Request.Query.tenantFilter
        $ScenarioId = $Request.Query.scenarioId
        if ($ScenarioId) {
            if (-not $TenantFilter -or $TenantFilter -in @('AllTenants', 'allTenants')) { throw 'Select a single tenant to read a stored run.' }
            $Run = Get-CIPPSecuritySimulationRun -TenantFilter $TenantFilter -ScenarioId $ScenarioId
            $Results = [PSCustomObject]@{
                cached = $null -ne $Run
                result = $Run
            }
        } else {
            $Results = @(Get-CIPPSecuritySimulationCatalog -TenantFilter $TenantFilter)
        }
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
