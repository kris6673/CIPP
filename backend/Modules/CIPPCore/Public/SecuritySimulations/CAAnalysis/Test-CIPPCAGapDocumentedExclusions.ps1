function Test-CIPPCAGapDocumentedExclusions {
    <#
    .SYNOPSIS
        Evaluates every policy against the Microsoft Learn catalog of documented exclusions and limitations.
    .DESCRIPTION
        Ports the documented-exclusion checks (token protection scoping, break-glass exclusions, Surface Hub / Teams
        Rooms compatibility, device code flow, sign-in frequency, Defender mobile, Azure VM sign-in, CAE, resilience
        defaults, All-resources baseline scopes, Directory Sync account, External Authentication Methods, approved
        client app retirement and the user-risk remediation controls). Static text lives in KnownExclusions.json; the
        detection logic is here, keyed by exclusion id. By default only Critical and High results are returned as
        findings (category "MS Learn: Documented Exclusion"), and the All-resources baseline-scope entry is never
        promoted because Test-CIPPCAGapResourceExclusionBypass already reports it tenant-wide. -IncludeAdvisory also
        returns the Medium/Info results. The tenant's External Authentication Method state is not cached by CIPP, so
        the EAM companion-policy check reports as unverified rather than being suppressed.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context,
        [switch]$IncludeAdvisory
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Reference = $Context.Data.Reference
    $Apps = $Reference.documentedExclusionApps
    $ExclusionById = @{}
    foreach ($Exclusion in @($Context.Data.KnownExclusions)) { $ExclusionById["$($Exclusion.id)"] = $Exclusion }

    $ExchangeOnline = "$($Apps.exchangeOnline)".ToLowerInvariant()
    $SharePointOnline = "$($Apps.sharePointOnline)".ToLowerInvariant()
    $TeamsService = "$($Apps.teamsService)".ToLowerInvariant()
    $Office365Group = "$($Apps.office365Group)".ToLowerInvariant()
    $DefenderAtp = "$($Apps.defenderAtpXplat)".ToLowerInvariant()
    $DefenderTvm = "$($Apps.defenderTvm)".ToLowerInvariant()
    $WindowsCloudLogin = "$($Apps.windowsCloudLogin)".ToLowerInvariant()
    $TokenProtectionSupported = @($ExchangeOnline, $SharePointOnline, $TeamsService, "$($Apps.azureVirtualDesktop)".ToLowerInvariant(), "$($Apps.windows365)".ToLowerInvariant(), $WindowsCloudLogin)
    $DirSyncRoleId = "$($Context.Data.DirSyncRoleId)"

    $IsActive = { param($P) $P.state -in @('enabled', 'enabledForReportingButNotEnforced') }
    $TargetsAllUsers = { param($P) @($P.conditions.users.includeUsers) -contains 'All' }
    $TargetsAllApps = { param($P) @($P.conditions.applications.includeApplications) -contains 'All' }
    $HasMfaGrant = { param($P) (@($P.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $P.grantControls.authenticationStrength) }
    $HasBlockGrant = { param($P) @($P.grantControls.builtInControls) -contains 'block' }
    $HasComplianceGrant = { param($P) @($P.grantControls.builtInControls) -contains 'compliantDevice' }
    $HasAdminRoles = { param($P) @($P.conditions.users.includeRoles).Count -gt 0 }
    $HasNoUserExclusions = { param($P) $U = $P.conditions.users; (@($U.excludeUsers).Count -eq 0) -and (@($U.excludeGroups).Count -eq 0) -and (@($U.excludeRoles).Count -eq 0) }
    $HasTokenProtection = {
        param($P)
        $Session = $P.sessionControls
        if ($null -eq $Session) { return $false }
        if ($Session.secureSignInSession.isEnabled -eq $true) { return $true }
        if ($Session.tokenProtection.signInSessionTokenProtection.isEnabled -eq $true) { return $true }
        $false
    }
    $LowerApps = { param($Values) , [string[]]@(@($Values) | ForEach-Object { "$_".ToLowerInvariant() }) }

    $Results = [System.Collections.Generic.List[object]]::new()
    $AddResult = {
        param($ExclusionId, $Policy, $Detail, $Impacted)
        $Exclusion = $ExclusionById[$ExclusionId]
        if ($null -eq $Exclusion) { return }
        $Results.Add([PSCustomObject]@{
                exclusionId       = $ExclusionId
                policyId          = $Policy.id
                policyName        = $Policy.displayName
                severity          = "$($Exclusion.severity)"
                title             = "$($Exclusion.title)"
                detail            = $Detail
                impactedResources = [string[]]@($Impacted | Where-Object { $_ })
                remediation       = "$($Exclusion.remediation)"
                docUrl            = "$($Exclusion.docUrl)"
            })
    }

    foreach ($Policy in @($Context.Policies)) {
        $Active = & $IsActive $Policy
        $AllUsers = & $TargetsAllUsers $Policy
        $AllApps = & $TargetsAllApps $Policy
        $Grant = $Policy.grantControls
        $Controls = @($Grant.builtInControls)
        $IncludeApps = & $LowerApps $Policy.conditions.applications.includeApplications
        $ExcludeApps = & $LowerApps $Policy.conditions.applications.excludeApplications
        $Session = $Policy.sessionControls
        $SignInFrequency = $Session.signInFrequency
        $TokenProtection = & $HasTokenProtection $Policy

        # token-prot-apps
        if ($Active -and $TokenProtection) {
            if ($IncludeApps -contains 'all') {
                & $AddResult 'token-prot-apps' $Policy 'Token Protection policy targets "All cloud apps" instead of specific supported applications. This will block users on unsupported apps like PowerQuery, VS Code extensions, and Office perpetual clients.' @('PowerShell modules accessing SharePoint', 'PowerQuery extension for Excel', 'VS Code extensions accessing Exchange/SharePoint', 'Office perpetual clients')
            } elseif ($IncludeApps -contains $Office365Group) {
                & $AddResult 'token-prot-apps' $Policy 'Token Protection policy uses the Office 365 application group. Microsoft warns this may result in unintended failures. Target Exchange Online, SharePoint Online, and Teams Services individually instead.' @('Office 365 application group members')
            } else {
                $Unsupported = @($IncludeApps | Where-Object { $TokenProtectionSupported -notcontains $_ })
                if ($Unsupported.Count -gt 0) {
                    & $AddResult 'token-prot-apps' $Policy "Token Protection policy targets $($Unsupported.Count) application(s) that may not support token protection. Only Exchange Online, SharePoint Online, Teams, Azure Virtual Desktop, Windows 365, and Windows Cloud Login are supported." $Unsupported
                }
            }
        }

        # token-prot-platform
        if ($Active -and $TokenProtection) {
            $Issues = [System.Collections.Generic.List[string]]::new()
            $Platforms = $Policy.conditions.platforms
            if ($null -eq $Platforms -or -not (@($Platforms.includePlatforms) -contains 'windows')) {
                $Issues.Add('Token Protection policy does not explicitly target Windows platform. It is only supported on Windows 10+.')
            }
            $ClientTypes = @($Policy.conditions.clientAppTypes)
            if ($ClientTypes.Count -eq 0 -or ($ClientTypes -contains 'browser')) {
                $Issues.Add('Token Protection policy includes "Browser" client apps or has no Client Apps condition configured. MSAL.js-based apps like Teams Web will be blocked.')
            }
            if ($Issues.Count -gt 0) {
                & $AddResult 'token-prot-platform' $Policy ($Issues -join ' ') @('macOS / iOS / Android / Linux users', 'Teams Web (MSAL.js)', 'Browser-based applications')
            }
        }

        # token-prot-devices
        if ($Active -and $TokenProtection) {
            $DeviceFilter = $Policy.conditions.devices.deviceFilter
            if ($null -eq $DeviceFilter) {
                & $AddResult 'token-prot-devices' $Policy 'Token Protection policy has no device filter to exclude unsupported device types. Surface Hub, Teams Rooms (MTR), Cloud PCs (AzureAD joined), AVD session hosts, Autopilot self-deploying devices, bulk-enrolled devices, and Azure VMs will be BLOCKED. Users on these devices will see unclear error messages.' @('Surface Hub', 'Teams Rooms (MTR) on Windows', 'Cloud PCs (Microsoft Entra joined)', 'Azure Virtual Desktop session hosts (Microsoft Entra joined)', 'Windows Autopilot self-deploying devices', 'Bulk-enrolled Windows devices', 'Azure VMs with Entra ID auth')
            } else {
                $Rule = "$($DeviceFilter.rule)".ToLowerInvariant()
                $Missing = @($Reference.tokenProtectionDeviceFilterPatterns | Where-Object { -not $Rule.Contains("$($_.pattern)") })
                if ($Missing.Count -gt 0 -and "$($DeviceFilter.mode)" -eq 'exclude') {
                    $MissingLabels = @($Missing | ForEach-Object { "$($_.label)" })
                    & $AddResult 'token-prot-devices' $Policy "Token Protection device filter may not cover all unsupported device types. Potentially missing exclusions for: $($MissingLabels -join ', ')." $MissingLabels
                }
            }
        }

        # break-glass-missing
        if ($Active -and $AllUsers -and ((& $HasMfaGrant $Policy) -or (& $HasBlockGrant $Policy) -or (& $HasComplianceGrant $Policy)) -and (& $HasNoUserExclusions $Policy)) {
            & $AddResult 'break-glass-missing' $Policy "Policy ""$($Policy.displayName)"" targets All Users with enforcement controls but has NO user exclusions. If this policy is misconfigured or an outage occurs, ALL users (including admins) will be locked out. Microsoft strongly recommends excluding at least 2 emergency access accounts." @('All administrators', 'Emergency access accounts')
        }

        # surface-hub-mfa
        if ($Active -and $AllUsers -and $AllApps -and $Grant.present) {
            $UnsupportedControls = @($Controls | Where-Object { $_ -in @('mfa', 'compliantDevice', 'domainJoinedDevice', 'approvedApplication', 'compliantApplication', 'passwordChange') })
            $HasStrength = $null -ne $Grant.authenticationStrength
            if ($UnsupportedControls.Count -gt 0 -or $HasStrength) {
                $ControlList = [System.Collections.Generic.List[string]]::new()
                foreach ($ControlName in $UnsupportedControls) { $ControlList.Add($ControlName) }
                if ($HasStrength) { $ControlList.Add('authentication strength') }
                & $AddResult 'surface-hub-mfa' $Policy "Policy requires $($ControlList -join ', ') for all users. Surface Hub device accounts CANNOT satisfy these controls and will fail to sign in. This affects meeting room calendar sync, Teams Rooms sign-in, and collaborative features." @('Surface Hub calendar sync', 'Surface Hub Teams meetings', 'Surface Hub collaborative whiteboard')
            }
        }

        # teams-rooms-mfa
        if ($Active -and $AllUsers -and $Grant.present -and (($Controls -contains 'mfa') -or ($null -ne $Grant.authenticationStrength)) -and $AllApps) {
            & $AddResult 'teams-rooms-mfa' $Policy 'Policy requires MFA/authentication strength for all users and all apps. Teams Rooms on Windows does NOT support MFA or authentication strength. Teams Rooms Android devices support MFA but not authentication strength. Room resource accounts will be blocked from signing in.' @('Teams Rooms on Windows', 'Teams Rooms on Android (auth strength only)', 'Teams Panels')
        }

        # device-code-teams-android
        if ($Active -and (& $HasBlockGrant $Policy) -and -not [string]::IsNullOrWhiteSpace("$($Policy.conditions.authenticationFlows.transferMethods)")) {
            & $AddResult 'device-code-teams-android' $Policy 'Policy blocks device code authentication flow for all users. This prevents remote sign-in (microsoft.com/devicelogin) for Teams Android devices, Teams phones, and Teams panels. These devices rely on device code flow for initial setup.' @('Teams Rooms on Android', 'Teams phones', 'Teams panels', 'Remote device sign-in scenarios')
        }

        # signin-freq-teams-rooms
        if ($Active -and $AllUsers -and $SignInFrequency.isEnabled -eq $true -and $AllApps) {
            & $AddResult 'signin-freq-teams-rooms' $Policy "Policy enforces sign-in frequency ($($SignInFrequency.value) $($SignInFrequency.type)) for all users. Teams Rooms, Teams phones, and Teams panels do NOT support this. These devices will periodically sign out, disrupting scheduled meetings and room availability." @('Teams Rooms on Windows', 'Teams Rooms on Android', 'Teams phones', 'Teams panels')
        }

        # defender-mobile-exclusion
        if ($Active -and $AllUsers -and $AllApps) {
            $Locations = $Policy.conditions.locations
            $IsRestrictive = (& $HasBlockGrant $Policy) -or (($null -ne $Locations) -and (@($Locations.includeLocations).Count -gt 0) -and (& $HasBlockGrant $Policy))
            if ($IsRestrictive -and -not (($ExcludeApps -contains $DefenderAtp) -and ($ExcludeApps -contains $DefenderTvm))) {
                & $AddResult 'defender-mobile-exclusion' $Policy "Restrictive CA policy (block/location-based) targets all apps but does not exclude Microsoft Defender for Endpoint mobile apps. This can prevent Defender from reporting device posture, causing a compliance loop where devices appear non-compliant because Defender can't communicate with its backend." @("MicrosoftDefenderATP XPlat ($DefenderAtp)", "Microsoft Defender for Mobile TVM ($DefenderTvm)", 'Mobile device compliance reporting')
            }
        }

        # azure-vm-signin-mfa
        if ($Active -and $AllUsers -and $AllApps -and ((& $HasMfaGrant $Policy) -or (& $HasComplianceGrant $Policy)) -and -not ($ExcludeApps -contains $WindowsCloudLogin)) {
            & $AddResult 'azure-vm-signin-mfa' $Policy 'Policy requires MFA or device compliance for all users and all cloud apps but does not exclude the Microsoft Azure Windows Virtual Machine Sign-In app. Users connecting via RDP to Azure VMs or Arc-enabled Windows Servers must supply MFA claims from the initiating device. If Windows Hello for Business is not deployed, users may be unable to complete MFA during RDP sessions. Windows Server devices cannot satisfy device compliance requirements as RDP clients.' @("Microsoft Azure Windows Virtual Machine Sign-In ($WindowsCloudLogin)", 'RDP connections to Azure VMs', 'RDP connections to Arc-enabled Windows Servers', 'Windows Server RDP client devices (device compliance unsupported)')
        }

        # cae-disabled
        if ($Active -and "$($Session.continuousAccessEvaluation.mode)" -eq 'disabled') {
            & $AddResult 'cae-disabled' $Policy 'Policy explicitly disables Continuous Access Evaluation (CAE). This means access tokens remain valid for up to 1 hour after a security event (user disabled, password changed, location change). Real-time token revocation is lost.' @('Real-time user session revocation', 'Location-based policy enforcement', 'Risk-based session termination')
        }

        # signin-freq-individual-services
        if ($Active -and $SignInFrequency.isEnabled -eq $true -and -not ($IncludeApps -contains 'all')) {
            $TargetsIndividualM365 = @($IncludeApps | Where-Object { $_ -in @($ExchangeOnline, $SharePointOnline, $TeamsService) }).Count -gt 0
            if ($TargetsIndividualM365) {
                & $AddResult 'signin-freq-individual-services' $Policy 'Sign-in frequency is configured on individual Microsoft 365 services rather than all cloud apps. Microsoft documents that this can interrupt or stop the Teams device sign-in flow and is not supported.' @('Teams sign-in flow', 'Teams Rooms devices', 'Teams desktop/mobile clients')
            }
        }

        # resilience-disabled-impact
        if ($Active -and $Session.disableResilienceDefaults -eq $true) {
            $Scope = if ($AllUsers) { 'ALL users' } else { 'targeted users' }
            & $AddResult 'resilience-disabled-impact' $Policy "Policy disables resilience defaults for $Scope. During an Entra ID outage, users whose sessions expire will be DENIED access until the service recovers. This could block productivity for hours during a major outage." @('All users covered by this policy during Entra ID outages', 'Business continuity during identity service disruptions')
        }

        # all-resources-exclusion-change
        if ($Active -and $AllApps -and $ExcludeApps.Count -gt 0) {
            & $AddResult 'all-resources-exclusion-change' $Policy 'This policy targets "All cloud apps" with app exclusions. Since March 2026, the low-privilege scope exemption has been removed - User.Read, openid, profile, email, and offline_access are now enforced via the Windows Azure Active Directory app (00000002-0000-0000-c000-000000000000) as the enforcement audience. Without a dedicated policy covering this app, users accessing apps that only request these basic scopes may receive unexpected CA challenges - or may bypass enforcement entirely depending on your tenant''s rollout state.' @('Windows Azure Active Directory (00000002-0000-0000-c000-000000000000)', 'Apps requesting User.Read, openid, profile, email, offline_access scopes', 'Native clients and SPAs with basic Azure AD Graph access')
        }

        # dirsync-account-mfa
        if ($Active -and $AllUsers -and (& $HasMfaGrant $Policy) -and $DirSyncRoleId -and (@($Policy.conditions.users.excludeRoles) -contains $DirSyncRoleId)) {
            & $AddResult 'dirsync-account-mfa' $Policy 'This MFA policy excludes the Directory Synchronization Accounts role. If your organization is running Entra Connect v2.5.76.0 or later, this exclusion may no longer be necessary - v2.5.76.0 introduced application-based authentication for the sync engine, meaning the sync service principal can authenticate without a traditional user account. Review your Entra Connect version and migrate to app-based auth to eliminate this MFA gap.' @('Directory Synchronization Accounts role', 'Entra Connect sync service account', 'Hybrid identity sync pipeline')
        }

        # eam-external-user-impact
        if ($Active -and ($AllUsers -or (& $HasAdminRoles $Policy))) {
            $HasCustomFactors = @($Grant.customAuthenticationFactors).Count -gt 0
            $HasEamViaStrength = $false
            $StrengthName = ''
            $ExternalMethods = @()
            $StrengthRef = $Grant.authenticationStrength
            if ($StrengthRef.id -and $Context.AuthStrengths.ContainsKey("$($StrengthRef.id)")) {
                $Resolved = $Context.AuthStrengths["$($StrengthRef.id)"]
                $ExternalMethods = @($Resolved.allowedCombinations | Where-Object { "$_".ToLowerInvariant().Contains('externalauthenticationmethod') })
                if ($ExternalMethods.Count -gt 0) {
                    $HasEamViaStrength = $true
                    $StrengthName = if ($Resolved.displayName) { "$($Resolved.displayName)" } elseif ($StrengthRef.displayName) { "$($StrengthRef.displayName)" } else { 'Unknown' }
                }
            }
            if ($HasCustomFactors -or $HasEamViaStrength) {
                $ExcludeGuestObject = $Policy.conditions.users.excludeGuestsOrExternalUsers
                $ExcludesGuests = ($null -ne $ExcludeGuestObject) -and (@($ExcludeGuestObject.PSObject.Properties).Count -gt 0)
                $EamSource = if ($HasEamViaStrength) { "an Authentication Strength policy (""$StrengthName"") that includes External Authentication Method combinations: $($ExternalMethods -join ', ')" } else { 'custom authentication factors (legacy Custom Controls)' }
                $Detail = if ($ExcludesGuests) {
                    "This policy requires $EamSource for MFA. While guest users appear to be excluded, verify that ALL external identities are covered by the exclusion - B2B direct connect users, service provider accounts, and cross-tenant sync accounts may still be impacted if not explicitly excluded."
                } else {
                    "This policy requires $EamSource for MFA and targets All Users without excluding guest or external users. External users (B2B guests, service providers, managed service accounts) cannot enroll in your organization's third-party MFA provider and will be blocked from accessing resources. Consider excluding external user types or creating a separate policy for guests that uses Entra ID native MFA."
                }
                $Impacted = [System.Collections.Generic.List[string]]::new()
                foreach ($Item in @('B2B guest users', 'External service providers and vendors', 'Cross-tenant collaboration partners', 'Managed service provider (MSP) accounts')) { $Impacted.Add($Item) }
                if ($ExcludesGuests) { $Impacted.Add('Verify: B2B direct connect and cross-tenant sync accounts') }
                if ($HasEamViaStrength) { $Impacted.Add("Auth Strength: ""$StrengthName"" - $($ExternalMethods.Count) external method combination(s)") }
                & $AddResult 'eam-external-user-impact' $Policy $Detail @($Impacted)
            }
        }

        # approved-client-app-retirement (no state gate in the source)
        if ($Controls -contains 'approvedApplication') {
            $HasAppProtection = $Controls -contains 'compliantApplication'
            if ($HasAppProtection -and $Grant.operator -eq 'OR') {
                # compliant migration path
            } elseif ($HasAppProtection -and $Grant.operator -eq 'AND') {
                & $AddResult 'approved-client-app-retirement' $Policy "Policy ""$($Policy.displayName)"" uses both 'Require approved client app' AND 'Require app protection policy' with the AND operator. After the retirement, change the operator to OR so that app protection policy alone is sufficient, as approved client app will stop being enforced." @('Mobile device users on iOS and Android', 'Users accessing M365 apps from mobile devices')
            } else {
                & $AddResult 'approved-client-app-retirement' $Policy "Policy ""$($Policy.displayName)"" uses only the 'Require approved client app' grant control, which is being retired in early March 2026. After retirement, this policy will no longer enforce app-level controls on mobile devices, leaving them unprotected. Migrate to 'Require application protection policy' before the deadline." @('Mobile device users on iOS and Android', 'Users accessing M365 apps from mobile devices', 'Unmanaged BYOD devices')
            }
        }

        # user-risk-password-change-deprecated
        if ($Active -and @($Policy.conditions.userRiskLevels).Count -gt 0 -and $Grant.present -and ($Controls -contains 'passwordChange')) {
            $UsesRiskRemediation = $Controls -contains 'riskRemediation'
            $Tail = if ($UsesRiskRemediation) { "The policy also has 'riskRemediation' - consider removing 'passwordChange' and keeping only 'riskRemediation'." } else { "Replace with 'Require risk remediation' to support all authentication method types." }
            & $AddResult 'user-risk-password-change-deprecated' $Policy "Policy ""$($Policy.displayName)"" uses the legacy 'Require password change' grant control for user risk. This control is deprecated and does not support passwordless users (FIDO2, Windows Hello for Business, External Authentication Methods such as Duo). Passwordless users flagged as high risk will be unable to self-remediate and will remain blocked. $Tail" @('Passwordless users (FIDO2, Windows Hello for Business)', 'External Authentication Method users (Duo, Okta, etc.)', 'High-risk users who cannot complete a password change flow')
        }

        # user-risk-remediation-no-eam-companion (EAM tenant state is not cached by CIPP: reported as unverified)
        if ($Active -and @($Policy.conditions.userRiskLevels).Count -gt 0 -and $Grant.present -and ($Controls -contains 'riskRemediation') -and ($null -ne $Grant.authenticationStrength)) {
            $ScopeNote = "This tenant's External Authentication Method configuration could not be verified (CIPP does not cache the EAM provider state). This finding is shown as a precaution and may not apply if the tenant has no EAM configured."
            & $AddResult 'user-risk-remediation-no-eam-companion' $Policy "Policy ""$($Policy.displayName)"" combines 'Require risk remediation' with an authentication strength object. Authentication strength objects do NOT support External Authentication Methods (EAM) such as Duo, Okta Verify, or Ping. Users enrolled in EAM who are flagged as high risk will be unable to complete the remediation challenge and will remain blocked indefinitely. A companion policy targeting only EAM-enrolled users - using the built-in 'Require MFA' control instead of an auth strength - is required to close this gap. $ScopeNote" @('Users enrolled in External Authentication Methods (Duo, Okta Verify, Ping, etc.)', 'Any tenant using a third-party MFA provider as EAM', 'High-risk EAM users who cannot complete authentication strength challenges')
        }
    }

    $TemplateByExclusion = @{
        'all-resources-exclusion-change'         = "$($Reference.templates.windowsAzureAdBaselineScopes)"
        'user-risk-password-change-deprecated'   = "$($Reference.templates.riskRemediationHigh)"
        'user-risk-remediation-no-eam-companion' = "$($Reference.templates.riskRemediationEam)"
        'approved-client-app-retirement'         = "$($Reference.templates.appProtectionMobile)"
    }

    foreach ($Result in $Results) {
        if ($Result.exclusionId -eq 'all-resources-exclusion-change' -and -not $IncludeAdvisory.IsPresent) { continue }
        $IsPromoted = $Result.severity -in @('critical', 'high')
        if (-not $IsPromoted -and -not $IncludeAdvisory.IsPresent) { continue }
        $SeverityLabel = switch ($Result.severity) {
            'critical' { 'Critical' }
            'high' { 'High' }
            'medium' { 'Medium' }
            default { 'Info' }
        }
        $Params = @{
            Severity         = $SeverityLabel
            Category         = 'MS Learn: Documented Exclusion'
            Title            = $Result.title
            Description      = "$($Result.detail) Reference: $($Result.docUrl)"
            Remediation      = $Result.remediation
            AffectedPolicies = @($Result.policyName)
            RelatedIds       = @($Result.impactedResources)
        }
        if ($TemplateByExclusion.ContainsKey($Result.exclusionId)) { $Params['CaTemplate'] = $TemplateByExclusion[$Result.exclusionId] }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
