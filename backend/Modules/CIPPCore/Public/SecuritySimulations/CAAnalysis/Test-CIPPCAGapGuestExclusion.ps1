function Test-CIPPCAGapGuestExclusion {
    <#
    .SYNOPSIS
        Flags All-users policies that exclude guest or external users, and tenants with no guest coverage at all.
    .DESCRIPTION
        Per policy (any state): a policy targeting All users that excludes GuestsOrExternalUsers, either the simple
        sentinel or the structured excludeGuestsOrExternalUsers object, produces a finding whose severity depends on
        what the policy enforces (security-info registration, block, MFA on all apps, or other) and on whether another
        non-disabled policy covers guests. Tenant-wide: when enabled policies exclude guests and there is neither a
        guest-specific MFA policy nor an All-users MFA policy, a High finding proposes the guest MFA template.
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
    $TypeLabels = $Reference.guestTypeLabels
    $AllKnownTypes = @($Reference.guestTypeOrder | ForEach-Object { "$_" })
    $RegisterSecurityInfo = "$($Reference.registerSecurityInfoAction)"

    $LabelOf = {
        param($TypeName)
        $Label = $TypeLabels.$TypeName
        if ($Label) { "$Label" } else { "$TypeName" }
    }

    foreach ($Policy in @($Context.Policies)) {
        $Users = $Policy.conditions.users
        if (-not (@($Users.includeUsers) -contains 'All')) { continue }

        $ExcludesGuestsSimple = @($Users.excludeUsers) -contains 'GuestsOrExternalUsers'
        $ExcludeObject = $Users.excludeGuestsOrExternalUsers
        $HasStructuredExclusion = ($null -ne $ExcludeObject) -and ($null -ne $ExcludeObject.guestOrExternalUserTypes)
        if (-not $ExcludesGuestsSimple -and -not $HasStructuredExclusion) { continue }

        $ExcludedGuestTypes = @()
        $ExternalTenantScope = ''
        if ($HasStructuredExclusion) {
            $ExcludedGuestTypes = @("$($ExcludeObject.guestOrExternalUserTypes)" -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            $Tenants = $ExcludeObject.externalTenants
            if ("$($Tenants.'@odata.type')".Contains('AllExternalTenants') -or "$($Tenants.membershipKind)" -eq 'all') {
                $ExternalTenantScope = 'all external organizations'
            } elseif ("$($Tenants.membershipKind)" -eq 'enumerated') {
                $ExternalTenantScope = 'specific external organizations'
            }
        }

        $ExcludesAllTypes = $ExcludesGuestsSimple -or (@($AllKnownTypes | Where-Object { $ExcludedGuestTypes -notcontains $_ }).Count -eq 0)

        $Controls = @($Policy.grantControls.builtInControls)
        $RequiresMfa = ($Controls -contains 'mfa') -or ($null -ne $Policy.grantControls.authenticationStrength)
        $Blocks = $Controls -contains 'block'
        $TargetsSecurityRegistration = @($Policy.conditions.applications.includeUserActions) -contains $RegisterSecurityInfo
        $TargetsAllApps = @($Policy.conditions.applications.includeApplications) -contains 'All'

        $HasGuestCoveragePolicy = $false
        foreach ($Other in @($Context.Policies)) {
            if ($Other.id -eq $Policy.id -or $Other.state -eq 'disabled') { continue }
            $OtherUsers = $Other.conditions.users
            $IncludesGuests = (@($OtherUsers.includeUsers) -contains 'GuestsOrExternalUsers') -or ($null -ne $OtherUsers.includeGuestsOrExternalUsers)
            $AllWithoutGuestExclusion = (@($OtherUsers.includeUsers) -contains 'All') -and -not (@($OtherUsers.excludeUsers) -contains 'GuestsOrExternalUsers') -and ($null -eq $OtherUsers.excludeGuestsOrExternalUsers)
            if ($IncludesGuests -or $AllWithoutGuestExclusion) { $HasGuestCoveragePolicy = $true; break }
        }

        if ($ExcludesGuestsSimple) {
            $GuestDescription = 'all guest and external users'
            $ExcludedTypesList = $AllKnownTypes
        } else {
            $GuestDescription = (@($ExcludedGuestTypes | ForEach-Object { & $LabelOf $_ }) -join ', ')
            if ($ExternalTenantScope) { $GuestDescription += " from $ExternalTenantScope" }
            $ExcludedTypesList = $ExcludedGuestTypes
        }

        $ResourceTenantEnforceable = @($ExcludedTypesList | Where-Object { $_ -in @('b2bCollaborationGuest', 'b2bCollaborationMember', 'internalGuest', 'serviceProvider') })
        $HomeTenantOnly = @($ExcludedTypesList | Where-Object { $_ -eq 'b2bDirectConnectUser' })
        $OtherTypes = @($ExcludedTypesList | Where-Object { $_ -eq 'otherExternalUser' })

        $EnforcementDetail = ''
        if ($ResourceTenantEnforceable.Count -gt 0) {
            $EnforcementDetail += "`n`nResource tenant enforceable (excluded from this policy): $(@($ResourceTenantEnforceable | ForEach-Object { & $LabelOf $_ }) -join ', '). These guest types can be required to satisfy MFA in YOUR tenant if you enable MFA trust in Cross-Tenant Access Settings. The guest completes MFA in their home tenant, and you trust that MFA claim via inbound trust settings."
        }
        if ($HomeTenantOnly.Count -gt 0) {
            $EnforcementDetail += "`n`nHome tenant only (excluded from this policy): $(& $LabelOf 'b2bDirectConnectUser'). These users authenticate entirely in their home tenant - your CA policies are NOT enforced. You cannot directly require MFA for B2B Direct Connect users, but you can require their home tenant has equivalent policies via trust settings."
        }
        if ($OtherTypes.Count -gt 0) {
            $EnforcementDetail += "`n`nOther external users (excluded from this policy): $(& $LabelOf 'otherExternalUser'). External identities not covered by B2B collaboration or direct connect."
        }

        if ($TargetsSecurityRegistration) {
            $Severity = if ($HasGuestCoveragePolicy) { 'Medium' } else { 'High' }
            $ContextDetail = "This policy protects security info registration but excludes $GuestDescription. A compromised B2B guest account could register attacker-controlled MFA methods from any location without any controls."
        } elseif ($Blocks -and $TargetsAllApps) {
            $Severity = if ($HasGuestCoveragePolicy) { 'Medium' } else { 'High' }
            $ContextDetail = "This policy blocks access for all apps but excludes $GuestDescription. These external users bypass the block entirely."
        } elseif ($RequiresMfa -and $TargetsAllApps) {
            $Severity = if ($HasGuestCoveragePolicy) { 'Medium' } else { 'High' }
            $ContextDetail = "This policy requires MFA for all apps but excludes $GuestDescription. These external users can access resources without MFA."
        } else {
            $Severity = if ($HasGuestCoveragePolicy) { 'Low' } else { 'Medium' }
            $ContextDetail = "This policy targets all users but excludes $GuestDescription. External users bypass this policy's controls."
        }
        if (-not $HasGuestCoveragePolicy) {
            $ContextDetail += ' No separate policy was found covering guest/external users for comparable controls - this creates an unprotected gap.'
        }

        $TypesText = if ($ExcludesGuestsSimple) {
            ' Excluded types: All guest and external user types.'
        } elseif ($ExcludedGuestTypes.Count -gt 0) {
            " Excluded types: $(@($ExcludedGuestTypes | ForEach-Object { & $LabelOf $_ }) -join ', ')."
        } else { '' }
        $ScopeText = if ($ExternalTenantScope) { " Tenant scope: $ExternalTenantScope." } else { '' }

        $Remediation = if ($HasGuestCoveragePolicy) {
            'A compensating policy was found, but verify it enforces equivalent controls for guest/external users. Ensure the guest policy covers the same apps and actions as this policy. For B2B Collaboration guests (b2bCollaborationGuest, b2bCollaborationMember): enable MFA trust in Cross-Tenant Access Settings (Entra Admin Center > External Identities > Cross-tenant access settings > Inbound access settings > Trust settings > "Trust multi-factor authentication from Azure AD tenants"). For B2B Direct Connect users: your CA policies do not apply - require equivalent policies in the partner tenant via trust settings.'
        } else {
            "Create a dedicated CA policy for guest/external users with appropriate controls, or remove the guest exclusion from this policy. Per CIS and Microsoft Zero Trust guidance, guest accounts should be subject to at least MFA and ideally session time restrictions. If guests must be excluded from this specific policy, create companion policies like ""$($Reference.templates.mfaB2BGuest)"" (for internalGuest, b2bCollaborationMember, b2bDirectConnectUser, serviceProvider) and ""$($Reference.templates.mfaMixedGuests)"" (for b2bCollaborationGuest, otherExternalUser) to ensure coverage. For B2B Collaboration guests: enable MFA trust in Cross-Tenant Access Settings to require guests complete MFA in their home tenant before accessing your resources. For B2B Direct Connect users: these users authenticate in their home tenant only - your CA policies do NOT apply. Require the partner organization has equivalent policies via Cross-Tenant Access Settings trust configuration."
        }

        $TitleCount = if ($ExcludesAllTypes) { 'All' } else { "$($ExcludedGuestTypes.Count)" }
        $TitleSuffix = if ($HasGuestCoveragePolicy) { '' } else { ' - no compensating policy found' }

        $Params = @{
            Severity         = $Severity
            Category         = 'Guest/External User Exclusion'
            Title            = "$TitleCount guest/external user type(s) excluded$TitleSuffix"
            Description      = $ContextDetail + $TypesText + $ScopeText + $EnforcementDetail
            Remediation      = $Remediation
            AffectedPolicies = @($Policy.displayName)
        }
        if (-not $HasGuestCoveragePolicy) { $Params['CaTemplate'] = "$($Reference.templates.mfaB2BGuest)" }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    # tenant-wide guest coverage
    $GuestExcludingPolicies = @($Context.Enabled | Where-Object {
            $U = $_.conditions.users
            if (-not (@($U.includeUsers) -contains 'All')) { return $false }
            (@($U.excludeUsers) -contains 'GuestsOrExternalUsers') -or ($null -ne $U.excludeGuestsOrExternalUsers -and $null -ne $U.excludeGuestsOrExternalUsers.guestOrExternalUserTypes)
        })
    $HasGuestSpecificMfa = @($Context.Enabled | Where-Object {
            $U = $_.conditions.users
            $IncludesGuests = (@($U.includeUsers) -contains 'GuestsOrExternalUsers') -or ($null -ne $U.includeGuestsOrExternalUsers)
            $RequiresMfa = (@($_.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $_.grantControls.authenticationStrength)
            $IncludesGuests -and $RequiresMfa
        }).Count -gt 0
    $HasMfaForAll = @($Context.Enabled | Where-Object {
            (@($_.conditions.users.includeUsers) -contains 'All') -and ((@($_.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $_.grantControls.authenticationStrength))
        }).Count -gt 0

    if ($GuestExcludingPolicies.Count -gt 0 -and -not $HasGuestSpecificMfa -and -not $HasMfaForAll) {
        $Names = @($GuestExcludingPolicies | ForEach-Object { $_.displayName })
        $Params = @{
            Severity         = 'High'
            Category         = 'Guest/External User Coverage'
            Title            = "$($GuestExcludingPolicies.Count) policy(ies) exclude guests but no guest-specific MFA policy exists"
            Description      = "$($GuestExcludingPolicies.Count) enabled policy(ies) exclude guest/external users, and no dedicated policy was found requiring MFA specifically for guests. Guest accounts are a common lateral movement target - B2B collaboration accounts, external partners, and service providers should all be subject to at least MFA controls. Policies excluding guests: $($Names -join ', ')."
            Remediation      = 'Create a dedicated CA policy requiring MFA for all guest/external users across all cloud apps. Include session controls like sign-in frequency (e.g., 1 hour) for guests. Consider requiring compliant devices or approved apps for guest access to sensitive resources.'
            AffectedPolicies = $Names
            CaTemplate       = "$($Reference.templates.mfaGuests)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
