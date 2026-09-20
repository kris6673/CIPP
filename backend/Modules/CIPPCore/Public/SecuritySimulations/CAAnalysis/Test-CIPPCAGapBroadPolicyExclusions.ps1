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
        $BgNote = if ($BgExcluded) { ' (the break-glass exclusion is expected and is not counted here)' } else { '' }

        $Params = @{
            Severity         = if ($AppExclusions -gt 0) { 'Medium' } else { 'Low' }
            Category         = 'Policy Scope'
            Title            = 'Broad policy with exclusions - review for gaps'
            Description      = "This policy targets All Users and All Cloud Apps but has exclusions beyond break-glass. Non-break-glass user/group/role exclusions: $NonBgUserExclusions, App exclusions: $AppExclusions.$BgNote Exclusions create potential bypass paths."
            Remediation      = 'Regularly audit exclusions. Ensure every excluded entity - other than documented break-glass accounts - has a business justification and is covered by a compensating policy.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
