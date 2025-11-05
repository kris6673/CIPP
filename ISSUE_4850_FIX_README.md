# Fix for Issue #4850: Exclude .mail.onmicrosoft.com from Domain Monitoring

## Quick Summary

This PR provides the solution for [Issue #4850](https://github.com/KelvinTegelaar/CIPP/issues/4850) which requests excluding `.mail.onmicrosoft.com` domains from domain monitoring to prevent false positive alerts.

## Problem

- `.mail.onmicrosoft.com` domains are automatically added for any hybrid Exchange systems
- These domains cannot be controlled by tenants (DNS is managed by Microsoft)
- They always fail SPF, DKIM, DMARC, and DNSSEC checks
- This creates constant false positive alerts that cannot be resolved

Example alert:
```
.mail.onmicrosoft.com: Domain security score is 12%, which is below the threshold of 25%. 
Issues: SPF record did not pass validation, No DMARC Records Found, DNSSEC Not Configured or Enabled, DKIM Not Configured
```

## Solution

Add `*.mail.onmicrosoft.com` to the exclusion list in CIPP-API to prevent these domains from being analyzed.

## Files in This PR

### 1. `SOLUTION_FOR_ISSUE_4850.md`
Comprehensive documentation explaining:
- The problem in detail
- Exact code changes needed in CIPP-API
- Before/after code examples
- Impact assessment
- Testing guidelines

### 2. `cipp-api-fix-4850.patch`
A Git patch file containing the exact changes needed for CIPP-API repository. This can be applied directly using:

```bash
cd /path/to/CIPP-API
git apply cipp-api-fix-4850.patch
```

## Implementation Required

The actual fix needs to be applied to the **CIPP-API repository** at https://github.com/kris6673/CIPP-API

### Changes Required in CIPP-API:

**File 1:** `Modules/CIPPCore/Public/Entrypoints/Activity Triggers/Domain Analyser/Push-DomainAnalyserTenant.ps1`
- Add `'*.mail.onmicrosoft.com'` to the `$ExclusionDomains` array at line ~26

**File 2:** `Modules/CIPPCore/Public/Standards/Invoke-CIPPStandardAddDKIM.ps1`
- Add `'*.mail.onmicrosoft.com'` to the `$ExclusionDomains` array at line ~79

Both changes are identical - just adding one line to the existing exclusion arrays.

## How to Apply

### Option 1: Using the Patch File
```bash
# In CIPP-API repository
git checkout -b fix/exclude-mail-onmicrosoft-domains
git apply /path/to/cipp-api-fix-4850.patch
git commit -m "Exclude *.mail.onmicrosoft.com domains from domain analyser"
git push origin fix/exclude-mail-onmicrosoft-domains
```

### Option 2: Manual Changes
Follow the detailed instructions in `SOLUTION_FOR_ISSUE_4850.md`

## Benefits

- ✅ Eliminates false positive alerts for `.mail.onmicrosoft.com` domains
- ✅ Reduces alert noise for MSPs managing hybrid Exchange environments
- ✅ Consistent with existing exclusions for other Microsoft-managed domains
- ✅ No impact on legitimate domain monitoring
- ✅ Follows existing patterns in the codebase

## Testing Checklist

Once applied to CIPP-API:

- [ ] Verify `.mail.onmicrosoft.com` domains are not added to the analyser during tenant sync
- [ ] Confirm other domains continue to be analysed correctly  
- [ ] Ensure no errors in domain filtering logic
- [ ] Validate that DKIM standard also skips these domains
- [ ] Test with a tenant that has `.mail.onmicrosoft.com` domains

## Related Issues

- Original Issue: https://github.com/KelvinTegelaar/CIPP/issues/4850
- Reported by: @jp-itt
- Category: Feature Request - Enhancement
- Priority: Medium
- Benefit: Reduce false positive alerts

## Notes

- This PR is in the CIPP (frontend) repository but documents changes needed in CIPP-API (backend)
- No changes are needed in the CIPP frontend repository
- The patch file provides a ready-to-apply solution for CIPP-API
- Existing `.mail.onmicrosoft.com` domains in the analyser will need manual cleanup or will age out naturally
