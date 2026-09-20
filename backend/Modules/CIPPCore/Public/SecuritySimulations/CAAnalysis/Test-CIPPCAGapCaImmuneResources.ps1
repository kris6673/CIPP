function Test-CIPPCAGapCaImmuneResources {
    <#
    .SYNOPSIS
        Tenant-wide awareness finding about Microsoft resources that Conditional Access never evaluates.
    .DESCRIPTION
        When at least one enabled or report-only policy targets All cloud apps, emits a single Info finding listing
        the resources that always show notApplied in sign-in logs (Intune Checkin, Windows Notification Service,
        Mobile Application Management, Azure MFA Connector, OCaaS Client Interaction Service, Authenticator App).
        This is by design and cannot be changed, but the resources can be used for password verification without
        triggering Conditional Access.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $Findings = [System.Collections.Generic.List[object]]::new()
    $AllAppsPolicies = @($Context.Policies | Where-Object { $_.state -ne 'disabled' -and (@($_.conditions.applications.includeApplications) -contains 'All') })
    if ($AllAppsPolicies.Count -eq 0) { return @($Findings) }

    $Resources = @($Context.Data.ImmuneResources)
    $Names = @($Resources | ForEach-Object { "$($_.displayName)" }) -join ', '
    $Params = @{
        Severity         = 'Info'
        Category         = 'CA-Immune Resources'
        Title            = "$($Resources.Count) Microsoft resources are always immune to Conditional Access"
        Description      = "$($AllAppsPolicies.Count) of your policies target ""All cloud apps"", but $($Resources.Count) Microsoft resources are always excluded from CA evaluation: $Names. These will show 'notApplied' in sign-in logs regardless of your policies."
        Remediation      = 'This is by-design and cannot be changed. Monitor sign-in logs for these resource IDs as they can be used for password verification without triggering CA.'
        AffectedPolicies = @($AllAppsPolicies | ForEach-Object { $_.displayName })
        RelatedIds       = @($Resources | ForEach-Object { "$($_.resourceId)" })
    }
    $Findings.Add((New-CIPPCAGapFinding @Params))

    @($Findings)
}
