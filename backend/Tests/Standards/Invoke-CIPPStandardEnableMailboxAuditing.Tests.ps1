# Pester tests for Invoke-CIPPStandardEnableMailboxAuditing
#
# The tenant default only audits user, shared and group mailboxes. Room, equipment, discovery
# and Bookings mailboxes keep AuditEnabled = False, so the standard reported compliant while
# Secure Score gave no points.

BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    $StandardPath = Join-Path $RepoRoot 'Modules/CIPPStandards/Public/Standards/Invoke-CIPPStandardEnableMailboxAuditing.ps1'

    function Test-CIPPStandardLicense { [CmdletBinding()] param($StandardName, $TenantFilter, $Preset, [switch]$SkipLog) }
    function New-CIPPDbRequest { [CmdletBinding()] param($TenantFilter, $Type, $Fields) }
    function New-ExoRequest { [CmdletBinding()] param($tenantid, $cmdlet, $cmdParams, $useSystemMailbox) }
    function New-ExoBulkRequest { [CmdletBinding()] param($tenantid, $cmdletArray, $MaxConcurrency, [switch]$AnchorPerMailbox) }
    function Write-LogMessage { [CmdletBinding()] param($API, $tenant, $message, $sev, $LogData) }
    function Write-StandardsAlert { [CmdletBinding()] param($message, $object, $tenant, $standardName, $standardId) }
    function Set-CIPPStandardsCompareField { [CmdletBinding()] param($FieldName, $FieldValue, $CurrentValue, $ExpectedValue, $TenantFilter, $Tenant) }
    function Get-NormalizedError { [CmdletBinding()] param($Message) $Message }

    . $StandardPath
    $script:Tenant = 'contoso.onmicrosoft.com'
}

Describe 'Invoke-CIPPStandardEnableMailboxAuditing' {
    BeforeEach {
        Mock Test-CIPPStandardLicense { $true }
        Mock New-ExoRequest {
            if ($cmdlet -eq 'Get-OrganizationConfig') { [PSCustomObject]@{ AuditDisabled = $false } }
        }
        Mock New-CIPPDbRequest { $script:Mailboxes }
        Mock New-ExoBulkRequest { $script:BulkResult }
        Mock Write-LogMessage { }
        Mock Write-StandardsAlert { }
        Mock Set-CIPPStandardsCompareField { }
        $script:BulkResult = @([PSCustomObject]@{ Success = $true; OperationGuid = 'equip@contoso.com' }, [PSCustomObject]@{ Success = $true; OperationGuid = 'room2@contoso.com' })
        $script:Mailboxes = @(
            [PSCustomObject]@{ UPN = 'user@contoso.com'; recipientTypeDetails = 'UserMailbox'; AuditEnabled = $false }
            [PSCustomObject]@{ UPN = 'room2@contoso.com'; recipientTypeDetails = 'RoomMailbox'; AuditEnabled = $false }
            [PSCustomObject]@{ UPN = 'room1@contoso.com'; recipientTypeDetails = 'RoomMailbox'; AuditEnabled = $true }
            [PSCustomObject]@{ UPN = 'equip@contoso.com'; recipientTypeDetails = 'EquipmentMailbox'; AuditEnabled = 'False' }
        )
    }

    It 'reports the mailboxes with auditing off although the tenant flag is correct' {
        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ alert = $true; report = $true }

        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter {
            $CurrentValue.EnableMailboxAuditing -eq $true -and
            ($CurrentValue.MailboxesWithoutAuditing -join ',') -eq 'equip@contoso.com,room2@contoso.com' -and
            @($ExpectedValue.MailboxesWithoutAuditing).Count -eq 0
        }
        Should -Invoke Write-StandardsAlert -Times 1 -Exactly -ParameterFilter { $message -like '*2 mailbox*' }
        Should -Invoke New-ExoBulkRequest -Times 0 -Exactly
    }

    It 'turns auditing on for those mailboxes and then reports compliant' {
        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; report = $true }

        Should -Invoke New-ExoBulkRequest -Times 1 -Exactly -ParameterFilter {
            $AnchorPerMailbox -and @($cmdletArray).Count -eq 2 -and
            @($cmdletArray)[0].CmdletInput.CmdletName -eq 'Set-Mailbox' -and
            @($cmdletArray)[0].CmdletInput.Parameters.Identity -eq 'equip@contoso.com' -and
            @($cmdletArray)[0].CmdletInput.Parameters.AuditEnabled -eq $true
        }
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { @($CurrentValue.MailboxesWithoutAuditing).Count -eq 0 }
    }

    It 'keeps a mailbox whose write failed in the report' {
        $script:BulkResult = @([PSCustomObject]@{ error = 'proxy'; OperationGuid = 'equip@contoso.com' }, [PSCustomObject]@{ Success = $true; OperationGuid = 'room2@contoso.com' })

        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; report = $true }

        Should -Invoke Write-LogMessage -Times 1 -Exactly -ParameterFilter { $sev -eq 'Warning' -and $message -like '*1 of 2*equip@contoso.com -> proxy*' }
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { ($CurrentValue.MailboxesWithoutAuditing -join ',') -eq 'equip@contoso.com' }
    }

    It 'keeps a mailbox Exchange did not answer for in the report' {
        $script:BulkResult = @([PSCustomObject]@{ Success = $true; OperationGuid = 'room2@contoso.com' })

        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; alert = $true; report = $true }

        Should -Invoke Write-LogMessage -Times 1 -Exactly -ParameterFilter { $sev -eq 'Warning' -and $message -like '*1 of 2*equip@contoso.com -> no response*' }
        Should -Invoke Write-StandardsAlert -Times 1 -Exactly -ParameterFilter { $message -like '*1 mailbox*' }
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { ($CurrentValue.MailboxesWithoutAuditing -join ',') -eq 'equip@contoso.com' }
    }

    It 'still handles the tenant flag and bypass when the mailbox write throws' {
        Mock New-ExoBulkRequest { throw 'exchange down' }

        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; report = $true }

        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter { $cmdlet -eq 'Get-MailboxAuditBypassAssociation' }
        Should -Invoke Write-LogMessage -Times 1 -Exactly -ParameterFilter { $sev -eq 'Error' -and $message -like '*2 of 2*exchange down*' }
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { @($CurrentValue.MailboxesWithoutAuditing).Count -eq 2 }
    }

    It 'still handles the tenant flag and bypass when the mailbox cache cannot be read' {
        Mock New-CIPPDbRequest { throw 'table down' }

        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; report = $true }

        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter { $cmdlet -eq 'Get-MailboxAuditBypassAssociation' }
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { $CurrentValue.EnableMailboxAuditing -eq $true -and @($CurrentValue.MailboxesWithoutAuditing).Count -eq 0 }
    }

    It 'falls back to the tenant flag alone when the mailbox cache is empty' {
        $script:Mailboxes = @()

        Invoke-CIPPStandardEnableMailboxAuditing -Tenant $script:Tenant -Settings @{ remediate = $true; report = $true }

        Should -Invoke Write-LogMessage -Times 1 -Exactly -ParameterFilter { $sev -eq 'Warning' -and $message -like '*cached mailbox list is empty*' }
        Should -Invoke New-ExoBulkRequest -Times 0 -Exactly
        Should -Invoke Set-CIPPStandardsCompareField -Times 1 -Exactly -ParameterFilter { $CurrentValue.EnableMailboxAuditing -eq $true -and @($CurrentValue.MailboxesWithoutAuditing).Count -eq 0 }
    }
}
