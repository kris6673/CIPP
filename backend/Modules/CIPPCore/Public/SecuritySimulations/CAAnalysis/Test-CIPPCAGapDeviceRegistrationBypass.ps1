function Test-CIPPCAGapDeviceRegistrationBypass {
    <#
    .SYNOPSIS
        Finds policies that try to protect device registration with controls the Device Registration Service ignores.
    .DESCRIPTION
        The Device Registration Service only honors MFA / authentication strength grant controls (MSRC VULN-153600,
        by design). A policy that reaches the service (explicitly via the register-device user action or the DRS
        resource, or incidentally via All apps) and relies only on location conditions or a compliant/hybrid-joined
        device requirement, with no MFA of its own and no separate enabled registration-MFA policy, leaves device
        registration unprotected. Explicit targeting is High, incidental All-apps coverage is Medium.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $DrsId = "$($Context.Data.DeviceRegistrationResource.resourceId)"
    $RegisterAction = "$($Context.Data.Reference.registerDeviceAction)"

    $RequiresMfa = {
        param($P)
        (@($P.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $P.grantControls.authenticationStrength)
    }

    foreach ($Policy in @($Context.Policies)) {
        if ($Policy.state -eq 'disabled') { continue }

        $Apps = $Policy.conditions.applications
        $Controls = @($Policy.grantControls.builtInControls)
        $Locations = $Policy.conditions.locations

        $ExplicitlyTargetsRegistration = (@($Apps.includeApplications) -contains $DrsId) -or (@($Apps.includeUserActions) -contains $RegisterAction)
        $TargetsAllApps = @($Apps.includeApplications) -contains 'All'
        if (-not $ExplicitlyTargetsRegistration -and -not $TargetsAllApps) { continue }

        $UsesLocationCondition = ($null -ne $Locations) -and ((@($Locations.includeLocations).Count -gt 0) -or (@($Locations.excludeLocations).Count -gt 0))
        $RequiresCompliantDevice = ($Controls -contains 'compliantDevice') -or ($Controls -contains 'domainJoinedDevice')
        if (-not $UsesLocationCondition -and -not $RequiresCompliantDevice) { continue }
        if (& $RequiresMfa $Policy) { continue }

        $HasRegistrationMfaPolicy = $false
        foreach ($Other in @($Context.Policies)) {
            if ($Other.id -eq $Policy.id -or $Other.state -eq 'disabled') { continue }
            $OtherApps = $Other.conditions.applications
            $CoversRegistration = (@($OtherApps.includeUserActions) -contains $RegisterAction) -or (@($OtherApps.includeApplications) -contains $DrsId)
            if ($CoversRegistration -and (& $RequiresMfa $Other)) { $HasRegistrationMfaPolicy = $true; break }
        }
        if ($HasRegistrationMfaPolicy) { continue }

        $Blocks = $Controls -contains 'block'
        $Issues = [System.Collections.Generic.List[string]]::new()
        if ($UsesLocationCondition) { $Issues.Add('location-based conditions') }
        if ($RequiresCompliantDevice) { $Issues.Add('a compliant/hybrid-joined device requirement') }
        $IssueText = $Issues -join ' and '

        $Framing = if ($Blocks) {
            "This policy blocks access using $IssueText, but those conditions are NOT evaluated for the Device Registration Service ($DrsId). Device registration is therefore not covered by this block and can still occur (for example from an untrusted location)."
        } else {
            "This policy relies on $IssueText to grant access, but those controls are NOT evaluated for the Device Registration Service ($DrsId) - only MFA / authentication strength is."
        }

        $Params = @{
            Severity         = if ($ExplicitlyTargetsRegistration) { 'High' } else { 'Medium' }
            Category         = 'Device Registration Bypass'
            Title            = if ($ExplicitlyTargetsRegistration) { 'Device registration protected only by controls the service ignores' } else { "Device Registration Service not covered by this policy's controls" }
            Description      = "$Framing The DRS only honors MFA grant controls (MSRC VULN-153600 - confirmed by-design by Microsoft). No separate enabled policy was found that requires MFA or authentication strength for the register-device user action, so device registration currently has no working control from this policy."
            Remediation      = 'Create (or enable) a dedicated policy that requires MFA or authentication strength for the "Register or join devices" user action. Do not rely on location or device compliance to protect device enrollment.'
            AffectedPolicies = @($Policy.displayName)
            RelatedIds       = @($DrsId)
            CaTemplate       = "$($Context.Data.Reference.templates.registerSecurityInfo)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
