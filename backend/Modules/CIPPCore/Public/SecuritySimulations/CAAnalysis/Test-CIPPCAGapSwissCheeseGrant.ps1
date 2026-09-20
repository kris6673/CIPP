function Test-CIPPCAGapSwissCheeseGrant {
    <#
    .SYNOPSIS
        Reviews policies whose grant controls are combined with the OR operator.
    .DESCRIPTION
        With OR, only the weakest listed control has to be satisfied. An OR between controls of equivalent strength
        (compliant device OR hybrid-joined device; approved app OR app protection; or the MDM-or-MAM mix of both
        groups) is Microsoft's accepted pattern and produces an Info finding. Any OR that spans controls of different
        strength (for example MFA OR compliant device) produces a High finding. Disabled and report-only policies are
        evaluated too so admins can see the impact before turning a policy on.
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
    $Labels = $Context.Data.Reference.grantControlLabels

    foreach ($Policy in @($Context.Policies)) {
        $Grant = $Policy.grantControls
        if (-not $Grant.present -or $Grant.operator -ne 'OR') { continue }

        $Controls = @($Grant.builtInControls | Where-Object { $_ -ne 'block' })
        if ($Controls.Count -le 1) { continue }

        $DistinctGroups = @($Controls | ForEach-Object {
                $ControlName = $_
                $Group = $Groups.$ControlName
                if ($Group) { "$Group" } else { "unique:$ControlName" }
            } | Select-Object -Unique)
        $SoleGroup = if ($DistinctGroups.Count -eq 1) { $DistinctGroups[0] } else { $null }
        $IsManagedAccessOnly = @($DistinctGroups | Where-Object { $_ -ne 'device-trust' -and $_ -ne 'app-protection' }).Count -eq 0
        $IsAcceptedEquivalentOr = ($null -ne $SoleGroup) -or $IsManagedAccessOnly

        $LabelList = @($Controls | ForEach-Object {
                $ControlName = $_
                $Label = $Labels.$ControlName
                if ($Label) { "$Label" } else { $ControlName }
            })
        $Joined = $LabelList -join ' OR '

        if ($IsAcceptedEquivalentOr) {
            $SpansBothGroups = ($null -eq $SoleGroup) -and $IsManagedAccessOnly
            $Explanation = if ($SpansBothGroups) {
                'Requiring a compliant/hybrid-joined device OR an approved app/app protection policy is Microsoft''s recommended MDM-or-MAM pattern for mobile and BYOD scenarios: a managed device satisfies compliance, and an unmanaged BYOD device satisfies app protection instead. Both paths enforce management-based control of equivalent strength - neither is a weaker fallback for the other.'
            } elseif ($SoleGroup -eq 'device-trust') {
                'Requiring a compliant device OR a Microsoft Entra hybrid joined device is a Microsoft-recommended way to require a managed, trusted device while supporting both Intune-managed and hybrid-joined estates. Both controls enforce device trust - neither is weaker than the other.'
            } else {
                'Requiring an approved client app OR an app protection policy is Microsoft''s recommended mobile application management (MAM) pattern. Both controls enforce app-level protection of equivalent strength.'
            }
            $Params = @{
                Severity         = 'Info'
                Category         = 'Swiss Cheese Model'
                Title            = 'Grant controls use "OR" between equivalent-strength controls - accepted pattern'
                Description      = "This policy requires $Joined. Although it uses the OR operator, all controls are management-based controls of equivalent strength, so there is no ""weakest control"" for an attacker to downgrade to. $Explanation"
                Remediation      = 'No change required - this OR is between controls of equivalent strength and does not weaken the policy. ' +
                'If you intend these device/app controls to be layered on top of MFA, add MFA as a separate policy or as an AND condition; do not rely on this policy alone for the MFA layer.'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
            continue
        }

        $Params = @{
            Severity         = 'High'
            Category         = 'Swiss Cheese Model'
            Title            = 'Grant controls use "OR" - weakest control is effective'
            Description      = "This policy requires $Joined. With the OR operator across controls of differing strength, only the WEAKEST control needs to be satisfied - an attacker satisfies the easiest one and skips the rest. This contradicts the Swiss cheese model of layered security."
            Remediation      = 'Change the operator to "AND" so ALL controls must be satisfied, or split into separate policies each requiring a single control. Use AND, not OR, for grant controls of differing strength.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
