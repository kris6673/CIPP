function Invoke-CIPPStandardEnableMailboxAuditing {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) EnableMailboxAuditing
    .SYNOPSIS
        (Label) Enable Mailbox auditing
    .DESCRIPTION
        (Helptext) Enables Mailbox auditing on tenant level and on the room, equipment, discovery and Bookings mailboxes the tenant default does not cover. Disables audit bypass on all mailboxes. Unified Audit Log needs to be enabled for this standard to function.
        (DocsDescription) Enables mailbox auditing on tenant level. Microsoft only enables auditing by default for user, shared and group mailboxes, so auditing is also turned on for each room, equipment, discovery and Bookings mailbox. Public folder mailboxes are not covered. Disables audit bypass on all mailboxes. Unified Audit Log needs to be enabled for this standard to function.
    .NOTES
        CAT
            Exchange Standards
        TAG
            "CIS M365 5.0 (6.1.1)"
            "CIS M365 5.0 (6.1.2)"
            "CIS M365 5.0 (6.1.3)"
            "exo_mailboxaudit"
            "Essential 8 (1509)"
            "Essential 8 (1683)"
            "NIST CSF 2.0 (DE.CM-09)"
            "CISAMSEXO131"
        EXECUTIVETEXT
            Enables comprehensive logging of all email access and modifications across all employee mailboxes, providing detailed audit trails for security investigations and compliance requirements. This helps detect unauthorized access, data breaches, and supports regulatory compliance efforts.
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2024-01-08
        POWERSHELLEQUIVALENT
            Set-OrganizationConfig -AuditDisabled \$false; Set-Mailbox -AuditEnabled \$true
        RECOMMENDEDBY
            "CIS"
            "CIPP"
        REQUIREDCAPABILITIES
            "EXCHANGE_S_STANDARD"
            "EXCHANGE_S_ENTERPRISE"
            "EXCHANGE_S_STANDARD_GOV"
            "EXCHANGE_S_ENTERPRISE_GOV"
            "EXCHANGE_LITE"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/alignment/templates/available-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'EnableMailboxAuditing' -TenantFilter $Tenant -Preset Exchange #No Foundation because that does not allow powershell access

    if ($TestResult -eq $false) {
        return $true
    } #we're done.

    try {
        $AuditState = (New-ExoRequest -tenantid $Tenant -cmdlet 'Get-OrganizationConfig').AuditDisabled
    } catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the EnableMailboxAuditing state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    # Mailbox auditing on by default covers user, shared and group mailboxes only, so these types
    # keep their own AuditEnabled flag, which Secure Score grades. Public folder mailboxes are not
    # in the mailbox cache.
    $AuditTypes = @('RoomMailbox', 'EquipmentMailbox', 'DiscoveryMailbox', 'SchedulingMailbox')
    $Mailboxes = @(try { New-CIPPDbRequest -TenantFilter $Tenant -Type 'Mailboxes' -Fields 'UPN', 'recipientTypeDetails', 'AuditEnabled' } catch { Write-Information "EnableMailboxAuditing: reading the mailbox cache for $Tenant failed: $($_.Exception.Message)" })
    if ($Mailboxes.Count -eq 0) {
        Write-LogMessage -API 'Standards' -tenant $Tenant -message 'EnableMailboxAuditing: the cached mailbox list is empty, so per-mailbox auditing was not checked. It is checked once mailbox data has been collected.' -sev Warning
    }
    $Unaudited = @($Mailboxes.Where({ $_.UPN -and $_.recipientTypeDetails -in $AuditTypes -and "$($_.AuditEnabled)" -eq 'False' }).UPN | Sort-Object)

    if ($Settings.remediate -eq $true) {
        if ($AuditState) {
            # Enable tenant level mailbox audit
            try {
                New-ExoRequest -tenantid $Tenant -cmdlet 'Set-OrganizationConfig' -cmdParams @{AuditDisabled = $false } -useSystemMailbox $true
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Tenant level mailbox audit enabled' -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to enable tenant level mailbox audit. Error: $ErrorMessage" -sev Error
            }
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Tenant level mailbox audit already enabled' -sev Info
        }

        if ($Unaudited.Count -gt 0) {
            $Request = foreach ($UPN in $Unaudited) {
                @{
                    CmdletInput   = @{ CmdletName = 'Set-Mailbox'; Parameters = @{ Identity = $UPN; AuditEnabled = $true } }
                    OperationGuid = $UPN
                }
            }
            # Audit settings are written on the mailbox's own server, so each write is anchored to its mailbox.
            # A mailbox counts as written only when Exchange answered for it without an error.
            $Answers = @{}
            try {
                foreach ($Answer in @(New-ExoBulkRequest -tenantid $Tenant -cmdletArray @($Request) -AnchorPerMailbox -MaxConcurrency 10)) {
                    if ($Answer.OperationGuid) { $Answers["$($Answer.OperationGuid)"] = "$($Answer.error)" }
                }
            } catch {
                foreach ($UPN in $Unaudited) { $Answers[$UPN] = "$($_.Exception.Message)" }
            }
            $Failed = @($Unaudited.Where({ -not $Answers.ContainsKey($_) -or $Answers[$_] }))
            if ($Failed.Count -gt 0) {
                $Failures = foreach ($UPN in $Failed[0..([Math]::Min(9, $Failed.Count - 1))]) { "$UPN -> $(if ($Answers[$UPN]) { Get-NormalizedError -Message $Answers[$UPN] } else { 'no response from Exchange' })" }
                $Sev = if ($Failed.Count -ge $Unaudited.Count) { 'Error' } else { 'Warning' }
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to enable mailbox auditing for $($Failed.Count) of $($Unaudited.Count) mailbox(es). $($Failures -join ' | ')" -sev $Sev
            }
            if ($Failed.Count -lt $Unaudited.Count) {
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Enabled mailbox auditing for $($Unaudited.Count - $Failed.Count) mailbox(es)" -sev Info
            }
            $Unaudited = $Failed
        }

        # Disable audit bypass for any mailbox that has it enabled, so no user is excluded from
        # auditing. The bypass flag is not a Get-Mailbox property - it lives on the association.
        try {
            $BypassMailboxes = @(New-ExoRequest -tenantid $Tenant -cmdlet 'Get-MailboxAuditBypassAssociation' -cmdParams @{ ResultSize = 'Unlimited' } -useSystemMailbox $true | Where-Object { $_.AuditBypassEnabled -eq $true })
        } catch {
            $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to retrieve mailbox audit bypass associations. Error: $ErrorMessage" -sev Error
            $BypassMailboxes = @()
        }

        if ($BypassMailboxes.Count -gt 0) {
            $Request = foreach ($Mailbox in $BypassMailboxes) {
                @{
                    CmdletInput = @{
                        CmdletName = 'Set-MailboxAuditBypassAssociation'
                        Parameters = @{Identity = $Mailbox.Guid; AuditBypassEnabled = $false }
                    }
                }
            }

            $BatchResults = New-ExoBulkRequest -tenantid $tenant -cmdletArray @($Request)
            foreach ($Result in $BatchResults) {
                if ($Result.error) {
                    $ErrorMessage = Get-NormalizedError -Message $Result.error
                    Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to disable mailbox audit bypass for $($Result.target). Error: $ErrorMessage" -sev Error
                }
            }
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Disabled mailbox audit bypass for $($BypassMailboxes.Count) mailbox(es)" -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'No mailboxes have audit bypass enabled' -sev Info
        }
    }

    if ($Settings.alert -eq $true) {
        if ($AuditState) {
            Write-StandardsAlert -message 'Tenant level mailbox audit is not enabled' -object $AuditState -tenant $Tenant -standardName 'EnableMailboxAuditing' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Tenant level mailbox audit is not enabled' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Tenant level mailbox audit is enabled' -sev Info
        }
        if ($Unaudited.Count -gt 0) {
            Write-StandardsAlert -message "Mailbox auditing is not enabled on $($Unaudited.Count) mailbox(es)" -object $Unaudited -tenant $Tenant -standardName 'EnableMailboxAuditing' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Mailbox auditing is not enabled on $($Unaudited.Count) mailbox(es): $($Unaudited -join ', ')" -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $AuditState = -not $AuditState

        $CurrentValue = [PSCustomObject]@{
            EnableMailboxAuditing    = $AuditState
            MailboxesWithoutAuditing = $Unaudited
        }
        $ExpectedValue = [PSCustomObject]@{
            EnableMailboxAuditing    = $true
            MailboxesWithoutAuditing = @()
        }

        Set-CIPPStandardsCompareField -FieldName 'standards.EnableMailboxAuditing' -CurrentValue $CurrentValue -ExpectedValue $ExpectedValue -Tenant $Tenant
    }

}
