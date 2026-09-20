function Test-CIPPCAGapLegacyAuth {
    <#
    .SYNOPSIS
        Checks that legacy authentication (Exchange ActiveSync / Other clients) is blocked.
    .DESCRIPTION
        Tenant-wide: when no enabled policy blocks the legacy client types, a Critical finding is
        raised with the block-legacy-authentication template as the fix. Only then does each
        enabled policy that targets the legacy client types without blocking them get a Medium
        finding - once a block policy exists those policies are moot, and a tenant that blocks
        legacy auth must never read as if it did not. Disabled policies are ignored.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()

    $TargetsLegacy = {
        param($P)
        $Types = @($P.conditions.clientAppTypes)
        ($Types -contains 'exchangeActiveSync') -or ($Types -contains 'other')
    }

    $BlocksLegacy = @($Context.Enabled | Where-Object { (& $TargetsLegacy $_) -and (@($_.grantControls.builtInControls) -contains 'block') }).Count -gt 0
    if ($BlocksLegacy) { return @() }

    $Params = @{
        Severity    = 'Critical'
        Category    = 'Legacy Auth'
        Title       = 'No policy blocks legacy authentication'
        Description = 'No enabled policy was found that blocks legacy authentication protocols. Legacy auth cannot support MFA and is a top attack vector.'
        Remediation = 'Create a policy that blocks Exchange ActiveSync and Other client types for All Users.'
        CaTemplate  = "$($Context.Data.Reference.templates.blockLegacyAuth)"
    }
    $Findings.Add((New-CIPPCAGapFinding @Params))

    foreach ($Policy in @($Context.Policies)) {
        if ($Policy.state -eq 'disabled') { continue }
        if (-not (& $TargetsLegacy $Policy)) { continue }
        if (@($Policy.grantControls.builtInControls) -contains 'block') { continue }
        $Params = @{
            Severity         = 'Medium'
            Category         = 'Legacy Authentication'
            Title            = 'Legacy auth clients targeted but not blocked'
            Description      = 'This policy targets legacy authentication clients (Exchange ActiveSync / Other) but does not block them. Legacy auth cannot support MFA, so the grant it applies cannot be met - block these clients explicitly instead.'
            Remediation      = 'Block legacy authentication. Legacy auth protocols cannot perform MFA and are a common attack vector for password spray and credential stuffing attacks.'
            AffectedPolicies = @($Policy.displayName)
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
