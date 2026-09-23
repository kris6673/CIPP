BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    function New-GraphBulkRequest { param($Requests, $tenantid, $asapp, $Version, $NoPaginateIds) }
    function New-GraphGetRequest { param($uri, $tenantid, $AsApp) }
    function New-ExoRequest { param($tenantid, $cmdlet, $cmdParams, $Anchor) }
    function Get-CIPPTenantAllowBlockListItems { param($TenantFilter, $ListType) }
    function Get-CIPPIPAllowBlockList { param($TenantFilter) }
    function Get-NormalizedError { param($message) $message }
    foreach ($File in @('ConvertTo-CIPPODataFilterValue.ps1', 'Authentication/ConvertTo-CIPPIPRange.ps1', 'BEC/ConvertTo-CIPPBecHostAddress.ps1', 'BEC/New-CIPPBecCollectorResult.ps1', 'BEC/Get-CIPPBecSignInBaseline.ps1', 'BEC/Get-CIPPBecIPPeers.ps1', 'BEC/Get-CIPPBecIPGuidance.ps1')) {
        . (Join-Path $RepoRoot "Modules/CIPPCore/Public/$File")
    }
    function New-SignIn {
        param($IP, $When, $Ok = $true, $Asn = 1221, $City = 'Sydney', $App = 'Outlook')
        [pscustomobject]@{ createdDateTime = $When; ipAddress = $IP; autonomousSystemNumber = $Asn; location = [pscustomobject]@{ countryOrRegion = 'AU'; city = $City }; conditionalAccessStatus = 'success'; status = [pscustomobject]@{ errorCode = $(if ($Ok) { 0 } else { 50126 }) }; appDisplayName = $App; resourceDisplayName = 'Office 365 Exchange Online' }
    }
}

Describe 'Get-CIPPBecSignInBaseline' {
    It 'profiles successful sign-ins by address, network and location across interactive and service sign-ins' {
        Mock New-GraphBulkRequest {
            @(
                [pscustomobject]@{ id = 'Interactive'; status = 200; body = [pscustomobject]@{ value = @(
                            (New-SignIn -IP '203.0.113.10' -When '2026-09-01T01:00:00Z')
                            (New-SignIn -IP '203.0.113.10' -When '2026-09-02T01:00:00Z')
                            (New-SignIn -IP '198.51.100.7' -When '2026-09-03T01:00:00Z' -Ok $false -Asn 14061 -City 'Lagos')
                        ) } }
                [pscustomobject]@{ id = 'NonInteractive'; status = 200; body = [pscustomobject]@{ value = @(
                            (New-SignIn -IP '203.0.113.10' -When '2026-09-02T02:00:00Z' -App 'SharePoint Online')
                            (New-SignIn -IP '192.0.2.44' -When '2026-09-04T01:00:00Z' -City 'Melbourne')
                        ) } }
            )
        }
        $Result = Get-CIPPBecSignInBaseline -TenantFilter 'contoso.com' -UserId '11111111-1111-1111-1111-111111111111' -StartDate '2026-08-15' -EndDate '2026-09-16'
        $Result.Complete | Should -BeTrue
        $Result.Data.Successful | Should -Be 4 -Because 'the failed spray attempt must not teach the baseline an attacker address'
        $Office = $Result.Data.IPs | Where-Object IP -EQ '203.0.113.10'
        $Office.SignIns | Should -Be 3
        $Office.Interactive | Should -Be 2
        $Office.NonInteractive | Should -Be 1
        $Office.Days | Should -Be 2
        $Office.Share | Should -Be 0.75
        $Office.Apps | Should -Contain 'SharePoint Online'
        ($Result.Data.IPs | Where-Object IP -EQ '198.51.100.7') | Should -BeNullOrEmpty
        ($Result.Data.Locations | Where-Object City -EQ 'Sydney').Share | Should -Be 0.75
        Should -Invoke New-GraphBulkRequest -Times 1 -ParameterFilter { @($Requests).Count -eq 2 -and $Requests[1].url -match "nonInteractiveUser" -and $Requests[0].url -match 'createdDateTime lt ' }
    }

    It 'reports a failed half and a Graph paging stop without losing the other half' {
        Mock New-GraphBulkRequest {
            @(
                [pscustomobject]@{ id = 'Interactive'; status = 200; PagingIncomplete = $true; body = [pscustomobject]@{ value = @(New-SignIn -IP '203.0.113.10' -When '2026-09-01T01:00:00Z') } }
                [pscustomobject]@{ id = 'NonInteractive'; status = 403; body = [pscustomobject]@{ error = [pscustomobject]@{ message = 'Tenant does not have a premium licence' } } }
            )
        }
        $Result = Get-CIPPBecSignInBaseline -TenantFilter 'contoso.com' -UserId '11111111-1111-1111-1111-111111111111' -StartDate '2026-08-15' -EndDate '2026-09-16'
        $Result.Complete | Should -BeFalse
        $Result.Error | Should -Match 'NonInteractive sign-ins: Tenant does not have a premium licence'
        $Result.Data.Successful | Should -Be 1
    }
}

