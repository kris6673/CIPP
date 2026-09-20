function Test-CIPPCAGapPrivilegedRoleExclusion {
    <#
    .SYNOPSIS
        Flags policies that exclude highly privileged directory roles.
    .DESCRIPTION
        Per policy (any state): every excluded role that is in the high-privilege list produces one finding per policy.
        Critical when Global Administrator, Privileged Role Administrator, Privileged Authentication Administrator or
        Conditional Access Administrator is excluded (or when the policy protects security-info registration),
        otherwise High; downgraded to Info when another non-disabled policy covers those roles with MFA or an
        authentication strength. Tenant-wide: one Critical finding lists every enabled policy that excludes a critical
        admin role.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $RoleNames = $Context.Data.HighPrivilegeRoleNames
    $CriticalRoleIds = $Context.Data.CriticalRoleIds
    $RegisterSecurityInfo = "$($Context.Data.Reference.registerSecurityInfoAction)"

    foreach ($Policy in @($Context.Policies)) {
        $ExcludedRoles = @($Policy.conditions.users.excludeRoles)
        if ($ExcludedRoles.Count -eq 0) { continue }

        $ExcludedHighPriv = [System.Collections.Generic.List[object]]::new()
        foreach ($RoleId in $ExcludedRoles) {
            $Name = $RoleNames["$RoleId".ToLowerInvariant()]
            if ($Name) {
                $ExcludedHighPriv.Add([PSCustomObject]@{ id = "$RoleId"; name = "$Name"; critical = $CriticalRoleIds.Contains("$RoleId") })
            }
        }
        if ($ExcludedHighPriv.Count -eq 0) { continue }

        $HasCritical = @($ExcludedHighPriv | Where-Object { $_.critical }).Count -gt 0
        $CriticalNames = @($ExcludedHighPriv | Where-Object { $_.critical } | ForEach-Object { $_.name })
        $AllNames = @($ExcludedHighPriv | ForEach-Object { $_.name })
        $ExcludedLower = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($Entry in $ExcludedHighPriv) { $null = $ExcludedLower.Add($Entry.id) }

        $CoveringPolicy = $null
        foreach ($Other in @($Context.Policies)) {
            if ($Other.id -eq $Policy.id -or $Other.state -eq 'disabled') { continue }
            $OtherUsers = $Other.conditions.users
            $EnforcesMfa = (@($Other.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $Other.grantControls.authenticationStrength)
            if (-not $EnforcesMfa) { continue }
            $IncludeRoles = @($OtherUsers.includeRoles | ForEach-Object { "$_".ToLowerInvariant() })
            $IncludesViaRoles = @($ExcludedLower | Where-Object { $IncludeRoles -notcontains $_.ToLowerInvariant() }).Count -eq 0
            $OtherExcludeRoles = @($OtherUsers.excludeRoles | ForEach-Object { "$_".ToLowerInvariant() })
            $ReExcludes = @($ExcludedLower | Where-Object { $OtherExcludeRoles -contains $_.ToLowerInvariant() }).Count -gt 0
            $IncludesViaAllUsers = (@($OtherUsers.includeUsers) -contains 'All') -and -not $ReExcludes
            if ($IncludesViaRoles -or $IncludesViaAllUsers) { $CoveringPolicy = $Other; break }
        }

        $Controls = @($Policy.grantControls.builtInControls)
        $RequiresMfa = ($Controls -contains 'mfa') -or ($null -ne $Policy.grantControls.authenticationStrength)
        $Blocks = $Controls -contains 'block'
        $TargetsSecurityRegistration = @($Policy.conditions.applications.includeUserActions) -contains $RegisterSecurityInfo
        $TargetsAllApps = @($Policy.conditions.applications.includeApplications) -contains 'All'

        $Severity = if ($HasCritical) { 'Critical' } else { 'High' }
        if ($TargetsSecurityRegistration) {
            $ScenarioNames = if ($CriticalNames.Count -gt 0) { $CriticalNames -join ', ' } else { $AllNames -join ', ' }
            $AttackScenario = "This policy protects security info registration but excludes $ScenarioNames. An attacker who compromises one of these admin accounts can register their own MFA methods (phone, authenticator app) from ANY location or device with NO controls. This gives them persistent access that survives a password reset."
            $Severity = 'Critical'
        } elseif ($Blocks) {
            $AttackScenario = "This policy blocks access but excludes privileged role(s): $($AllNames -join ', '). These admin accounts bypass the block entirely, creating a privileged access path."
        } elseif ($RequiresMfa -and $TargetsAllApps) {
            $AttackScenario = "This policy requires MFA for all apps but excludes: $($AllNames -join ', '). These admins can access all cloud apps without MFA - the highest-value accounts have the weakest protection."
        } else {
            $AttackScenario = "This policy excludes $($ExcludedHighPriv.Count) privileged role(s): $($AllNames -join ', '). Privileged accounts should have EQUAL or STRICTER controls, not exemptions."
        }
        if ($CoveringPolicy) { $Severity = 'Info' }

        $CoveredNote = if ($CoveringPolicy) {
            $StateLabel = if ($CoveringPolicy.state -eq 'enabledForReportingButNotEnforced') { 'report-only' } else { 'enabled' }
            " However, these roles appear to be covered by a separate policy: $($CoveringPolicy.displayName) ($StateLabel). Verify that policy enforces equivalent or stricter controls for these admin roles."
        } else {
            ' No separate policy was found that covers these excluded admin roles with MFA or authentication strength. Per Microsoft Zero Trust and CIS benchmarks, privileged roles should be the FIRST users subject to strong controls, not excluded from them.'
        }

        $TitleSuffix = ''
        if ($HasCritical) { $TitleSuffix += ' - includes critical admin roles' }
        if ($CoveringPolicy) { $TitleSuffix += ' (covered by separate policy)' }

        $Remediation = if ($CoveringPolicy) {
            "The excluded admin roles appear covered by $($CoveringPolicy.displayName). Confirm that policy enforces equivalent controls (MFA, authentication strength, device compliance). Break-glass accounts should still be excluded by specific user ID, never by role."
        } else {
            "Remove $($AllNames -join ', ') from the excluded roles. If you need emergency access, exclude 1-2 dedicated break-glass accounts by user ID (in excludeUsers) instead of excluding an entire admin role. Break-glass accounts should have complex passwords, be cloud-only, and be monitored with alerts."
        }

        $Affected = [System.Collections.Generic.List[string]]::new()
        $Affected.Add($Policy.displayName)
        if ($CoveringPolicy) { $Affected.Add($CoveringPolicy.displayName) }

        $Params = @{
            Severity         = $Severity
            Category         = 'Privileged Role Exclusion'
            Title            = "$($ExcludedHighPriv.Count) privileged role(s) excluded$TitleSuffix"
            Description      = $AttackScenario + $CoveredNote
            Remediation      = $Remediation
            AffectedPolicies = @($Affected)
            RelatedIds       = @($ExcludedHighPriv | ForEach-Object { $_.id })
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    # tenant-wide: enabled policies excluding critical admin roles
    $PoliciesExcludingCritical = @($Context.Enabled | Where-Object {
            @($_.conditions.users.excludeRoles | Where-Object { $CriticalRoleIds.Contains("$_") }).Count -gt 0
        })
    if ($PoliciesExcludingCritical.Count -gt 0) {
        $AffectedNames = @($PoliciesExcludingCritical | ForEach-Object { $_.displayName })
        $Params = @{
            Severity         = 'Critical'
            Category         = 'Privileged Role Exclusion'
            Title            = "$($PoliciesExcludingCritical.Count) policy(ies) exclude critical admin roles (Global Admin, Privileged Role Admin, etc.)"
            Description      = "$($PoliciesExcludingCritical.Count) enabled policy(ies) exclude one or more critical admin roles from their controls: $($AffectedNames -join ', '). Global Administrators and Privileged Role Administrators are the highest-value targets for attackers. Excluding them from CA policies means these accounts have WEAKER protection than regular users - the opposite of Zero Trust principles. Break-glass access should use dedicated accounts excluded by user ID, not entire admin roles."
            Remediation      = 'Remove admin role exclusions from all CA policies. Instead: 1) Create 2 cloud-only break-glass accounts with complex passwords, 2) Exclude them by user ID (not role) from MFA policies, 3) Set up Azure Monitor alerts for any break-glass sign-in, 4) Ensure all admin roles are subject to phishing-resistant MFA (FIDO2 or certificate-based). Per CIS 6.2.1 and Microsoft Zero Trust: admins should have equal or stricter controls.'
            AffectedPolicies = $AffectedNames
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
