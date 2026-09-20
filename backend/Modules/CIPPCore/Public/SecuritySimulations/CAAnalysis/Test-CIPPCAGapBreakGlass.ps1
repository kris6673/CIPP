function Test-CIPPCAGapBreakGlass {
    <#
    .SYNOPSIS
        Checks that the detected break-glass account or group is excluded from every user-targeting policy.
    .DESCRIPTION
        Uses the break-glass candidate on the context (the user or group excluded most often across enabled and
        report-only All-users policies). Per policy that targets real users: Info when the candidate is excluded;
        otherwise High for enabled block-everything policies, Medium for enabled MFA/compliance/block All-users
        policies and report-only policies, Low for other enabled or disabled policies, Info for disabled
        Microsoft-managed policies. Tenant-wide: one summary finding (High/Medium when some policies miss the
        exclusion, Info when all have it) or a Critical finding when no break-glass candidate can be detected at all.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $BreakGlass = $Context.BreakGlass

    $TargetsUsers = {
        param($P)
        $U = $P.conditions.users
        (@($U.includeUsers | Where-Object { $_ -ne 'None' }).Count -gt 0) -or (@($U.includeGroups).Count -gt 0) -or (@($U.includeRoles).Count -gt 0)
    }
    $IsExcluded = {
        param($P)
        if ($BreakGlass.type -eq 'user') { @($P.conditions.users.excludeUsers) -contains $BreakGlass.id }
        else { @($P.conditions.users.excludeGroups) -contains $BreakGlass.id }
    }

    $AllPolicies = @($Context.Policies)
    $UserTargetingPolicies = @($AllPolicies | Where-Object { & $TargetsUsers $_ })

    if ($BreakGlass) {
        $Label = if ($BreakGlass.type -eq 'user') { 'break-glass account' } else { 'break-glass group' }
        $DisplayName = "$($BreakGlass.displayName)"
        $ExcludeTarget = if ($BreakGlass.type -eq 'user') { 'excluded users' } else { 'excluded groups' }

        foreach ($Policy in $UserTargetingPolicies) {
            $Excluded = & $IsExcluded $Policy

            if ($Excluded) {
                $Params = @{
                    Severity         = 'Info'
                    Category         = 'Break-Glass'
                    Title            = "Break-glass $($BreakGlass.type) excluded"
                    Description      = "The $Label $DisplayName is excluded from this policy. This ensures emergency access is preserved if this policy causes a lockout."
                    Remediation      = "No action required. Verify the $Label periodically to ensure it is still valid and monitored for sign-in activity."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($BreakGlass.id)
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
                continue
            }

            $Controls = @($Policy.grantControls.builtInControls)
            $Blocks = $Controls -contains 'block'
            $RequiresMfa = ($Controls -contains 'mfa') -or ($null -ne $Policy.grantControls.authenticationStrength)
            $RequiresCompliance = ($Controls -contains 'compliantDevice') -or ($Controls -contains 'domainJoinedDevice')
            $TargetsAllUsers = @($Policy.conditions.users.includeUsers) -contains 'All'
            $TargetsAllApps = @($Policy.conditions.applications.includeApplications) -contains 'All'

            $Severity = 'Low'
            if ($Blocks -and $TargetsAllUsers -and $TargetsAllApps) { $Severity = 'High' }
            elseif (($RequiresMfa -or $RequiresCompliance) -and $TargetsAllUsers) { $Severity = 'Medium' }
            elseif ($Blocks -and $TargetsAllUsers) { $Severity = 'Medium' }

            $IsMicrosoftManaged = "$($Policy.displayName)".ToLowerInvariant().Contains('microsoft managed') -or ($null -ne $Policy.templateId)
            if ($IsMicrosoftManaged -and $Policy.state -eq 'disabled') {
                $Params = @{
                    Severity         = 'Info'
                    Category         = 'Break-Glass'
                    Title            = "Break-glass $($BreakGlass.type) not excluded (disabled Microsoft managed policy)"
                    Description      = "The $Label $DisplayName is not excluded from this policy, but the policy is disabled and Microsoft managed. No risk while disabled."
                    Remediation      = "If you enable this policy, add the $Label $DisplayName to the exclusions first to prevent emergency access lockout."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($BreakGlass.id)
                }
            } elseif ($Policy.state -eq 'enabledForReportingButNotEnforced') {
                $Params = @{
                    Severity         = 'Medium'
                    Category         = 'Break-Glass'
                    Title            = "Break-glass $($BreakGlass.type) not excluded (report-only policy)"
                    Description      = "The $Label $DisplayName is not excluded from this policy. This policy is currently in report-only mode so there is no enforcement risk, but the $Label should be added before switching to enabled."
                    Remediation      = "Add the $Label $DisplayName to the user/group exclusions before enabling enforcement on this policy."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($BreakGlass.id)
                }
            } elseif ($Policy.state -eq 'disabled') {
                $Params = @{
                    Severity         = 'Low'
                    Category         = 'Break-Glass'
                    Title            = "Break-glass $($BreakGlass.type) not excluded (disabled policy)"
                    Description      = "The $Label $DisplayName is not excluded from this policy. This policy is currently disabled so there is no enforcement risk."
                    Remediation      = "Add the $Label $DisplayName to the exclusions before enabling this policy."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($BreakGlass.id)
                }
            } else {
                $Params = @{
                    Severity         = $Severity
                    Category         = 'Break-Glass'
                    Title            = "Break-glass $($BreakGlass.type) NOT excluded"
                    Description      = "The $Label $DisplayName is NOT excluded from this enabled policy. If this policy causes a lockout (e.g. misconfigured MFA, compliance, or block rule), the $Label will also be blocked and cannot be used for emergency access."
                    Remediation      = "Add the $Label $DisplayName to the $ExcludeTarget for this policy to preserve emergency access: edit the policy in the Entra admin center, open Users > Exclude, add $DisplayName and save."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($BreakGlass.id)
                }
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }

        # tenant-wide summary
        $WithNames = [System.Collections.Generic.List[string]]::new()
        $WithoutNames = [System.Collections.Generic.List[string]]::new()
        $EnabledWithoutCount = 0
        foreach ($Policy in $UserTargetingPolicies) {
            if (& $IsExcluded $Policy) { $WithNames.Add($Policy.displayName) }
            else {
                $WithoutNames.Add($Policy.displayName)
                if ($Policy.state -eq 'enabled') { $EnabledWithoutCount++ }
            }
        }
        $BreakGlassLabel = if ($BreakGlass.type -eq 'user') { 'Break-glass account' } else { 'Break-glass group' }
        $TotalPolicyCount = $AllPolicies.Count
        $Overview = "$BreakGlassLabel`: $DisplayName. Tenant overview - total policies in tenant: $TotalPolicyCount; policies targeting users: $($UserTargetingPolicies.Count); with break-glass excluded: $($WithNames.Count); without break-glass excluded: $($WithoutNames.Count)."

        if ($WithoutNames.Count -gt 0) {
            $Listed = @($WithoutNames | Select-Object -First 10) -join ', '
            $Overflow = if ($WithoutNames.Count -gt 10) { " and $($WithoutNames.Count - 10) more..." } else { '' }
            $Params = @{
                Severity         = if ($EnabledWithoutCount -gt 0) { 'High' } else { 'Medium' }
                Category         = 'Break-Glass'
                Title            = "$BreakGlassLabel coverage: $($WithNames.Count) of $($UserTargetingPolicies.Count) policies ($TotalPolicyCount total in tenant)"
                Description      = "$Overview The $($BreakGlassLabel.ToLowerInvariant()) $DisplayName was detected by analyzing exclusion patterns across your policies. $($WithoutNames.Count) user-targeting policy(ies) do NOT exclude this $($BreakGlassLabel.ToLowerInvariant()). Without break-glass exclusions, a misconfigured CA policy can lock out ALL administrators. Microsoft recommends excluding break-glass accounts from every Conditional Access policy to ensure emergency access. Policies WITHOUT break-glass exclusion: $Listed$Overflow"
                Remediation      = "Add break-glass exclusions to all $($WithoutNames.Count) policies listed above (edit each policy > Users > Exclude > add $DisplayName > save). Best practices: exclude break-glass from ALL CA policies, use cloud-only accounts with 16+ character passwords stored in a physical safe, no mailbox assigned, Azure Monitor alerts for ANY break-glass sign-in, and test quarterly. See https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access"
                AffectedPolicies = @($WithoutNames)
                RelatedIds       = @($BreakGlass.id)
            }
        } else {
            $Params = @{
                Severity         = 'Info'
                Category         = 'Break-Glass'
                Title            = "$BreakGlassLabel excluded from all $($UserTargetingPolicies.Count) user-targeting policies ($TotalPolicyCount total in tenant)"
                Description      = "$Overview The $($BreakGlassLabel.ToLowerInvariant()) $DisplayName is correctly excluded from all user-targeting Conditional Access policies. This ensures emergency access is preserved across your entire tenant. Break-glass accounts are cloud-only emergency access accounts with permanent Global Admin privileges that are excluded from all CA policies to prevent administrative lockout."
                Remediation      = "Ongoing maintenance: confirm $DisplayName is your intended break-glass $($BreakGlass.type), set up Azure Monitor alerts for ANY activity on it, test emergency access every 3 months, make sure new CA policies also exclude it, and maintain 2 break-glass accounts for redundancy."
                AffectedPolicies = @($WithNames)
                RelatedIds       = @($BreakGlass.id)
            }
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    } else {
        $CriticalPolicies = @($Context.Enabled | Where-Object {
                if (-not (@($_.conditions.users.includeUsers) -contains 'All')) { return $false }
                $C = @($_.grantControls.builtInControls)
                ($C -contains 'mfa') -or ($null -ne $_.grantControls.authenticationStrength) -or ($C -contains 'block') -or ($C -contains 'compliantDevice')
            })
        $CriticalList = @($CriticalPolicies | Select-Object -First 10 | ForEach-Object { "- $($_.displayName)" }) -join "`n"
        $CriticalOverflow = if ($CriticalPolicies.Count -gt 10) { "`n...and $($CriticalPolicies.Count - 10) more" } else { '' }
        $TotalPolicyCount = $AllPolicies.Count
        $Params = @{
            Severity         = 'Critical'
            Category         = 'Break-Glass'
            Title            = "No break-glass account or group detected across $TotalPolicyCount policies"
            Description      = "No consistent user or group exclusions were found across your $TotalPolicyCount Conditional Access policies that would indicate a break-glass (emergency access) account or group. Tenant overview - total policies in tenant: $TotalPolicyCount; policies targeting users: $($UserTargetingPolicies.Count); break-glass exclusions found: 0. Without break-glass accounts excluded from CA policies, a misconfiguration can lock out ALL administrators, including Global Admins. Microsoft Support intervention may be required, causing extended downtime. Critical policies that need break-glass exclusions:`n$CriticalList$CriticalOverflow"
            Remediation      = "Immediate action required: 1) create 2 break-glass accounts (cloud-only, Global Admin, 16+ character passwords, no mailbox); 2) exclude them from ALL $TotalPolicyCount CA policies (edit each policy > Users > Exclude > add both accounts); 3) set up Azure Monitor alerts on ANY break-glass sign-in; 4) test quarterly. See https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access"
            AffectedPolicies = @($CriticalPolicies | ForEach-Object { $_.displayName })
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
