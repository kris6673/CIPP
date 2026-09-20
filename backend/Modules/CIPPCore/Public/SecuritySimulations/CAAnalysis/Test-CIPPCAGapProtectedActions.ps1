function Test-CIPPCAGapProtectedActions {
    <#
    .SYNOPSIS
        Reviews policies that protect Protected Actions (microsoft.directory.* user actions).
    .DESCRIPTION
        For every policy (any state) whose user actions start with "microsoft.directory": basic "Require MFA" instead
        of an authentication strength is High; targeting All users instead of admin roles is Medium; a non-phishing-
        resistant authentication strength is Info; report-only state is Info; an enabled policy with no user
        exclusions (no break-glass path) is Medium.
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
        $UserActions = @($Policy.conditions.applications.includeUserActions)
        if ($UserActions.Count -eq 0) { continue }
        $ProtectedActions = @($UserActions | Where-Object { "$_".StartsWith('microsoft.directory') })
        if ($ProtectedActions.Count -eq 0) { continue }

        $Grant = $Policy.grantControls
        $Users = $Policy.conditions.users
        $Controls = @($Grant.builtInControls)
        $ActionList = $ProtectedActions -join ', '
        $UsesBasicMfa = ($Controls -contains 'mfa') -and ($null -eq $Grant.authenticationStrength)
        $UsesAuthStrength = $null -ne $Grant.authenticationStrength

        if ($UsesBasicMfa) {
            $Params = @{
                Severity         = 'High'
                Category         = 'Protected Actions Configuration'
                Title            = 'Protected Actions policy uses basic MFA instead of authentication strength'
                Description      = "This policy targets protected actions ($ActionList) but uses the basic ""Require MFA"" grant control instead of an authentication strength. Protected Actions policies MUST use authentication strength to function correctly. With basic MFA the policy may not enforce correctly during the protected action, users may bypass the additional authentication requirement, and Microsoft's recommendation is always authentication strength for Protected Actions. Protected Actions are sensitive operations such as deleting or modifying CA policies, changing role assignments and modifying app registrations - they require phishing-resistant or strong authentication to prevent privilege escalation attacks."
                Remediation      = 'Replace the grant control: remove "Require multifactor authentication" and add an authentication strength (recommended: "Phishing-resistant MFA"; minimum: "Multifactor authentication"). In the Entra admin center open Protection > Conditional Access > this policy > Grant > "Require authentication strength" and choose the strength. Verify all targeted admins have registered the required methods before enforcing, and use report-only mode first.'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }

        $TargetsAllUsers = @($Users.includeUsers) -contains 'All'
        $TargetsAdminRoles = @($Users.includeRoles).Count -gt 0
        if ($TargetsAllUsers -and -not $TargetsAdminRoles) {
            $Params = @{
                Severity         = 'Medium'
                Category         = 'Protected Actions Configuration'
                Title            = "Protected Actions policy targets 'All users' instead of specific admin roles"
                Description      = "This policy targets protected actions ($ActionList) and applies to All users. Protected Actions are typically administrative operations that only admins can perform. Targeting ""All users"" creates unnecessary auth prompts for non-admin users who wouldn't be able to perform these actions anyway. Best practice: target only the specific admin roles that perform these protected actions (CA policy changes: Conditional Access Administrator, Security Administrator; role management: Privileged Role Administrator, Global Administrator; app registration changes: Application Administrator, Cloud Application Administrator)."
                Remediation      = 'Determine which roles perform these actions in your environment, change the policy from "All users" to those directory roles, and make sure break-glass accounts are excluded.'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }

        if ($UsesAuthStrength) {
            $StrengthName = "$($Grant.authenticationStrength.displayName)"
            if (-not (Test-CIPPCAPolicyPhishingResistant -Policy $Policy -Context $Context)) {
                $Params = @{
                    Severity         = 'Info'
                    Category         = 'Protected Actions Configuration'
                    Title            = "Protected Actions using ""$StrengthName"" - consider phishing-resistant MFA"
                    Description      = "This policy protects sensitive admin actions ($ActionList) using the ""$StrengthName"" authentication strength. Microsoft's recommendation is phishing-resistant MFA for Protected Actions to prevent privilege escalation attacks: standard MFA methods (SMS, TOTP, push notifications) can be defeated by adversary-in-the-middle (AiTM) phishing. Attackers who compromise an admin account want to delete CA policies, modify role assignments for persistence, or change app registrations to grant broad API permissions. Phishing-resistant methods include FIDO2 security keys, Windows Hello for Business, Certificate-Based Authentication and passkeys in Microsoft Authenticator."
                    Remediation      = 'Deploy phishing-resistant credentials to admins who perform protected actions, update this policy to the "Phishing-resistant MFA" authentication strength, and use Temporary Access Pass (TAP) to bootstrap credential registration. This is informational only - the current configuration meets minimum requirements.'
                    AffectedPolicies = @($Policy.displayName)
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }

        if ($Policy.state -eq 'enabledForReportingButNotEnforced') {
            $Params = @{
                Severity         = 'Info'
                Category         = 'Protected Actions Configuration'
                Title            = 'Protected Actions policy in report-only mode - consider enabling for enforcement'
                Description      = 'This Protected Actions policy is currently in report-only mode. While this is the recommended initial deployment state, once you have validated that admins can satisfy the requirements the policy should be enabled for enforcement. In report-only mode the additional authentication is NOT required, sign-in logs only show what would have happened, and admins can still perform protected actions without the additional verification - your protected actions are currently NOT protected. Report-only should be a temporary validation phase, not a permanent state.'
                Remediation      = 'Review sign-in logs to check that admins satisfy the authentication strength in report-only, confirm all targeted admins have registered the required credentials, then change the policy state from "Report-only" to "On" and monitor for authentication failures in the first 24-48 hours. Enable enforcement after 1-2 weeks of successful report-only validation.'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }

        $HasExclusions = @($Users.excludeUsers).Count -gt 0
        if (-not $HasExclusions -and $Policy.state -eq 'enabled') {
            $Params = @{
                Severity         = 'Medium'
                Category         = 'Protected Actions Configuration'
                Title            = 'Protected Actions policy has no user exclusions - ensure break-glass access'
                Description      = 'This policy protects sensitive admin actions but does not exclude any users (such as break-glass accounts). Risk: if the authentication strength requirement fails (e.g., FIDO2 not working, auth service outage), admins may be unable to perform critical operations like disabling a misconfigured CA policy that locks out users, modifying role assignments to restore access, or responding to security incidents that require CA policy changes. Break-glass accounts should be excluded from Protected Actions policies to ensure emergency access to critical admin operations.'
                Remediation      = 'Identify your break-glass accounts (typically 2 emergency access accounts with permanent Global Admin), add them to the "Exclude users" list of this policy, and make sure they are cloud-only, monitored with alerts for any sign-in activity, excluded from ALL CA policies that could block emergency access, and use strong randomly generated passwords stored in a secure physical location.'
                AffectedPolicies = @($Policy.displayName)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }
    }

    @($Findings)
}
