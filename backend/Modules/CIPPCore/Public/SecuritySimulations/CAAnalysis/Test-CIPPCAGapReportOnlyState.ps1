function Test-CIPPCAGapReportOnlyState {
    <#
    .SYNOPSIS
        Lists every policy that is in report-only mode.
    .DESCRIPTION
        A report-only policy logs what would happen but enforces nothing. Each one produces an Info finding so the
        posture report shows which rules exist on paper only. Other checks downgrade or adjust their severity for
        report-only policies themselves; this check is the plain inventory.
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
        if ($Policy.state -ne 'enabledForReportingButNotEnforced') { continue }
        $Params = @{
            Severity         = 'Info'
            Category         = 'Policy State'
            Title            = 'Policy is in report-only mode'
            Description      = 'This policy is enabled for reporting but NOT enforced. It will log what WOULD happen but takes no action.'
            Remediation      = "Review sign-in logs to validate the policy's impact, then enable enforcement when ready."
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
