function Invoke-CippTestCIS_6_1_3 {
    <#
    .SYNOPSIS
    Tests CIS M365 7.0.0 (6.1.3) - 'AuditBypassEnabled' SHALL NOT be enabled on mailboxes
    #>
    param($Tenant)

    try {
        $Bypassed = @(@(Get-CIPPTestData -TenantFilter $Tenant -Type 'ExoMailboxAuditBypass').Where({ $_ }))

        if ($Bypassed.Count -eq 0 -and -not (Get-CIPPDbItem -TenantFilter $Tenant -Type 'ExoMailboxAuditBypass' -CountsOnly)) {
            Add-CippTestResult -TenantFilter $Tenant -TestId 'CIS_6_1_3' -TestType 'Identity' -Status 'Skipped' -ResultMarkdown 'Mailbox audit bypass data has not been collected yet.' -Risk 'High' -Name "'AuditBypassEnabled' is not enabled on mailboxes" -UserImpact 'Low' -ImplementationEffort 'Low' -Category 'Audit & Compliance'
            return
        }

        if ($Bypassed.Count -eq 0) {
            $Status = 'Passed'
            $Result = 'No accounts have AuditBypassEnabled set to true.'
        } else {
            $Status = 'Failed'
            $Result = "$($Bypassed.Count) account(s) have audit bypass enabled:`n`n$(($Bypassed.Where({ $true }, 'First', 25).ForEach({ "- $($_.Name)" })) -join "`n")"
        }

        Add-CippTestResult -TenantFilter $Tenant -TestId 'CIS_6_1_3' -TestType 'Identity' -Status $Status -ResultMarkdown $Result -Risk 'High' -Name "'AuditBypassEnabled' is not enabled on mailboxes" -UserImpact 'Low' -ImplementationEffort 'Low' -Category 'Audit & Compliance'
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Add-CippTestResult -TenantFilter $Tenant -TestId 'CIS_6_1_3' -TestType 'Identity' -Status 'Failed' -ResultMarkdown "Test failed: $($ErrorMessage.NormalizedError)" -Risk 'High' -Name "'AuditBypassEnabled' is not enabled on mailboxes" -UserImpact 'Low' -ImplementationEffort 'Low' -Category 'Audit & Compliance'
    }
}
