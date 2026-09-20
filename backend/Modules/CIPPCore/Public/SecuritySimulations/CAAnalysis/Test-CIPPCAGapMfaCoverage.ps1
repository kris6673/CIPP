function Test-CIPPCAGapMfaCoverage {
    <#
    .SYNOPSIS
        Tenant-wide check that some enabled policy requires MFA for All users.
    .DESCRIPTION
        A policy covers MFA for all users when it includes "All" users and requires MFA or an authentication strength.
        When no enabled policy does so: Medium if a report-only policy already does (the rule exists but is not
        enforced), otherwise Critical with the all-users MFA template as the fix.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()

    $IsMfaForAll = {
        param($P)
        (@($P.conditions.users.includeUsers) -contains 'All') -and ((@($P.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $P.grantControls.authenticationStrength))
    }

    $HasMfaForAll = @($Context.Enabled | Where-Object { & $IsMfaForAll $_ }).Count -gt 0
    if ($HasMfaForAll) { return @($Findings) }

    $ReportOnlyMfaForAll = @($Context.ReportOnly | Where-Object { & $IsMfaForAll $_ } | Select-Object -First 1)
    if ($ReportOnlyMfaForAll.Count -gt 0) {
        $Policy = $ReportOnlyMfaForAll[0]
        $Params = @{
            Severity         = 'Medium'
            Category         = 'MFA Coverage'
            Title            = 'MFA for All Users exists but is Report-only'
            Description      = "The policy $($Policy.displayName) requires MFA for All Users, but is currently in Report-only mode and is not enforced. Sign-ins are logged but not blocked, so users can still authenticate without MFA."
            Remediation      = 'After observing report-only telemetry for 7-14 days with no unexpected blocks, switch this policy to On (enabled) so MFA is actually enforced. Confirm break-glass accounts are excluded before flipping the state.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    } else {
        $Params = @{
            Severity    = 'Critical'
            Category    = 'MFA Coverage'
            Title       = 'No policy requires MFA for All Users'
            Description = 'No enabled or report-only policy was found that requires MFA (or authentication strength) for All Users. This means there may be users who can authenticate without MFA.'
            Remediation = 'Create a baseline policy requiring MFA for All Users and All Cloud Apps. This is the foundation of the Swiss cheese model - MFA is the bare minimum.'
            CaTemplate  = "$($Context.Data.Reference.templates.mfaAllUsers)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
