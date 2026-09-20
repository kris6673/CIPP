function Test-CIPPCAGapMicrosoftManagedPolicy {
    <#
    .SYNOPSIS
        Surfaces Microsoft-managed Conditional Access policies detected by their display names.
    .DESCRIPTION
        Per policy: a disabled policy whose name matches a Microsoft-managed policy pattern gets an Info finding
        pointing at the MC1246002 Baseline Security Mode phantom-draft issue. Tenant-wide: one Info finding lists every
        managed policy detected, with how many are report-only or disabled, so overlap with custom policies is reviewed.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $Keywords = @($Context.Data.Reference.managedPolicyPatterns | ForEach-Object { "$($_.keyword)".ToLowerInvariant() })

    $IsManaged = {
        param($P)
        $Name = "$($P.displayName)".ToLowerInvariant()
        foreach ($Keyword in $Keywords) { if ($Name.Contains($Keyword)) { return $true } }
        $false
    }

    foreach ($Policy in @($Context.Policies)) {
        if (-not (& $IsManaged $Policy) -or $Policy.state -ne 'disabled') { continue }
        $Params = @{
            Severity         = 'Info'
            Category         = 'Microsoft-Managed Policies'
            Title            = 'MC1246002: Disabled managed policy - possible Baseline Security Mode phantom draft'
            Description      = 'Between Nov 2025 and Feb 2026, Baseline Security Mode accidentally created disabled draft CA policies in some tenants (MC1246002). These phantom policies are not a security risk - Microsoft is removing unintended drafts automatically. If you did not intentionally disable this managed policy, this is likely the cause.'
            Remediation      = 'No action required if this was created by Baseline Security Mode. Microsoft will clean up phantom drafts. If you intentionally disabled this managed policy, consider enabling it in report-only mode to evaluate its impact. See: https://learn.microsoft.com/entra/identity/conditional-access/managed-policies'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    $ManagedPolicies = @($Context.Policies | Where-Object { & $IsManaged $_ })
    if ($ManagedPolicies.Count -gt 0) {
        $ReportOnlyCount = @($ManagedPolicies | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' }).Count
        $DisabledCount = @($ManagedPolicies | Where-Object { $_.state -eq 'disabled' }).Count
        $Names = @($ManagedPolicies | ForEach-Object { $_.displayName })
        $Detail = "Detected $($ManagedPolicies.Count) Microsoft-managed Conditional Access policy(ies): $($Names -join ', '). "
        if ($ReportOnlyCount -gt 0) { $Detail += "$ReportOnlyCount are in report-only mode. " }
        if ($DisabledCount -gt 0) { $Detail += "$DisabledCount are disabled. " }
        $Detail += 'Microsoft-managed policies auto-adapt to tenant changes and cannot be renamed or deleted. They may overlap with your custom policies - review for redundancy or conflicts. '

        $Params = @{
            Severity         = 'Info'
            Category         = 'Microsoft-Managed Policies'
            Title            = "$($ManagedPolicies.Count) Microsoft-managed CA policy(ies) detected"
            Description      = $Detail
            Remediation      = 'Review Microsoft-managed policies alongside your custom policies for overlap. Consider enabling managed policies that are in report-only mode for defense-in-depth. You can exclude users from managed policies but cannot rename or delete them. See: https://learn.microsoft.com/entra/identity/conditional-access/managed-policies'
            AffectedPolicies = $Names
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
