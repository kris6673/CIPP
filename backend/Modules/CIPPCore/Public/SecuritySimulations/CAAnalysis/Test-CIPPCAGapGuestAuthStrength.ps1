function Test-CIPPCAGapGuestAuthStrength {
    <#
    .SYNOPSIS
        Advises on Cross-Tenant Access Settings when guests are required to satisfy MFA or an authentication strength.
    .DESCRIPTION
        Requiring MFA for guests is best practice, not a weakness, so this is an Info-level operational advisory: guest
        users authenticate in their home tenant and are blocked unless inbound MFA trust is configured. Fires for every
        non-disabled policy that targets guests/external users and requires MFA or an authentication strength; names
        the strength type (phishing-resistant detection reads the tenant's cached authentication-strength catalog).
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
        if ($Policy.state -eq 'disabled') { continue }
        $Users = $Policy.conditions.users
        $Grant = $Policy.grantControls
        $TargetsGuests = (@($Users.includeUsers) -contains 'GuestsOrExternalUsers') -or ($null -ne $Users.includeGuestsOrExternalUsers)
        $RequiresAuthStrength = $null -ne $Grant.authenticationStrength
        $RequiresMfa = @($Grant.builtInControls) -contains 'mfa'
        if (-not $TargetsGuests -or (-not $RequiresAuthStrength -and -not $RequiresMfa)) { continue }

        $StrengthType = 'MFA'
        if ($RequiresAuthStrength) {
            $StrengthName = if ($Grant.authenticationStrength.displayName) { "$($Grant.authenticationStrength.displayName)" } else { 'Unknown' }
            $StrengthType = if (Test-CIPPCAPolicyPhishingResistant -Policy $Policy -Context $Context) { 'Phishing-resistant MFA' } else { "Authentication strength: $StrengthName" }
        }

        $GuestTypes = [System.Collections.Generic.List[string]]::new()
        if ($null -ne $Users.includeGuestsOrExternalUsers) {
            $TypeString = "$($Users.includeGuestsOrExternalUsers.guestOrExternalUserTypes)"
            if ($TypeString.Contains('b2bCollaborationGuest')) { $GuestTypes.Add('B2B Collaboration guests') }
            if ($TypeString.Contains('b2bCollaborationMember')) { $GuestTypes.Add('B2B Collaboration members') }
            if ($TypeString.Contains('b2bDirectConnectUser')) { $GuestTypes.Add('B2B Direct Connect users') }
            if ($TypeString.Contains('internalGuest')) { $GuestTypes.Add('Internal guests') }
            if ($TypeString.Contains('serviceProvider')) { $GuestTypes.Add('Service provider users') }
        }
        $GuestTypeText = if ($GuestTypes.Count -gt 0) { $GuestTypes -join ', ' } else { 'All guest/external users' }

        $PhishingNote = if ($RequiresAuthStrength -and $StrengthType -eq 'Phishing-resistant MFA') {
            ' Phishing-resistant MFA note: very few tenants have phishing-resistant MFA deployed. If you require phishing-resistant MFA for guests, ensure their home tenant supports FIDO2, Windows Hello for Business, or Certificate-Based Authentication, AND that you trust those MFA claims inbound.'
        } else { '' }

        $Params = @{
            Severity         = 'Info'
            Category         = 'Guest Authentication Requirements'
            Title            = "Guest users required to satisfy $StrengthType - may need Cross-Tenant Access Settings"
            Description      = "This policy requires $StrengthType for $GuestTypeText. Important: guest users authenticate in their home tenant, not in your resource tenant. For guests to satisfy this policy requirement you must 1) enable MFA trust in Cross-Tenant Access Settings for the guest's home tenant, 2) the guest must have already completed MFA in their home tenant, and 3) the home tenant must present an MFA claim that satisfies your authentication strength requirement. B2B Collaboration guests can satisfy MFA requirements if their home tenant presents MFA claims AND you trust those claims in Cross-Tenant Access Settings. B2B Direct Connect users authenticate entirely in their home tenant - your policy requirements are not directly enforced, but you can require that their home tenant has equivalent policies.$PhishingNote Without Cross-Tenant Access MFA trust enabled, guest users will be blocked even if they completed MFA in their home tenant."
            Remediation      = "Review Cross-Tenant Access Settings (Entra Admin Center > External Identities > Cross-tenant access settings > Inbound access settings) and enable MFA trust for each organization whose guests need access (default settings for all external organizations, or organization-specific settings for specific partner tenants). Under B2B collaboration trust settings check ""Trust multi-factor authentication from Azure AD tenants"" (optionally also trust compliant and hybrid joined devices). Validate the guest sign-in flow with a guest from a trusted tenant. If only specific guests need $StrengthType, scope the includeGuestsOrExternalUsers condition to those guest types. Use report-only mode first to identify which guests would be blocked."
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
