function Test-CIPPCAGapUserAgentBypass {
    <#
    .SYNOPSIS
        Detects platform- and client-type-specific MFA policies that can be bypassed by spoofing the user agent.
    .DESCRIPTION
        Per policy (non-disabled): an MFA or device-compliance policy scoped to specific device platforms can be
        bypassed by presenting an unrecognized platform; this is High unless an enabled tenant-wide policy blocks
        unknown platforms (then Info, naming the companion policy). An MFA policy that filters client app types but
        omits browser or mobileAppsAndDesktopClients is Medium. Tenant-wide: when any enabled MFA policy is platform
        specific and nothing blocks unknown platforms, a High finding proposes the block-unsupported-platforms template.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()

    $IsBlockUnknownPlatformsPolicy = {
        param($P)
        $Platforms = $P.conditions.platforms
        ($P.state -eq 'enabled') -and
        ($null -ne $Platforms) -and
        (@($P.grantControls.builtInControls) -contains 'block') -and
        (@($Platforms.includePlatforms) -contains 'all') -and
        (@($Platforms.excludePlatforms).Count -gt 0) -and
        (@($P.conditions.users.includeUsers) -contains 'All') -and
        (@($P.conditions.applications.includeApplications) -contains 'All')
    }

    foreach ($Policy in @($Context.Policies)) {
        if ($Policy.state -eq 'disabled') { continue }

        $Platforms = $Policy.conditions.platforms
        $Controls = @($Policy.grantControls.builtInControls)
        $ClientAppTypes = @($Policy.conditions.clientAppTypes)
        $RequiresMfa = ($Controls -contains 'mfa') -or ($null -ne $Policy.grantControls.authenticationStrength)
        $RequiresCompliance = ($Controls -contains 'compliantDevice') -or ($Controls -contains 'domainJoinedDevice')

        # 1) platform-specific policies
        if ($null -ne $Platforms -and @($Platforms.includePlatforms).Count -gt 0 -and -not (@($Platforms.includePlatforms) -contains 'all')) {
            $Targeted = @($Platforms.includePlatforms) -join ', '
            if ($RequiresMfa -or $RequiresCompliance) {
                $Companion = $null
                foreach ($Other in @($Context.Policies)) {
                    if ($Other.id -ne $Policy.id -and (& $IsBlockUnknownPlatformsPolicy $Other)) { $Companion = $Other; break }
                }
                if ($Companion) {
                    $Params = @{
                        Severity         = 'Info'
                        Category         = 'User-Agent Bypass'
                        Title            = "Platform condition targets $Targeted - unknown-platform bypass covered by companion policy"
                        Description      = "This policy enforces controls only for platforms: $Targeted. On its own that would allow a user-agent-spoofing bypass to an unrecognized platform, but $($Companion.displayName) blocks access from unknown/unsupported platforms tenant-wide, which closes that path."
                        Remediation      = "No action required for the unknown-platform bypass - it is covered by $($Companion.displayName). Do verify that any recognized platforms you intentionally do not target here (e.g. iOS/Android) are covered by another policy such as app protection / MAM."
                        AffectedPolicies = @($Policy.displayName, $Companion.displayName)
                    }
                } else {
                    $Params = @{
                        Severity         = 'High'
                        Category         = 'User-Agent Bypass'
                        Title            = "Platform condition only targets $Targeted - user-agent spoofing risk"
                        Description      = "This policy enforces controls only for platforms: $Targeted. An attacker can spoof their user-agent string to appear as an unrecognized platform (e.g. Linux, ChromeOS, or a custom UA) to bypass this policy entirely. Tools like MFASweep actively exploit this gap by enumerating user-agent strings."
                        Remediation      = 'Change the platform condition to target "All platforms" instead of specific platforms, or create a companion policy that blocks access from unknown/unsupported device platforms (supplementary CA hardening). This eliminates the user-agent spoofing bypass path.'
                        AffectedPolicies = @($Policy.displayName)
                        CaTemplate       = "$($Context.Data.Reference.templates.blockUnsupportedPlatforms)"
                    }
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }

        # 2) client app type coverage gaps
        $HasClientFilter = ($ClientAppTypes.Count -gt 0) -and -not ($ClientAppTypes -contains 'all')
        if ($HasClientFilter) {
            $HasBrowser = $ClientAppTypes -contains 'browser'
            $HasMobile = $ClientAppTypes -contains 'mobileAppsAndDesktopClients'
            if ($RequiresMfa -and (-not $HasBrowser -or -not $HasMobile)) {
                $Missing = [System.Collections.Generic.List[string]]::new()
                if (-not $HasBrowser) { $Missing.Add('browser') }
                if (-not $HasMobile) { $Missing.Add('mobileAppsAndDesktopClients') }
                $MissingText = $Missing -join ', '
                $Params = @{
                    Severity         = 'Medium'
                    Category         = 'User-Agent Bypass'
                    Title            = "MFA policy does not cover client app type(s): $MissingText"
                    Description      = "This policy requires MFA but only targets client app types: $($ClientAppTypes -join ', '). Missing coverage for: $MissingText. An attacker can use a client matching the uncovered app type to bypass MFA. MFASweep tests both browser and desktop/mobile client types to find these gaps."
                    Remediation      = 'Ensure MFA policies cover all modern client app types: both "browser" and "mobileAppsAndDesktopClients". Use a separate policy to block legacy auth (exchangeActiveSync + other).'
                    AffectedPolicies = @($Policy.displayName)
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }
    }

    # tenant-wide
    $BlocksUnknownPlatforms = @($Context.Enabled | Where-Object {
            $Platforms = $_.conditions.platforms
            ($null -ne $Platforms) -and (@($Platforms.includePlatforms) -contains 'all') -and (@($Platforms.excludePlatforms).Count -gt 0) -and (@($_.grantControls.builtInControls) -contains 'block')
        }).Count -gt 0
    $MfaPoliciesUseSpecificPlatforms = @($Context.Enabled | Where-Object {
            $Platforms = $_.conditions.platforms
            if ($null -eq $Platforms -or @($Platforms.includePlatforms).Count -eq 0) { return $false }
            $RequiresMfa = (@($_.grantControls.builtInControls) -contains 'mfa') -or ($null -ne $_.grantControls.authenticationStrength)
            $RequiresMfa -and -not (@($Platforms.includePlatforms) -contains 'all')
        }).Count -gt 0

    if ($MfaPoliciesUseSpecificPlatforms -and -not $BlocksUnknownPlatforms) {
        $Params = @{
            Severity    = 'High'
            Category    = 'User-Agent Bypass'
            Title       = 'MFA policies use platform-specific conditions without blocking unknown platforms'
            Description = 'One or more MFA policies target specific device platforms (e.g. iOS, Android, Windows) instead of all platforms, AND no policy blocks unknown or unsupported device platforms. This creates a gap exploitable by tools like MFASweep, which enumerate user-agent strings to find platforms where MFA is not enforced. An attacker can spoof a Linux, ChromeOS, or unrecognized user-agent to bypass MFA entirely.'
            Remediation = "Either change all MFA policies to target 'All platforms' (recommended), or create a companion policy that blocks access from unknown/unsupported device platforms (supplementary CA hardening). This closes the user-agent spoofing bypass path that MFASweep exploits."
            CaTemplate  = "$($Context.Data.Reference.templates.blockUnsupportedPlatforms)"
        }
        $Findings.Add((New-CIPPCAGapFinding @Params))
    }

    @($Findings)
}
