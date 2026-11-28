BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))

    function Get-Tenants { param($TenantFilter, [switch]$SkipDomains) }
    function Get-CIPPTable { param($TableName) @{ Context = $TableName } }
    function Get-CIPPAzDataTableEntity { param($Context, $Filter, $Property) }
    function Write-AlertTrace { param($cmdletName, $tenantFilter, $data) }
    function Write-LogMessage { param($API, $tenant, $message, $sev, $LogData) }
    function Get-CippException { param($Exception) @{ NormalizedError = "$($Exception.Exception.Message)" } }

    . (Join-Path $RepoRoot 'Modules/CIPPAlerts/Public/Alerts/Get-CIPPAlertManagedBaselineRecommendations.ps1')

    function New-Finding {
        param($Id, $Status, $Title = "Title $Id")
        [pscustomobject]@{ PartitionKey = 'tenant-id'; RowKey = "rec-$Id"; Status = $Status; Title = $Title; Standard = "Standard$Id"; Impact = 'Low Impact'; Reason = 'Because.' }
    }
    $script:Finished = [pscustomobject]@{ PartitionKey = 'tenant-id'; RowKey = 'scan'; Status = 'Finished'; FinishedAt = 1794000000 }
}

Describe 'Get-CIPPAlertManagedBaselineRecommendations' {
    BeforeEach {
        Mock Write-AlertTrace { }
        Mock Write-LogMessage { }
        Mock Get-Tenants { [pscustomobject]@{ customerId = 'tenant-id'; defaultDomainName = 'contoso.onmicrosoft.com' } }
    }

    It 'reports the open recommendations, and not what a baseline covers or what already matches' {
        Mock Get-CIPPAzDataTableEntity { @($script:Finished, (New-Finding 'a' 'Recommended'), (New-Finding 'b' 'Covered by a baseline'), (New-Finding 'c' 'Compliant')) }

        Get-CIPPAlertManagedBaselineRecommendations -TenantFilter 'contoso.onmicrosoft.com'

        Should -Invoke Write-AlertTrace -Times 1 -Exactly -ParameterFilter {
            @($data).Count -eq 1 -and $data.Id -eq 'rec-a' -and $data.Message -eq 'New managed baseline recommendation: Title a'
        }
        Should -Invoke Get-CIPPAzDataTableEntity -Times 1 -Exactly -ParameterFilter { $Filter -eq "PartitionKey eq 'tenant-id'" -and $Property -contains 'RowKey' }
    }

    It 'reports an empty result once nothing is recommended any more' {
        Mock Get-CIPPAzDataTableEntity { @($script:Finished, (New-Finding 'c' 'Compliant')) }

        Get-CIPPAlertManagedBaselineRecommendations -TenantFilter 'contoso.onmicrosoft.com'

        Should -Invoke Write-AlertTrace -Times 1 -Exactly -ParameterFilter { -not $data }
    }

    It 'reports nothing for a tenant that has not finished a scan' {
        Mock Get-CIPPAzDataTableEntity { @([pscustomobject]@{ RowKey = 'scan'; Status = 'Running' }) }

        Get-CIPPAlertManagedBaselineRecommendations -TenantFilter 'contoso.onmicrosoft.com'

        Should -Invoke Write-AlertTrace -Times 0 -Exactly
    }

    It 'does not report when the stored results cannot be read' {
        Mock Get-CIPPAzDataTableEntity { throw 'table down' }

        Get-CIPPAlertManagedBaselineRecommendations -TenantFilter 'contoso.onmicrosoft.com'

        Should -Invoke Write-AlertTrace -Times 0 -Exactly
        Should -Invoke Write-LogMessage -Times 1 -Exactly
    }
}