Describe 'Get-CIPPBecIPPeers' {
    It 'splits other accounts into before and only-in-window, excluding the investigated user, and samples service sign-ins' {
        Mock New-GraphBulkRequest {
            @(
                [pscustomobject]@{ id = 'i0'; status = 200; body = [pscustomobject]@{ value = @(
                            [pscustomobject]@{ userId = 'me'; userPrincipalName = 'victim@contoso.com'; createdDateTime = '2026-09-01T00:00:00Z' }
                            [pscustomobject]@{ userId = 'a'; userPrincipalName = 'a@contoso.com'; createdDateTime = '2026-09-01T00:00:00Z' }
                        ) } }
                [pscustomobject]@{ id = 'n0'; status = 200; body = [pscustomobject]@{ '@odata.nextLink' = 'more'; value = @([pscustomobject]@{ userId = 'b'; userPrincipalName = 'b@contoso.com'; createdDateTime = '2026-09-02T00:00:00Z' }) } }
                [pscustomobject]@{ id = 'i1'; status = 200; body = [pscustomobject]@{ value = @([pscustomobject]@{ userId = 'c'; userPrincipalName = 'c@contoso.com'; createdDateTime = '2026-09-20T00:00:00Z' }) } }
                [pscustomobject]@{ id = 'n1'; status = 200; body = [pscustomobject]@{ value = @() } }
            )
        }
        $Peers = Get-CIPPBecIPPeers -TenantFilter 'contoso.com' -UserId 'me' -IPs @('203.0.113.10', '198.51.100.7') -StartDate '2026-08-15' -WindowStart '2026-09-16'
        $Peers['203.0.113.10'].OtherUsersBefore | Should -Be 2
        $Peers['203.0.113.10'].Users | Should -Not -Contain 'victim@contoso.com'
        $Peers['203.0.113.10'].Sampled | Should -BeTrue
        $Peers['198.51.100.7'].OtherUsersInWindowOnly | Should -Be 1
        Should -Invoke New-GraphBulkRequest -Times 1 -ParameterFilter { @($NoPaginateIds) -contains 'n0' -and @($NoPaginateIds) -contains 'n1' -and $Requests[0].url -match "ipAddress eq '203.0.113.10'" }
    }

    It 'returns nothing without calling Graph when there are no addresses' {
        Mock New-GraphBulkRequest { throw 'should not be called' }
        (Get-CIPPBecIPPeers -TenantFilter 'contoso.com' -UserId 'me' -IPs @() -StartDate '2026-08-15' -WindowStart '2026-09-16').Count | Should -Be 0
    }
}

Describe 'Get-CIPPBecIPGuidance' {
    It 'gathers the CIPP list as deciding entries and the named locations and Exchange lists as hints' {
        Mock Get-CIPPIPAllowBlockList { @([pscustomobject]@{ Range = '198.51.100.0/24'; State = 'Blocked'; Scope = 'AllTenants'; Prefix = 24; Note = 'kit' }) }
        Mock New-GraphGetRequest { @(
                [pscustomobject]@{ '@odata.type' = '#microsoft.graph.ipNamedLocation'; displayName = 'HQ'; isTrusted = $true; ipRanges = @([pscustomobject]@{ cidrAddress = '203.0.113.0/24' }) }
                [pscustomobject]@{ '@odata.type' = '#microsoft.graph.ipNamedLocation'; displayName = 'Blocked countries IPs'; isTrusted = $false; ipRanges = @([pscustomobject]@{ cidrAddress = '192.0.2.0/24' }) }
            ) }
        Mock Get-CIPPTenantAllowBlockListItems { @([pscustomobject]@{ Value = '2001:db8::1'; Action = 'Block'; Notes = $null }) }
        Mock New-ExoRequest { @([pscustomobject]@{ Name = 'Default'; IPAllowList = @('192.0.2.10', '192.0.2.20-192.0.2.30'); IPBlockList = @() }) }
        $Result = Get-CIPPBecIPGuidance -TenantFilter 'contoso.com'
        $Result.Complete | Should -BeTrue
        ($Result.Data | Where-Object Range -EQ '198.51.100.0/24').Strength | Should -Be 'List'
        ($Result.Data | Where-Object Range -EQ '203.0.113.0/24').Source | Should -Be "Trusted named location 'HQ'"
        ($Result.Data | Where-Object Range -EQ '192.0.2.0/24') | Should -BeNullOrEmpty -Because 'only trusted named locations say anything about the user'
        ($Result.Data | Where-Object Range -EQ '2001:db8::1').Verdict | Should -Be 'Blocked'
        @($Result.Data | Where-Object Source -Like 'Connection filter*').Range | Should -Be @('192.0.2.10') -Because 'hyphenated ranges are skipped'
    }

    It 'keeps the other sources when one fails and reports it' {
        Mock Get-CIPPIPAllowBlockList { @([pscustomobject]@{ Range = '198.51.100.7'; State = 'Trusted'; Scope = 'Tenant'; Prefix = 32 }) }
        Mock New-GraphGetRequest { throw 'Forbidden' }
        Mock Get-CIPPTenantAllowBlockListItems { @() }
        Mock New-ExoRequest { @() }
        $Result = Get-CIPPBecIPGuidance -TenantFilter 'contoso.com'
        $Result.Complete | Should -BeFalse
        $Result.Error | Should -Match 'named locations: Forbidden'
        @($Result.Data).Count | Should -Be 1
    }
}
