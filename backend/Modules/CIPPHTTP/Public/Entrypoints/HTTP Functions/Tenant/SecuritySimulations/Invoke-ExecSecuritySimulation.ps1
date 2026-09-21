function Invoke-ExecSecuritySimulation {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.SecuritySimulations.Read
    .DESCRIPTION
        Plays one security scenario against a tenant: grades the standards each step relies on, evaluates
        the scenario's sign-in live through the Conditional Access What If API, and checks whether an
        audit-log alert would fire. The result is stored so the catalog shows it. With scenarioId 'All'
        every scenario is played in one go, sharing the graded standards and resolved identities.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    try {
        $TenantFilter = $Request.Body.tenantFilter.value ?? $Request.Body.tenantFilter
        $ScenarioId = $Request.Body.scenarioId.value ?? $Request.Body.scenarioId
        if (-not $TenantFilter -or $TenantFilter -in @('AllTenants', 'allTenants')) { throw 'Select a single tenant to run a simulation.' }
        if (-not $ScenarioId) { throw 'Provide a scenarioId.' }

        if ("$ScenarioId" -eq 'All') {
            $Shared = @{}
            $Ran = 0
            $Failed = [System.Collections.Generic.List[string]]::new()
            foreach ($Scenario in @(Get-CIPPSecuritySimulationDefinition)) {
                try {
                    $null = Invoke-CIPPSecuritySimulation -TenantFilter $TenantFilter -ScenarioId $Scenario.id -Shared $Shared
                    $Ran++
                } catch {
                    $Failed.Add("$($Scenario.title) ($($_.Exception.Message))")
                }
            }
            $Message = "Checked $Ran scenario$(if ($Ran -eq 1) { '' } else { 's' }) for $TenantFilter."
            if ($Failed.Count -gt 0) { $Message += " $($Failed.Count) could not be checked: $($Failed -join '; ')" }
            Write-LogMessage -headers $Request.Headers -API $APIName -tenant $TenantFilter -message $Message -Sev 'Info'
            $Results = @{ Results = $Message }
        } else {
            $Results = Invoke-CIPPSecuritySimulation -TenantFilter $TenantFilter -ScenarioId $ScenarioId
            Write-LogMessage -headers $Request.Headers -API $APIName -tenant $TenantFilter -message "Ran security simulation '$ScenarioId'." -Sev 'Info'
        }
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        Write-LogMessage -headers $Request.Headers -API $APIName -message "Failed to run security simulation: $($_.Exception.Message)" -Sev 'Error'
        $Results = @{ Results = "Failed to run security simulation: $($_.Exception.Message)" }
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    return ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $Results
        })
}
