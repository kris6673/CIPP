# Pester tests for Invoke-CippTestCIS_6_1_3
#
# The test read AuditBypassEnabled from the mailbox cache, where that field is never collected,
# so it passed on every tenant. The flag lives on the bypass association, cached on its own.

BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))

    function Get-CIPPTestData { [CmdletBinding()] param($TenantFilter, $Type) }
    function Get-CIPPDbItem { [CmdletBinding()] param($TenantFilter, $Type, [switch]$CountsOnly) }
    function Add-CippTestResult { [CmdletBinding()] param($TenantFilter, $TestId, $TestType, $Status, $ResultMarkdown, $Risk, $Name, $UserImpact, $ImplementationEffort, $Category) }
    function Get-CippException { [CmdletBinding()] param($Exception) @{ NormalizedError = $Exception.Exception.Message } }

    . (Join-Path $RepoRoot 'Modules/CIPPTests/Public/Tests/CIS/Identity/Invoke-CippTestCIS_6_1_3.ps1')
    $script:Tenant = 'contoso.onmicrosoft.com'
}

Describe 'Invoke-CippTestCIS_6_1_3' {
    BeforeEach {
        Mock Add-CippTestResult { }
        Mock Get-CIPPDbItem { [PSCustomObject]@{ RowKey = 'ExoMailboxAuditBypass-Count'; DataCount = 0 } }
        Mock Get-CIPPTestData { $script:Bypassed } -ParameterFilter { $Type -eq 'ExoMailboxAuditBypass' }
    }

    It 'fails and names the accounts that have audit bypass enabled' {
        $script:Bypassed = @([PSCustomObject]@{ Name = 'svc-a'; Guid = 'aaaaaaaa-0000-0000-0000-000000000001' })

        Invoke-CippTestCIS_6_1_3 -Tenant $script:Tenant

        Should -Invoke Add-CippTestResult -Times 1 -Exactly -ParameterFilter { $Status -eq 'Failed' -and $ResultMarkdown -like '*1 account*- svc-a*' }
    }

    It 'passes when the collected list is empty' {
        $script:Bypassed = @()

        Invoke-CippTestCIS_6_1_3 -Tenant $script:Tenant

        Should -Invoke Add-CippTestResult -Times 1 -Exactly -ParameterFilter { $Status -eq 'Passed' }
    }

    It 'passes when a cached empty read comes back as a null record' {
        $script:Bypassed = $null
        Mock Get-CIPPTestData { $null } -ParameterFilter { $Type -eq 'ExoMailboxAuditBypass' }

        Invoke-CippTestCIS_6_1_3 -Tenant $script:Tenant

        Should -Invoke Add-CippTestResult -Times 1 -Exactly -ParameterFilter { $Status -eq 'Passed' }
    }

    It 'is skipped when the list was never collected' {
        $script:Bypassed = @()
        Mock Get-CIPPDbItem { }

        Invoke-CippTestCIS_6_1_3 -Tenant $script:Tenant

        Should -Invoke Add-CippTestResult -Times 1 -Exactly -ParameterFilter { $Status -eq 'Skipped' }
    }
}
