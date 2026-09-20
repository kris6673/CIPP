function Test-CIPPCAGapResilienceDefaults {
    <#
    .SYNOPSIS
        Flags enabled or report-only policies that disable resilience defaults.
    .DESCRIPTION
        Disabling resilience defaults means users are denied access when their session expires during an Entra ID
        outage. Every non-disabled policy with sessionControls.disableResilienceDefaults = true gets a Medium finding.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()

    foreach ($Policy in @($Context.Policies)) {
        if ($null -eq $Policy.sessionControls -or $Policy.state -eq 'disabled') { continue }
        if ($Policy.sessionControls.disableResilienceDefaults -ne $true) { continue }

        $Params = @{
            Severity         = 'Medium'
            Category         = 'Resilience'
            Title            = 'Resilience defaults are disabled'
            Description      = 'This policy disables resilience defaults, which means users may be blocked during an Entra ID outage.'
            Remediation      = 'Only disable resilience defaults if strict real-time policy evaluation is required. For most organizations, keeping resilience defaults improves availability.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
