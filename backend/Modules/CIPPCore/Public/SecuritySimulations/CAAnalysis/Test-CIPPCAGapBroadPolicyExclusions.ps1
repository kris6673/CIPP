function Test-CIPPCAGapBroadPolicyExclusions {
    <#
    .SYNOPSIS
        Reminds admins to audit exclusions on enabled All-users / All-apps policies.
    .DESCRIPTION
        For every enabled policy that targets All users and All cloud apps, counts user/group/role exclusions other
        than the detected break-glass account or group, plus app exclusions. App exclusions are a real bypass surface
        (Medium); user/group/role exclusions beyond break-glass are an audit reminder (Low). A policy whose only
        exclusion is the break-glass account produces nothing.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $BreakGlassId = if ($Context.BreakGlass) { "$($Context.BreakGlass.id)".ToLowerInvariant() } else { $null }

    foreach ($Policy in @($Context.Policies)) {
        $Users = $Policy.conditions.users
        $Apps = $Policy.conditions.applications
        $TargetsAllUsers = @($Users.includeUsers) -contains 'All'
        $TargetsAllApps = @($Apps.includeApplications) -contains 'All'
        if (-not ($TargetsAllUsers -and $TargetsAllApps -and $Policy.state -eq 'enabled')) { continue }

        $NonBgUsers = @($Users.excludeUsers | Where-Object { $null -eq $BreakGlassId -or "$_".ToLowerInvariant() -ne $BreakGlassId }).Count
        $NonBgGroups = @($Users.excludeGroups | Where-Object { $null -eq $BreakGlassId -or "$_".ToLowerInvariant() -ne $BreakGlassId }).Count
        $NonBgRoles = @($Users.excludeRoles | Where-Object { $null -eq $BreakGlassId -or "$_".ToLowerInvariant() -ne $BreakGlassId }).Count
        $NonBgUserExclusions = $NonBgUsers + $NonBgGroups + $NonBgRoles
        $AppExclusions = @($Apps.excludeApplications).Count

        if ($NonBgUserExclusions -eq 0 -and $AppExclusions -eq 0) { continue }

        $BgExcluded = $false
        if ($BreakGlassId) {
            $BgExcluded = (@($Users.excludeUsers | Where-Object { "$_".ToLowerInvariant() -eq $BreakGlassId }).Count -gt 0) -or
            (@($Users.excludeGroups | Where-Object { "$_".ToLowerInvariant() -eq $BreakGlassId }).Count -gt 0)
        }
        $BgNote = if ($BgExcluded) { ' (the emergency-access exclusion is expected and is not counted)' } else { '' }

        $Params = @{
            Severity         = if ($AppExclusions -gt 0) { 'Medium' } else { 'Low' }
            Category         = 'Policy scope'
            Title            = 'Tenant-wide policy has exclusions beyond the emergency-access account'
            Description      = "This policy applies to all users and all applications, so every exclusion is a path around it. It exempts $NonBgUserExclusions users, groups or roles and $AppExclusions applications$BgNote."
            Remediation      = 'Confirm that every exclusion has a documented business reason and that another policy still protects what it exempts.'
            AffectedPolicies = @($Policy.displayName)
            DocumentationUrl = 'https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-users-groups'
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
