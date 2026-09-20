function Test-CIPPCAGapFociExclusion {
    <#
    .SYNOPSIS
        Flags policies that exclude an app from the FOCI (Family of Client IDs) token-sharing family.
    .DESCRIPTION
        FOCI apps share refresh tokens, so excluding one Microsoft client (Teams, Office, Outlook Mobile, ...) from a
        policy effectively excludes every other family member. Every excluded FOCI app produces one Critical finding,
        regardless of the policy state, listing the first eight family members that inherit the exclusion.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $FociApps = @($Context.Data.FociApps)

    foreach ($Policy in @($Context.Policies)) {
        foreach ($AppId in @($Policy.conditions.applications.excludeApplications)) {
            $Key = "$AppId".ToLowerInvariant()
            $App = $Context.Data.FociById[$Key]
            if ($null -eq $App) { continue }

            $Family = @($FociApps | Where-Object { "$($_.appId)".ToLowerInvariant() -ne $Key })
            $FamilyNames = @($Family | Select-Object -First 8 | ForEach-Object { "$($_.displayName)" })
            $Overflow = if ($Family.Count -gt 8) { '...' } else { '' }

            $Params = @{
                Severity         = 'Critical'
                Category         = 'FOCI Token Sharing'
                Title            = "Excluded FOCI app ""$($App.displayName)"" shares tokens with $($Family.Count) other apps"
                Description      = """$($App.displayName)"" ($AppId) is excluded from this policy and belongs to the FOCI (Family of Client IDs) family. " +
                'FOCI apps share refresh tokens, meaning any FOCI app can obtain an access token for any other FOCI family member. ' +
                "Excluding one effectively excludes ALL: $($FamilyNames -join ', ')$Overflow."
                Remediation      = 'Remove the exclusion or accept that ALL 45+ FOCI family apps are effectively excluded. ' +
                'Consider targeting specific apps in a separate policy instead of excluding from a broad policy.'
                AffectedPolicies = @($Policy.displayName)
                RelatedIds       = @($Family | ForEach-Object { "$($_.appId)" })
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }
    }

    @($Findings)
}
