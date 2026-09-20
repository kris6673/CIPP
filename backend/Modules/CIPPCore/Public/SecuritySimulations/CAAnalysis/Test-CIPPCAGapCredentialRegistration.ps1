function Test-CIPPCAGapCredentialRegistration {
    <#
    .SYNOPSIS
        Reviews policies that target "Register security info" for constraints that block new-device credential setup.
    .DESCRIPTION
        Since July 2026 (MC1326253) policies scoped to the register-security-info user action are evaluated during
        Windows Hello for Business and macOS Platform SSO registration. A non-disabled policy on that user action that
        requires device compliance, approved/protected apps (without an MFA alternative through OR), trusted locations
        or a device filter may block first-time setup: High when compliance is mandatory or locations are restricted,
        otherwise Medium. A policy with only MFA / authentication strength gets an Info finding confirming it is safe.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Reference = $Context.Data.Reference
    $RegisterSecurityInfo = "$($Reference.registerSecurityInfoAction)"
    $LegacyTrustedIps = "$($Reference.legacyMfaTrustedIpsLocation)"

    foreach ($Policy in @($Context.Policies)) {
        if ($Policy.state -eq 'disabled') { continue }
        if (-not (@($Policy.conditions.applications.includeUserActions) -contains $RegisterSecurityInfo)) { continue }

        $Grant = $Policy.grantControls
        $Controls = @($Grant.builtInControls)
        $Conditions = $Policy.conditions
        $Locations = $Conditions.locations

        $RequiresCompliance = ($Controls -contains 'compliantDevice') -or ($Controls -contains 'domainJoinedDevice')
        $RequiresApprovedApp = $Controls -contains 'approvedApplication'
        $RequiresAppProtection = $Controls -contains 'compliantApplication'
        $IncludedLocations = if ($null -ne $Locations) { @($Locations.includeLocations) } else { @() }
        $ExcludedLocations = if ($null -ne $Locations) { @($Locations.excludeLocations) } else { @() }
        $HasLocationConditions = ($IncludedLocations.Count -gt 0) -or ($ExcludedLocations.Count -gt 0)
        $HasDeviceFilter = $null -ne $Conditions.devices.deviceFilter.rule
        $HasMfaAlternative = ($Grant.operator -eq 'OR') -and (($Controls -contains 'mfa') -or ($null -ne $Grant.authenticationStrength))

        $Issues = [System.Collections.Generic.List[string]]::new()
        if ($RequiresCompliance -and -not $HasMfaAlternative) {
            $Issues.Add('Device compliance: Users provisioning WHfB/Platform SSO on a NEW device cannot satisfy this requirement during initial setup (device is not enrolled yet)')
        }
        if (($RequiresApprovedApp -or $RequiresAppProtection) -and -not $HasMfaAlternative) {
            $Issues.Add('Approved/protected app: Users setting up credentials during device provisioning may not have approved apps installed yet')
        }
        if ($HasLocationConditions) {
            if ($IncludedLocations.Count -gt 0 -and -not ($IncludedLocations -contains 'All') -and -not ($IncludedLocations -contains 'AllTrusted')) {
                $LocationNames = @($IncludedLocations | ForEach-Object {
                        if ($_ -eq $LegacyTrustedIps) { 'MFA Trusted IPs (legacy)' }
                        else {
                            $Named = $Context.NamedLocationById["$_"]
                            if ($Named.displayName) { "$($Named.displayName)" } else { "$_" }
                        }
                    }) -join ', '
                $Issues.Add("Trusted location requirement: Policy requires access from: $LocationNames. Users setting up credentials from home/remote locations (common for new device setup) will be blocked")
            }
            if (($ExcludedLocations -contains 'AllTrusted') -and -not ($IncludedLocations -contains 'AllTrusted')) {
                $Issues.Add('Untrusted location block: Policy blocks access from untrusted locations. Users setting up new devices from home/public networks may be blocked')
            }
        }
        if ($HasDeviceFilter) {
            $Issues.Add('Device filter: Device filters may not evaluate correctly on devices during initial provisioning before they are fully enrolled/registered')
        }

        if ($Issues.Count -eq 0) {
            $StateNote = if ($Policy.state -eq 'enabledForReportingButNotEnforced') {
                'This policy is currently in report-only mode - switch it to On if you want it enforced during registration.'
            } else {
                'This policy is enabled, so it applies during registration automatically.'
            }
            $Params = @{
                Severity         = 'Info'
                Category         = 'Credential Registration Constraints'
                Title            = 'Targets "Register security info" - will apply to WHfB / Platform SSO registration (July 2026)'
                Description      = "Since July 2026 (MC1326253) this policy is evaluated during Windows Hello for Business and macOS Platform SSO credential registration - not just sign-in. Good news: this policy requires only MFA / authentication strength with no device-compliance, trusted-location, approved/protected-app, or device-filter constraints - so it should not block users provisioning a new device. This is the recommended configuration for a registration-targeting policy. $StateNote"
                Remediation      = 'No changes required. Confirm the grant control is achievable on a new device (a user enrolling WHfB can satisfy your authentication strength with a FIDO2 key, Authenticator push, or a Temporary Access Pass), keep the policy free of device/location constraints, and update helpdesk docs because users may see a new authentication prompt during device setup. Reference: MC1326253 / https://learn.microsoft.com/entra/identity/conditional-access/policy-all-users-security-info-registration'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
            continue
        }

        $Severity = 'Medium'
        if (($RequiresCompliance -and -not $HasMfaAlternative) -or ($HasLocationConditions -and -not ($IncludedLocations -contains 'All'))) {
            $Severity = 'High'
        }

        $Remediation = if ($RequiresCompliance -and -not $HasMfaAlternative) {
            'High priority: remove device compliance requirements from this policy or add exclusions for users during initial device provisioning. Options: 1) separate policies - one for sign-in (with compliance) and one for registration (MFA + phishing-resistant authentication only); 2) use Temporary Access Pass (TAP) for new device enrollment, excluded from this policy; 3) allow registration from trusted corporate networks only; 4) use report-only mode to see impact without blocking users. Recommended grant controls for registration policies: MFA + authentication strength (phishing-resistant) - avoid device compliance/location requirements.'
        } elseif ($HasLocationConditions) {
            'Review recommended: if users commonly set up new devices from home/remote locations, consider 1) allowing "All locations" for registration (even if blocking specific locations for sign-in); 2) including "MFA Trusted IPs" or home office locations in allowed locations; 3) a separate registration policy with relaxed location requirements; 4) report-only mode to identify affected users. MFA is still required by default for ALL passwordless credential registration (WHfB, Platform SSO, passkeys) even without CA policies.'
        } else {
            "Review this policy's device filter and app requirements to ensure they don't block legitimate credential registration flows. Test with report-only mode. Ensure users setting up new devices can satisfy policy requirements, or add exclusions/adjust conditions for the registration flow."
        }

        $Params = @{
            Severity         = $Severity
            Category         = 'Credential Registration Constraints'
            Title            = 'Policy may block Windows Hello / Platform SSO setup on new devices (July 2026 enforcement)'
            Description      = "Since July 2026 (MC1326253) this policy is enforced during Windows Hello for Business and macOS Platform SSO credential registration - not just sign-in. This policy has the following constraints that may prevent users from completing device setup:`n$(@($Issues | ForEach-Object { "- $_" }) -join "`n")`n`nWhen users provision WHfB on a new laptop or register macOS Platform SSO credentials for the first time, they may not be able to satisfy these requirements. This can block legitimate enrollment flows. Per Microsoft's Message Center post (MC1326253), admins should review policies targeting ""Register security info"" and test with report-only mode."
            Remediation      = $Remediation
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
