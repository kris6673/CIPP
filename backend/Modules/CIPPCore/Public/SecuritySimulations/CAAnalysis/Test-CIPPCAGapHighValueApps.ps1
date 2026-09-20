function Test-CIPPCAGapHighValueApps {
    <#
    .SYNOPSIS
        Tenant-wide check that high-value Microsoft applications are covered by an MFA or block policy.
    .DESCRIPTION
        For Azure Management, Azure Portal, Microsoft Graph, Exchange Online and SharePoint Online: covered when an
        enabled policy includes the app (directly or via All apps) without excluding it and requires MFA, an
        authentication strength, or blocks. Uncovered apps produce one finding: Critical when any critical-risk app is
        uncovered, otherwise High.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Unprotected = [System.Collections.Generic.List[object]]::new()

    foreach ($App in @($Context.Data.HighValueApps)) {
        $AppId = "$($App.appId)"
        $IsCovered = @($Context.Enabled | Where-Object {
                $Apps = $_.conditions.applications
                $IncludesAll = @($Apps.includeApplications) -contains 'All'
                $IncludesSpecific = @($Apps.includeApplications) -contains $AppId
                $IsExcluded = @($Apps.excludeApplications) -contains $AppId
                $C = @($_.grantControls.builtInControls)
                $HasMfaOrBlock = ($C -contains 'mfa') -or ($C -contains 'block') -or ($null -ne $_.grantControls.authenticationStrength)
                ($IncludesAll -or $IncludesSpecific) -and -not $IsExcluded -and $HasMfaOrBlock
            }).Count -gt 0
        if (-not $IsCovered) { $Unprotected.Add($App) }
    }

    if ($Unprotected.Count -gt 0) {
        $CriticalApps = @($Unprotected | Where-Object { $_.risk -eq 'critical' })
        $AppLines = @($Unprotected | ForEach-Object { "- $($_.name) ($($_.description)) - $("$($_.risk)".ToUpperInvariant()) RISK. App ID: $($_.appId)" }) -join "`n"
        $CriticalSuffix = if ($CriticalApps.Count -gt 0) { " ($($CriticalApps.Count) critical)" } else { '' }
        $Params = @{
            Severity    = if ($CriticalApps.Count -gt 0) { 'Critical' } else { 'High' }
            Category    = 'Application Coverage'
            Title       = "$($Unprotected.Count) high-value application(s) lack MFA/blocking policies$CriticalSuffix"
            Description = "$($Unprotected.Count) high-value Microsoft application(s) do not have Conditional Access policies requiring MFA, authentication strength, or blocking access. These applications provide access to critical tenant resources and should have the strongest protection. Unprotected applications:`n$AppLines`n`nRisk by application: Azure Management / Azure Portal give full control over subscription resources (backdoors, data exfiltration, crypto miners); Microsoft Graph gives API access to all M365 data (mail, files, users, groups) and can be used to escalate privileges; Exchange Online exposes corporate email (business email compromise); SharePoint/OneDrive exposes corporate documents. Without MFA/strong auth on these apps, a compromised password grants full access to your tenant's most sensitive resources."
            Remediation = 'Create Conditional Access policies for high-value applications. Azure Management / Azure Portal: All users, cloud app "Azure Management" (Portal, ARM, PowerShell, CLI), grant phishing-resistant MFA, sign-in frequency Every time, exclude break-glass only. Office 365 (Exchange, SharePoint, Teams): All users, cloud app "Office 365", grant Require MFA, consider device compliance or approved client app. Microsoft Graph: All users, grant MFA + compliant device, sign-in frequency Every time. Best practice: use "All cloud apps" policies for baseline MFA, then layer application-specific policies with stronger controls for high-value resources.'
            RelatedIds  = @($Unprotected | ForEach-Object { "$($_.appId)" })
            CaTemplate  = "$($Context.Data.Reference.templates.mfaAllUsers)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
