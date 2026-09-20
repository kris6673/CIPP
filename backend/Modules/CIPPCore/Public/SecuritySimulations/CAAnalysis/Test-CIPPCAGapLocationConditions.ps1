function Test-CIPPCAGapLocationConditions {
    <#
    .SYNOPSIS
        Reviews the named locations each non-disabled policy references.
    .DESCRIPTION
        Four checks per policy with a location condition: (1) a referenced named location explicitly marked not
        trusted (Medium); (2) the policy uses "All trusted locations" while IP-range named locations in the tenant are
        not trusted, so they silently fall outside the trusted set (High; country locations cannot be trusted and are
        ignored); (3) a referenced location ID that no longer exists (Medium); (4) a referenced country location with
        no countries configured, which never matches (High).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $CountryType = '#microsoft.graph.countryNamedLocation'

    foreach ($Policy in @($Context.Policies)) {
        $Locations = $Policy.conditions.locations
        if ($null -eq $Locations -or $Policy.state -eq 'disabled') { continue }

        $Include = @($Locations.includeLocations)
        $Exclude = @($Locations.excludeLocations)
        $UsesAllTrusted = ($Include -contains 'AllTrusted') -or ($Exclude -contains 'AllTrusted')

        $AllRefs = [System.Collections.Generic.List[string]]::new()
        foreach ($Id in $Include) { $AllRefs.Add("$Id") }
        foreach ($Id in $Exclude) { $AllRefs.Add("$Id") }
        $Sentinels = @('AllTrusted', 'All')

        # 1) untrusted named locations referenced directly
        foreach ($LocationId in $AllRefs) {
            if ($LocationId -in $Sentinels) { continue }
            $Location = $Context.NamedLocationById[$LocationId]
            if ($null -ne $Location -and $Location.isTrusted -eq $false) {
                $Params = @{
                    Severity         = 'Medium'
                    Category         = 'Location Configuration'
                    Title            = "Named location ""$($Location.displayName)"" is not marked as trusted"
                    Description      = "The named location ""$($Location.displayName)"" used in this policy is not marked as trusted. If this policy also references ""All trusted locations"", this location will NOT be included in the trusted set and users from this location may be unexpectedly blocked or challenged."
                    Remediation      = "Mark ""$($Location.displayName)"" as trusted in Entra ID if it represents a known-good network, or ensure the policy logic handles untrusted locations as intended."
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($LocationId)
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }

        # 2) "All trusted locations" while some IP-range locations are untrusted
        if ($UsesAllTrusted) {
            $Untrusted = @($Context.NamedLocations | Where-Object { -not $_.isTrusted -and "$($_.'@odata.type')" -ne $CountryType })
            if ($Untrusted.Count -gt 0) {
                $Names = @($Untrusted | ForEach-Object { "$($_.displayName)" }) -join ', '
                $Params = @{
                    Severity         = 'High'
                    Category         = 'Location Configuration'
                    Title            = "Policy uses ""All trusted locations"" but $($Untrusted.Count) location(s) are NOT trusted"
                    Description      = "This policy conditions on ""All trusted locations"" but the following named location(s) are not marked as trusted and will be EXCLUDED from the trusted set: $Names. Users signing in from these locations will not be recognized as coming from a trusted location, which may cause accidental lockouts or unexpected MFA prompts."
                    Remediation      = 'Review each untrusted named location in Entra ID > Protection > Conditional Access > Named locations. Mark locations as trusted if they represent corporate offices, VPNs, or other known-good networks. If a location should not be trusted, ensure this policy''s behavior is correct for non-trusted traffic.'
                    AffectedPolicies = @($Policy.displayName)
                    RelatedIds       = @($Untrusted | ForEach-Object { "$($_.id)" })
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }

        # 3) orphaned references
        foreach ($LocationId in $AllRefs) {
            if ($LocationId -in $Sentinels) { continue }
            if ($Context.NamedLocationById.ContainsKey($LocationId)) { continue }
            $Params = @{
                Severity         = 'Medium'
                Category         = 'Location Configuration'
                Title            = 'Policy references a deleted or missing named location'
                Description      = "This policy references named location ID ""$LocationId"" which does not exist. The location may have been deleted. This stale reference will never match any traffic, which could silently change the policy's effective behavior - potentially blocking or allowing access unintentionally."
                Remediation      = 'Remove the stale location reference from this policy and replace it with a valid named location if needed.'
                AffectedPolicies = @($Policy.displayName)
                RelatedIds       = @($LocationId)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }

        # 4) country locations with no countries
        foreach ($LocationId in $AllRefs) {
            if ($LocationId -in $Sentinels) { continue }
            $Location = $Context.NamedLocationById[$LocationId]
            if ($null -eq $Location) { continue }
            if ("$($Location.'@odata.type')" -ne $CountryType) { continue }
            if (@($Location.countriesAndRegions | Where-Object { $_ }).Count -gt 0) { continue }
            $Params = @{
                Severity         = 'High'
                Category         = 'Location Configuration'
                Title            = "Country location ""$($Location.displayName)"" has no countries defined"
                Description      = "This policy references the country-based named location ""$($Location.displayName)"" which has zero countries configured. The location condition will never match any traffic, which could create a security gap (if used as an include condition) or make the exclude condition meaningless."
                Remediation      = 'Add the intended countries to this named location, or remove it from this policy.'
                AffectedPolicies = @($Policy.displayName)
                RelatedIds       = @($LocationId)
            }
            $Findings.Add((New-CIPPCAGapFinding @Params))
        }
    }

    @($Findings)
}
