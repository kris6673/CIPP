function Test-CIPPCAGapResourceExclusionBypass {
    <#
    .SYNOPSIS
        Tenant-wide check for "All resources" policies with app exclusions affected by Low-Privilege Scope Enforcement.
    .DESCRIPTION
        Until 2026, excluding any app from an All-resources policy silently exempted low-privilege scopes (User.Read,
        openid, profile, email, offline_access, People.Read) from enforcement. Microsoft now routes those scopes to the
        Windows Azure Active Directory (Azure AD Graph) enforcement audience. This emits one rollup finding across every
        enabled All-resources policy with exclusions: Info when an enabled policy already targets Azure AD Graph
        explicitly, otherwise Medium with the baseline-scopes template as the fix.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $AzureAdGraph = "$($Context.Data.Reference.windowsAzureAdResource)"

    $PoliciesWithExclusions = @($Context.Enabled | Where-Object {
            $Apps = $_.conditions.applications
            (@($Apps.includeApplications) -contains 'All') -and (@($Apps.excludeApplications).Count -gt 0)
        })
    if ($PoliciesWithExclusions.Count -eq 0) { return @($Findings) }

    $Names = @($PoliciesWithExclusions | ForEach-Object { $_.displayName })
    $TotalExclusions = 0
    foreach ($Policy in $PoliciesWithExclusions) { $TotalExclusions += @($Policy.conditions.applications.excludeApplications).Count }
    $HasAzureAdGraphPolicy = @($Context.Enabled | Where-Object { @($_.conditions.applications.includeApplications | Where-Object { "$_".ToLowerInvariant() -eq $AzureAdGraph }).Count -gt 0 }).Count -gt 0

    $CoverageNote = if ($HasAzureAdGraphPolicy) {
        ' You have a policy explicitly targeting Azure AD Graph, which provides coverage for the enforcement audience.'
    } else {
        ' No policy explicitly targets Azure AD Graph. If your "All resources" policies have exclusions but do not cover the Azure AD Graph resource, the enforcement change may cause unexpected CA challenges for apps that only request low-privilege scopes. Review and test before the rollout completes.'
    }

    $Params = @{
        Severity         = if ($HasAzureAdGraphPolicy) { 'Info' } else { 'Medium' }
        Category         = 'Low-Privilege Scope Enforcement'
        Title            = "$($PoliciesWithExclusions.Count) ""All resources"" policy(ies) with exclusions - affected by March 2026 enforcement change"
        Description      = "$($PoliciesWithExclusions.Count) enabled policy(ies) target ""All resources"" with a combined $TotalExclusions app exclusion(s): $($Names -join ', '). Microsoft is rolling out a behavioral change (March-June 2026) that affects these policies. Previously, low-privilege scopes (User.Read, openid, profile, email, offline_access, People.Read) were automatically exempt from CA enforcement when ANY resource was excluded. This created a bypass path where apps could read directory data without meeting policy controls. What's changing: these scopes are now mapped to Azure AD Graph (Windows Azure Active Directory, ID: $AzureAdGraph) as the enforcement audience, so any ""All resources"" policy - even with exclusions - will enforce on these scopes. Confidential client apps that were excluded and relied on low-privilege scopes had an even broader set of unprotected scopes (User.Read.All, User.ReadBasic.All, People.Read.All, GroupMember.Read.All, Member.Read.Hidden); those will now also face CA enforcement, closing the directory enumeration bypass.$CoverageNote"
        Remediation      = "1) Remove resource exclusions where possible - Microsoft recommends ""All resources"" policies with NO exclusions as the baseline; create separate, less-restrictive policies for apps that need exemptions. 2) If exclusions cannot be removed immediately, create a report-only policy targeting Azure AD Graph ($AzureAdGraph) with the same controls to preview impact. 3) Review apps requesting only low-privilege scopes in the sign-in logs (resource ""Windows Azure Active Directory""). 4) Update custom apps that only request openid/profile/User.Read and are not designed to handle CA claims challenges. 5) Consider a dedicated policy targeting the Azure AD Graph resource for granular control. See https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-cloud-apps#new-conditional-access-behavior-when-an-all-resources-policy-has-a-resource-exclusion"
        AffectedPolicies = $Names
        RelatedIds       = @($AzureAdGraph)
    }
    if (-not $HasAzureAdGraphPolicy) { $Params['CaTemplate'] = "$($Context.Data.Reference.templates.windowsAzureAdBaselineScopes)" }
    $Findings.Add((New-CIPPCAGapFinding @Params))

    @($Findings)
}
