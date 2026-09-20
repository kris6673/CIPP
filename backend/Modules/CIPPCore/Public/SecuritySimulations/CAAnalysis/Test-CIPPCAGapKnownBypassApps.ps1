function Test-CIPPCAGapKnownBypassApps {
    <#
    .SYNOPSIS
        Reviews every non-FOCI app excluded from a policy and cross-references it with the known bypass-app catalog.
    .DESCRIPTION
        One consolidated "App Exclusion" finding per policy that excludes apps (FOCI apps are covered by
        Test-CIPPCAGapFociExclusion). Each excluded app is resolved against the curated app descriptions, the tenant's
        cached service principals, the known Conditional Access bypass apps (Azure CLI, Azure PowerShell, Device
        Management Client, ...) and the built-in application-group aliases. The finding is High when any exclusion is a
        known bypass app or carries a critical/high exclusion risk, otherwise Medium. All policy states are evaluated.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Data = $Context.Data

    foreach ($Policy in @($Context.Policies)) {
        $Details = [System.Collections.Generic.List[object]]::new()
        $HasHighRisk = $false

        foreach ($AppId in @($Policy.conditions.applications.excludeApplications)) {
            $Key = "$AppId".ToLowerInvariant()
            if ($null -ne $Data.FociById[$Key]) { continue }

            $ServicePrincipal = $Context.ServicePrincipals[$Key]
            $BypassApp = $Data.BypassAppById[$Key]
            $Description = $Data.AppDescriptionById[$Key]
            $Alias = $Data.AppGroupAliases[$Key]

            $Name = $Description.displayName ?? $ServicePrincipal.displayName ?? $BypassApp.displayName ?? $Alias.displayName ?? "$AppId"
            $ServicePrincipalPurpose = if ($ServicePrincipal) { "Service principal: $($ServicePrincipal.servicePrincipalType ?? 'Application')" } else { 'Unrecognized app ID - not found in service principal list or known app catalog.' }
            $Purpose = $Description.purpose ?? $BypassApp.description ?? $Alias.purpose ?? $ServicePrincipalPurpose
            $Reason = $Description.commonExclusionReason ?? 'No documented exclusion reason. Review whether this exclusion is necessary.'
            $Risk = $Description.exclusionRisk ?? $(if ($BypassApp) { 'high' } else { 'medium' })

            if ($Risk -in @('critical', 'high') -or $null -ne $BypassApp) { $HasHighRisk = $true }

            $Details.Add([PSCustomObject]@{
                    appId           = "$AppId"
                    displayName     = "$Name"
                    purpose         = "$Purpose"
                    exclusionReason = "$Reason"
                    risk            = "$Risk"
                })
        }

        if ($Details.Count -eq 0) { continue }

        $HighRiskApps = @($Details | Where-Object { $_.risk -in @('critical', 'high') })
        $AppNames = @($Details | ForEach-Object { $_.displayName }) -join ', '
        $RiskSummary = if ($HighRiskApps.Count -gt 0) {
            "High-risk exclusions: $(@($HighRiskApps | ForEach-Object { $_.displayName }) -join ', ')."
        } else {
            'All exclusions are low/medium risk - see the per-app details below.'
        }
        $PerApp = @($Details | ForEach-Object { "- $($_.displayName) ($($_.appId)) [$($_.risk) risk]: $($_.purpose) Exclusion reason: $($_.exclusionReason)" }) -join "`n"
        $HighRiskSuffix = if ($HighRiskApps.Count -gt 0) { " ($($HighRiskApps.Count) high-risk)" } else { '' }

        $Params = @{
            Severity         = if ($HasHighRisk) { 'High' } else { 'Medium' }
            Category         = 'App Exclusion'
            Title            = "$($Details.Count) app(s) excluded from this policy$HighRiskSuffix"
            Description      = "This policy excludes: $AppNames. Each excluded app bypasses the policy's controls. $RiskSummary`n`n$PerApp"
            Remediation      = 'Review each exclusion and ensure it has a documented business justification. Consider using separate targeted policies with reduced controls instead of excluding apps.'
            AffectedPolicies = @($Policy.displayName)
            RelatedIds       = @($Details | ForEach-Object { $_.appId })
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
