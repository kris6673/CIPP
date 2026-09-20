function Test-CIPPCAGapUncoveredAppExclusions {
    <#
    .SYNOPSIS
        Tenant-wide check for apps excluded from "All resources" policies that no other policy covers.
    .DESCRIPTION
        Collects every app excluded from an enabled All-resources policy and checks whether any other enabled policy
        targets it directly or via All resources without excluding it. Apps with no coverage at all receive zero
        Conditional Access enforcement; one High finding lists them with the policies they are excluded from.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()

    $ExcludedFromAllResources = [ordered]@{}
    foreach ($Policy in @($Context.Enabled)) {
        $Apps = $Policy.conditions.applications
        if (-not (@($Apps.includeApplications) -contains 'All')) { continue }
        foreach ($AppId in @($Apps.excludeApplications)) {
            $Key = "$AppId"
            if (-not $ExcludedFromAllResources.Contains($Key)) { $ExcludedFromAllResources[$Key] = [System.Collections.Generic.List[string]]::new() }
            $ExcludedFromAllResources[$Key].Add($Policy.displayName)
        }
    }

    $Uncovered = [System.Collections.Generic.List[object]]::new()
    foreach ($AppId in @($ExcludedFromAllResources.Keys)) {
        $IsCovered = @($Context.Enabled | Where-Object {
                $Apps = $_.conditions.applications
                if (@($Apps.excludeApplications) -contains $AppId) { return $false }
                if (@($Apps.includeApplications) -contains $AppId) { return $true }
                if (@($Apps.includeApplications) -contains 'All') { return $true }
                $false
            }).Count -gt 0
        if ($IsCovered) { continue }
        $Uncovered.Add([PSCustomObject]@{
                appId        = $AppId
                displayName  = Get-CIPPCAAppDisplayName -AppId $AppId -Context $Context
                excludedFrom = [string[]]@($ExcludedFromAllResources[$AppId])
            })
    }

    if ($Uncovered.Count -gt 0) {
        $AppList = @($Uncovered | ForEach-Object { "- $($_.displayName) ($($_.appId)) - excluded from: $($_.excludedFrom -join ', ') - no dedicated CA policy found for this app" }) -join "`n"
        $Affected = [System.Collections.Generic.List[string]]::new()
        foreach ($Entry in $Uncovered) { foreach ($Name in $Entry.excludedFrom) { if (-not $Affected.Contains($Name)) { $Affected.Add($Name) } } }
        $Params = @{
            Severity         = 'High'
            Category         = 'Application Coverage'
            Title            = "$($Uncovered.Count) app(s) excluded from ""All resources"" policies with no alternative CA coverage"
            Description      = "$($Uncovered.Count) application(s) are excluded from your ""All resources"" Conditional Access policies and have no dedicated policy covering them - they receive zero CA enforcement:`n$AppList`n`nPer Microsoft documentation, when an app is excluded from an ""All resources"" (All cloud apps) policy, it falls completely outside your CA baseline. Microsoft recommends creating a baseline multifactor authentication policy targeting all users and all resources without any resource exclusions. Additionally, some applications cannot be individually targeted in the CA app picker - the only way to protect them is via an ""All resources"" policy. Excluding them creates an uncloseable gap unless you remove the exclusion."
            Remediation      = 'For each excluded app choose one approach. Option A (preferred): remove the app exclusion from your "All resources" policy; if the app needs different controls, create a separate policy targeting that specific app with the appropriate grant controls so the "All resources" policy acts as the baseline floor. Option B: create a dedicated policy that explicitly targets the excluded app by its App ID (Users: All users or the app''s user population; Grant: Require MFA or appropriate controls; enable in report-only first). Some apps cannot be individually targeted and can only be protected via "All resources" - for those, Option A is the only option. See https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-cloud-apps'
            AffectedPolicies = @($Affected)
            RelatedIds       = @($Uncovered | ForEach-Object { $_.appId })
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
