function Test-CIPPCAGapMissingMfa {
    <#
    .SYNOPSIS
        Flags grant policies that do not require MFA or an authentication strength.
    .DESCRIPTION
        Skips disabled policies, policies with no grant controls, block policies, workload/agent-identity policies
        (includeUsers = None with no groups or roles) and policies whose controls are all strong device-trust or
        app-protection controls (a legitimate standalone layer). Everything else that grants access without MFA gets a
        Medium finding. Tenant-wide MFA coverage is handled by Test-CIPPCAGapMfaCoverage.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Groups = $Context.Data.Reference.equivalentStrengthGroups

    foreach ($Policy in @($Context.Policies)) {
        if ($Policy.state -eq 'disabled') { continue }
        $Grant = $Policy.grantControls
        $Controls = @($Grant.builtInControls)
        if (-not $Grant.present -or $Controls.Count -eq 0) { continue }
        if ($Controls -contains 'block') { continue }

        $RequiresMfa = ($Controls -contains 'mfa') -or ($null -ne $Grant.authenticationStrength)
        if ($RequiresMfa) { continue }

        $Users = $Policy.conditions.users
        $RealIncludeUsers = @($Users.includeUsers | Where-Object { $_ -ne 'None' })
        $TargetsUsers = ($RealIncludeUsers.Count -gt 0) -or (@($Users.includeGroups).Count -gt 0) -or (@($Users.includeRoles).Count -gt 0)
        if (-not $TargetsUsers) { continue }

        $AllStrongNonMfa = @($Controls | Where-Object {
                $ControlName = $_
                $null -eq $Groups.$ControlName
            }).Count -eq 0
        if ($AllStrongNonMfa) { continue }

        $Params = @{
            Severity         = 'Medium'
            Category         = 'Swiss Cheese Model'
            Title            = 'Policy does not require MFA'
            Description      = "This policy grants access with: $($Controls -join ', ') but does not require MFA. Per the Swiss cheese model, MFA should be the bare minimum requirement layered under everything else."
            Remediation      = 'Add MFA as a grant control requirement. MFA should be the baseline layer of defense. Consider using Authentication Strengths for phishing-resistant MFA.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
