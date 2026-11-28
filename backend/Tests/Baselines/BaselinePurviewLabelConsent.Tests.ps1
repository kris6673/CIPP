# PurviewLabelConsent turns on a one-way setting. Set-PolicyConfig throws once it is on, and the
# Secure Score read lags by a day or more, so the executor is re-run against tenants that are
# already on. Only that one error may be swallowed.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))

    function New-ExoRequest { [CmdletBinding()] param($tenantid, $cmdlet, $cmdParams, [switch]$Compliance) }

    . (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public/Executors/Invoke-CIPPBaselinePurviewLabelConsent.ps1')

    $script:Tenant = 'contoso.onmicrosoft.com'
    $script:Definition = Get-Content (Join-Path $script:RepoRoot 'Config/BaselineStandards/Global Standards/PurviewLabelConsent.json') -Raw | ConvertFrom-Json
}

Describe 'Invoke-CIPPBaselinePurviewLabelConsent' {
    It 'turns the consent on through the Security & Compliance endpoint' {
        Mock New-ExoRequest {}
        Invoke-CIPPBaselinePurviewLabelConsent -Remediate $script:Definition.remediate -TenantFilter $script:Tenant -Current $null
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter {
            $tenantid -eq $script:Tenant -and $cmdlet -eq 'Set-PolicyConfig' -and $Compliance -and $cmdParams.PurviewLabelConsent -eq $true
        }
    }

    It 'treats a tenant that is already on as done' {
        Mock New-ExoRequest { throw '|Microsoft.Exchange.Management.UnifiedPolicy.PurviewLabelAlreadyTurnOnErrorException|The PurviewLabelConsent option is already turned on.' }
        $Output = Invoke-CIPPBaselinePurviewLabelConsent -Remediate $script:Definition.remediate -TenantFilter $script:Tenant -Current $null
        $Output.Changed | Should -BeFalse
    }

    It 'reports a real change as changed' {
        Mock New-ExoRequest {}
        Invoke-CIPPBaselinePurviewLabelConsent -Remediate $script:Definition.remediate -TenantFilter $script:Tenant -Current $null | Should -BeNullOrEmpty
    }

    It 'fails when New-ExoRequest writes an error and returns without sending' {
        Mock New-ExoRequest { Write-Error 'Failed to get the Compliance URL' }
        { Invoke-CIPPBaselinePurviewLabelConsent -Remediate $script:Definition.remediate -TenantFilter $script:Tenant -Current $null } | Should -Throw '*Compliance URL*'
    }

    It 'fails on any other error' {
        Mock New-ExoRequest { throw 'Access denied' }
        { Invoke-CIPPBaselinePurviewLabelConsent -Remediate $script:Definition.remediate -TenantFilter $script:Tenant -Current $null } | Should -Throw 'Access denied'
    }
}

Describe 'PurviewLabelConsent definition' {
    It 'grades the Secure Score control this setting scores' {
        $script:Definition.read.cacheType | Should -Be 'SecureScoreSummary'
        $script:Definition.read.array | Should -Be 'controls'
        $script:Definition.read.filter[0].property | Should -Be 'controlName'
        $script:Definition.read.filter[0].value | Should -Be 'mip_purviewlabelconsent'
        $script:Definition.expected.scoreInPercentage | Should -Be 100
    }
}
