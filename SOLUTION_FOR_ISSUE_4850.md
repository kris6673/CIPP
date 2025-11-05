# Solution for Issue #4850: Exclude .mail.onmicrosoft.com from Domain Monitoring

## Problem
`.mail.onmicrosoft.com` domains are automatically added for hybrid Exchange systems, but their DNS is managed by Microsoft. These domains cannot be controlled by tenants and always fail SPF, DKIM, DMARC, and DNSSEC checks, creating false positive alerts.

## Solution
Add `*.mail.onmicrosoft.com` to the domain exclusion list in the CIPP-API repository to prevent these domains from being added to the domain analyser.

## Required Changes in CIPP-API Repository

### File 1: `Modules/CIPPCore/Public/Entrypoints/Activity Triggers/Domain Analyser/Push-DomainAnalyserTenant.ps1`

**Location:** Line 24-35

**Change:** Add `'*.mail.onmicrosoft.com'` to the `$ExclusionDomains` array

**Before:**
```powershell
# Remove domains that are not wanted, and used for cloud signature services. Same exclusions also found in Invoke-CIPPStandardAddDKIM
$ExclusionDomains = @(
    '*.microsoftonline.com'
    '*.exclaimer.cloud'
    '*.excl.cloud'
    '*.codetwo.online'
    '*.call2teams.com'
    '*.signature365.net'
    '*.myteamsconnect.io'
    '*.teams.dstny.com'
    '*.msteams.8x8.com'
    '*.ucconnect.co.uk'
)
```

**After:**
```powershell
# Remove domains that are not wanted, and used for cloud signature services. Same exclusions also found in Invoke-CIPPStandardAddDKIM
$ExclusionDomains = @(
    '*.microsoftonline.com'
    '*.mail.onmicrosoft.com'
    '*.exclaimer.cloud'
    '*.excl.cloud'
    '*.codetwo.online'
    '*.call2teams.com'
    '*.signature365.net'
    '*.myteamsconnect.io'
    '*.teams.dstny.com'
    '*.msteams.8x8.com'
    '*.ucconnect.co.uk'
)
```

### File 2: `Modules/CIPPCore/Public/Standards/Invoke-CIPPStandardAddDKIM.ps1`

**Location:** Line 76-88

**Change:** Add `'*.mail.onmicrosoft.com'` to the `$ExclusionDomains` array for consistency

**Before:**
```powershell
# Same exclusions also found in Push-DomainAnalyserTenant
$ExclusionDomains = @(
    '*.microsoftonline.com'
    '*.exclaimer.cloud'
    '*.excl.cloud'
    '*.codetwo.online'
    '*.call2teams.com'
    '*.signature365.net'
    '*.myteamsconnect.io'
    '*.teams.dstny.com'
    '*.msteams.8x8.com'
    '*.ucconnect.co.uk'
)
```

**After:**
```powershell
# Same exclusions also found in Push-DomainAnalyserTenant
$ExclusionDomains = @(
    '*.microsoftonline.com'
    '*.mail.onmicrosoft.com'
    '*.exclaimer.cloud'
    '*.excl.cloud'
    '*.codetwo.online'
    '*.call2teams.com'
    '*.signature365.net'
    '*.myteamsconnect.io'
    '*.teams.dstny.com'
    '*.msteams.8x8.com'
    '*.ucconnect.co.uk'
)
```

## Impact
- `.mail.onmicrosoft.com` domains will no longer be added to the domain analyser
- Existing `.mail.onmicrosoft.com` domains in the analyser will not be automatically removed (they would need manual cleanup or will eventually age out)
- No false positive alerts will be generated for these domains going forward
- DKIM standard will also skip these domains, maintaining consistency

## Applying the Fix

A patch file `cipp-api-fix-4850.patch` has been provided in this repository. To apply it to the CIPP-API repository:

```bash
cd /path/to/CIPP-API
git apply /path/to/CIPP/cipp-api-fix-4850.patch
```

Or manually apply the changes as described above.

## Testing
1. Verify that new `.mail.onmicrosoft.com` domains are not added to the analyser when syncing tenant domains
2. Confirm that other domains continue to be analysed correctly
3. Check that no errors are introduced in domain filtering logic

## Related Code
The exclusion is applied in `Push-DomainAnalyserTenant.ps1` at the domain collection stage (lines 37-45):

```powershell
$Domains = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/domains' -tenantid $Tenant.customerId | Where-Object { $_.isVerified -eq $true } | ForEach-Object {
    $Domain = $_
    foreach ($ExclusionDomain in $ExclusionDomains) {
        if ($Domain.id -like $ExclusionDomain) {
            $Domain = $null
        }
    }
    $Domain
} | Where-Object { $_ -ne $null }
```

This filtering prevents excluded domains from ever being stored in the Domains table, which means they won't be processed by the domain analyser.
