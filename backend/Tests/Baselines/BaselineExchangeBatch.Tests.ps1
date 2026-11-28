# Backlog batch 2: the Exchange cluster. Tests pin the normalization and grading decisions
# that fail silently - wrong-shaped duration compares, per-language contains semantics,
# additive-vs-strict list ownership, and the link write that must never unlink other tags.
# Also hosts the TeamsFederation single-domain array-shape regression.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    $Baselines = Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public'

    function New-CIPPDbRequest { param($TenantFilter, $Type) }
    function Write-LogMessage { param($API, $tenant, $message, $Sev, $LogData) }
    function Get-CIPPDbItem { param($TenantFilter, $Type, [switch]$CountsOnly) }
    function New-ExoRequest { param($tenantid, $cmdlet, $cmdParams, $useSystemMailbox) }
    function New-ExoBulkRequest { param($tenantid, $cmdletArray, $useSystemMailbox, $ReturnWithCommand, $MaxConcurrency, [switch]$AnchorPerMailbox) }
    function Get-CIPPTextReplacement { param($TenantFilter, $Text) $Text }
    function Get-NormalizedError { param($Message) "$Message" }

    function Get-CIPPTable { param($tablename) @{ Name = $tablename } }
    function Get-CIPPAzDataTableEntity { param($Name, $Filter, $Property) }
    . (Join-Path $script:RepoRoot 'Modules/CIPPCore/Public/Get-CIPPDomainExclusionList.ps1')
    . (Join-Path $script:RepoRoot 'Modules/CIPPCore/Public/Get-CIPPIntuneCompareExclusions.ps1')
    . (Join-Path $script:RepoRoot 'Modules/CIPPCore/Public/Compare-CIPPIntuneObject.ps1')
    . (Join-Path $Baselines 'Helpers/Get-CIPPBaselineCommand.ps1')
    . (Join-Path $Baselines 'Helpers/Get-CIPPBaselineCacheRows.ps1')
    . (Join-Path $Baselines 'Helpers/Test-CIPPBaselineCacheCollected.ps1')
    foreach ($Name in @('GlobalQuarantineSettings', 'GlobalQuarantineNotifications', 'UserSubmissions', 'RetentionPolicyTag',
            'SendReceiveLimitTenant', 'AddDKIM', 'RotateDKIM', 'PhishSimSpoofIntelligence', 'PhishingSimulations')) {
        . (Join-Path $Baselines "PrepareHooks/Get-CIPPBaseline${Name}State.ps1")
        . (Join-Path $Baselines "Executors/Invoke-CIPPBaseline${Name}.ps1")
    }

    $script:Tenant = 'contoso.onmicrosoft.com'
    function ConvertTo-Cached { param([Parameter(ValueFromPipeline = $true)]$InputObject) process { $InputObject | ConvertTo-Json -Depth 20 | ConvertFrom-Json } }
    function Get-Verdict {
        param($Expected, $Current)
        $Projected = [PSCustomObject]@{}
        foreach ($Key in $Expected.PSObject.Properties.Name) { $Projected | Add-Member -NotePropertyName $Key -NotePropertyValue $Current.$Key }
        @(Compare-CIPPIntuneObject -ReferenceObject $Expected -DifferenceObject $Projected | Where-Object { $_ })
    }
    Mock Get-CIPPDbItem { [PSCustomObject]@{ RowKey = 'X-Count'; DataCount = 1 } }
}

Describe 'Get-CIPPBaselineGlobalQuarantineSettingsState' {
    BeforeAll {
        $script:GqPolicy = @{ Name = 'DefaultGlobalTag'; Identity = 'DefaultGlobalTag'; MultiLanguageSetting = @('Default', 'Dutch')
            MultiLanguageSenderName = @('IT Alerts', 'IT Meldingen'); ESNCustomSubject = @('Quarantined mail', 'Bericht in quarantaine')
            MultiLanguageCustomDisclaimer = @(); EndUserSpamNotificationCustomFromAddress = 'alerts@contoso.com'; OrganizationBrandingEnabled = $true }
    }

    It 'grades a per-language text as contains: present in ANY language slot is compliant' {
        # The configured value sits in the SECOND language slot on purpose - a first-slot
        # equality compare would miss it and report drift the write cannot clear.
        Mock New-CIPPDbRequest { @($script:GqPolicy | ConvertTo-Cached) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ SenderName = 'IT Meldingen'; OrganizationBrandingEnabled = $true } }
        $Prepared = Get-CIPPBaselineGlobalQuarantineSettingsState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'does not grade fields the baseline leaves empty - the classic graded them as permanent drift' {
        Mock New-CIPPDbRequest { @($script:GqPolicy | ConvertTo-Cached) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ OrganizationBrandingEnabled = $true } }
        $Prepared = Get-CIPPBaselineGlobalQuarantineSettingsState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'senderNamePresent'
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'sends ALL THREE per-language arrays at equal counts, preserving unconfigured values' {
        # Exchange rejects the write outright unless sender, subject and disclaimer arrays
        # all match the language count - and the unconfigured subject must resend the
        # tenant's existing values, not blanks.
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{
            languages = @('Default', 'Dutch'); policyName = 'DefaultGlobalTag'; policyIdentity = 'DefaultGlobalTag'
            currentSenderNames = @('Old', 'Oud'); currentSubjects = @('Quarantined mail', 'Bericht in quarantaine'); currentDisclaimers = @()
        }
        Invoke-CIPPBaselineGlobalQuarantineSettings -Remediate ([PSCustomObject]@{ senderName = 'IT Alerts'; organizationBrandingEnabled = $true }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter {
            $cmdlet -eq 'Set-QuarantinePolicy' -and
            @($cmdParams.MultiLanguageSenderName).Count -eq 2 -and $cmdParams.MultiLanguageSenderName[0] -eq 'IT Alerts' -and
            @($cmdParams.ESNCustomSubject).Count -eq 2 -and $cmdParams.ESNCustomSubject[1] -eq 'Bericht in quarantaine' -and
            @($cmdParams.MultiLanguageCustomDisclaimer).Count -eq 2
        }
    }

    It 'creates the custom global policy when the tenant still runs the Microsoft default' {
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{ languages = @('Default'); policyName = 'DefaultGlobalPolicy'; policyIdentity = 'DefaultGlobalPolicy'; currentSenderNames = @(); currentSubjects = @(); currentDisclaimers = @() }
        Invoke-CIPPBaselineGlobalQuarantineSettings -Remediate ([PSCustomObject]@{ organizationBrandingEnabled = $false }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter { $cmdlet -eq 'New-QuarantinePolicy' -and $cmdParams.Name -eq 'DefaultGlobalTag' }
    }
}

Describe 'Get-CIPPBaselineGlobalQuarantineNotificationsState' {
    It 'normalizes the ISO duration and the timespan string to the same hours' {
        Mock New-CIPPDbRequest { @(@{ Name = 'DefaultGlobalTag'; Identity = 'x'; EndUserSpamNotificationFrequency = 'P1D' } | ConvertTo-Cached) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ NotificationInterval = '1.00:00:00' } }
        $Prepared = Get-CIPPBaselineGlobalQuarantineNotificationsState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'grades an unrecognized tenant interval as drift, never as compliant' {
        Mock New-CIPPDbRequest { @(@{ Name = 'DefaultGlobalTag'; Identity = 'x'; EndUserSpamNotificationFrequency = 'PT15M' } | ConvertTo-Cached) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ NotificationInterval = '04:00:00' } }
        $Prepared = Get-CIPPBaselineGlobalQuarantineNotificationsState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }
}

Describe 'Get-CIPPBaselineUserSubmissionsState' {
    It 'requires ALL THREE report types at the custom address, not just one' {
        Mock New-CIPPDbRequest {
            if ($Type -eq 'ReportSubmissionPolicy') { @(@{ EnableReportToMicrosoft = $true; ReportJunkToCustomizedAddress = $true; ReportJunkAddresses = @('soc@contoso.com'); ReportNotJunkToCustomizedAddress = $false; ReportNotJunkAddresses = @(); ReportPhishToCustomizedAddress = $true; ReportPhishAddresses = @('soc@contoso.com') } | ConvertTo-Cached) }
            else { @(@{ State = 'Enabled'; SentTo = @('soc@contoso.com') } | ConvertTo-Cached) }
        }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ state = 'enable'; email = 'soc@contoso.com' } }
        $Prepared = Get-CIPPBaselineUserSubmissionsState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.customAddressCorrect | Should -BeFalse
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'treats no policy at all as compliant for the disable posture' {
        Mock New-CIPPDbRequest { @() }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ state = 'disable' } }
        $Prepared = Get-CIPPBaselineUserSubmissionsState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'removes an enabled rule when turning reporting off, and only then' {
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{ policyExists = $true; ruleExists = $true; ruleEnabled = $true; resolvedEmail = '' }
        Invoke-CIPPBaselineUserSubmissions -Remediate ([PSCustomObject]@{ state = 'disable' }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter { $cmdlet -eq 'Remove-ReportSubmissionRule' }
    }

    It 'grades reporting-to-Microsoft OFF as compliant for the mailbox-only destination, and as drift without it' {
        # Issue #409: tenants using a third-party phishing service keep EnableReportToMicrosoft
        # off - the mailbox-only destination must not read that as drift.
        Mock New-CIPPDbRequest {
            if ($Type -eq 'ReportSubmissionPolicy') { @(@{ EnableReportToMicrosoft = $false; ReportJunkToCustomizedAddress = $true; ReportJunkAddresses = @('soc@contoso.com'); ReportNotJunkToCustomizedAddress = $true; ReportNotJunkAddresses = @('soc@contoso.com'); ReportPhishToCustomizedAddress = $true; ReportPhishAddresses = @('soc@contoso.com') } | ConvertTo-Cached) }
            else { @(@{ State = 'Enabled'; SentTo = @('soc@contoso.com') } | ConvertTo-Cached) }
        }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ state = 'enable'; email = 'soc@contoso.com'; reportDestination = 'Mailbox' } }
        $Prepared = Get-CIPPBaselineUserSubmissionsState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0

        $Legacy = [PSCustomObject]@{ Variables = [PSCustomObject]@{ state = 'enable'; email = 'soc@contoso.com' } }
        $Prepared = Get-CIPPBaselineUserSubmissionsState -Item $Legacy -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'writes EnableReportToMicrosoft false when remediating the mailbox-only destination' {
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{ policyExists = $true; ruleExists = $true; ruleEnabled = $true; resolvedEmail = 'soc@contoso.com'; reportDestination = 'Mailbox' }
        Invoke-CIPPBaselineUserSubmissions -Remediate ([PSCustomObject]@{ state = 'enable' }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter {
            $cmdlet -eq 'Set-ReportSubmissionPolicy' -and $cmdParams.EnableReportToMicrosoft -eq $false -and $cmdParams.ReportPhishAddresses -eq 'soc@contoso.com'
        }
    }
}

Describe 'Get-CIPPBaselineRetentionPolicyTagState' {
    BeforeAll {
        $script:GoodTag = @{ Identity = 'CIPP Deleted Items'; Name = 'CIPP Deleted Items'; RetentionEnabled = $true; RetentionAction = 'PermanentlyDelete'; AgeLimitForRetention = '30.00:00:00'; Type = 'DeletedItems' }
    }

    It 'grades the MRM policy link separately - an unlinked tag does nothing' {
        Mock New-CIPPDbRequest {
            if ($Type -eq 'ExoRetentionPolicyTags') { @($script:GoodTag | ConvertTo-Cached) }
            else { @(@{ Identity = 'Default MRM Policy'; RetentionPolicyTagLinks = @('Junk Email', '1 Month Delete') } | ConvertTo-Cached) }
        }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ AgeLimitForRetention = 30 } }
        $Prepared = Get-CIPPBaselineRetentionPolicyTagState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.linkedToPolicy | Should -BeFalse
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'resends the FULL link list plus ours - sending only the new tag unlinks everything else' {
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{ tagExists = $true; linkedToPolicy = $false; existingLinks = @('Junk Email', '1 Month Delete') }
        Invoke-CIPPBaselineRetentionPolicyTag -Remediate ([PSCustomObject]@{ ageLimitForRetention = 30 }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter {
            $cmdlet -eq 'Set-RetentionPolicy' -and @($cmdParams.RetentionPolicyTagLinks).Count -eq 3 -and $cmdParams.RetentionPolicyTagLinks -contains 'Junk Email'
        }
    }
}

Describe 'Get-CIPPBaselineSendReceiveLimitTenantState' {
    It 'parses the display-string byte counts and treats Unlimited as an offender' {
        Mock New-CIPPDbRequest { @(
                (@{ DisplayName = 'ExchangeOnlineEnterprise'; MaxSendSize = '35 MB (36,700,160 bytes)'; MaxReceiveSize = '36 MB (37,748,736 bytes)'; Guid = 'g1' } | ConvertTo-Cached),
                (@{ DisplayName = 'ExchangeOnlineDeskless'; MaxSendSize = 'Unlimited'; MaxReceiveSize = '36 MB (37,748,736 bytes)'; Guid = 'g2' } | ConvertTo-Cached)
            ) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ SendLimit = 35; ReceiveLimit = 36 } }
        $Prepared = Get-CIPPBaselineSendReceiveLimitTenantState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.plansOffLimits | Should -Be @('ExchangeOnlineDeskless')
        $Prepared.Current.offenderGuids | Should -Be @('g2')
    }
}

Describe 'Get-CIPPBaselineAddDKIMState' {
    It 'excludes service domains and splits create-vs-enable for the executor' {
        Mock New-CIPPDbRequest {
            if ($Type -eq 'ExoAcceptedDomains') { @(
                    (@{ DomainName = 'contoso.com' } | ConvertTo-Cached),
                    (@{ DomainName = 'contoso.mail.onmicrosoft.com' } | ConvertTo-Cached),
                    (@{ DomainName = 'fabrikam.com' } | ConvertTo-Cached)
                ) }
            else { @(@{ Domain = 'fabrikam.com'; Enabled = $false } | ConvertTo-Cached) }
        }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{} }
        $Prepared = Get-CIPPBaselineAddDKIMState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.domainsToCreate | Should -Be @('contoso.com')
        $Prepared.Current.domainsToEnable | Should -Be @('fabrikam.com')
        $Prepared.Current.domainsWithoutDkim | Should -Not -Contain 'contoso.mail.onmicrosoft.com'
    }

    It 'also skips domains matching the global exclusion list' {
        Mock Get-CIPPAzDataTableEntity { [pscustomobject]@{ DomainExclusions = '["*.voice.fabrikam.com"]' } }
        Mock New-CIPPDbRequest {
            if ($Type -eq 'ExoAcceptedDomains') { @(
                    (@{ DomainName = 'contoso.com' } | ConvertTo-Cached),
                    (@{ DomainName = 'tenant1.voice.fabrikam.com' } | ConvertTo-Cached)
                ) }
        }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{} }
        (Get-CIPPBaselineAddDKIMState -Item $Item -TenantFilter $script:Tenant).Current.domainsWithoutDkim | Should -Be @('contoso.com')
    }
}

Describe 'Get-CIPPBaselineRotateDKIMState' {
    It 'grades only ENABLED configs on 1024-bit keys - rotating a disabled config does nothing' {
        Mock New-CIPPDbRequest { @(
                (@{ Identity = 'contoso.com'; Selector1KeySize = 1024; Selector2KeySize = 2048; Enabled = $true } | ConvertTo-Cached),
                (@{ Identity = 'fabrikam.com'; Selector1KeySize = 1024; Selector2KeySize = 1024; Enabled = $false } | ConvertTo-Cached),
                (@{ Identity = 'tailspin.com'; Selector1KeySize = 2048; Selector2KeySize = 2048; Enabled = $true } | ConvertTo-Cached)
            ) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{} }
        (Get-CIPPBaselineRotateDKIMState -Item $Item -TenantFilter $script:Tenant).Current.domainsWith1024BitDkim | Should -Be @('contoso.com')
    }
}

Describe 'Get-CIPPBaselinePhishSimSpoofIntelligenceState' {
    It 'is additive by default: hand-added spoof allowances are not drift' {
        Mock New-CIPPDbRequest { @(
                (@{ Identity = 'id1'; SendingInfrastructure = 'sim.knowbe4.com' } | ConvertTo-Cached),
                (@{ Identity = 'id2'; SendingInfrastructure = 'operator-added.example' } | ConvertTo-Cached)
            ) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ AllowedDomains = @('sim.knowbe4.com'); RemoveExtraDomains = $false } }
        $Prepared = Get-CIPPBaselinePhishSimSpoofIntelligenceState -Item $Item -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'strict mode grades extras and carries their item ids for removal' {
        Mock New-CIPPDbRequest { @(@{ Identity = 'id2'; SendingInfrastructure = 'operator-added.example' } | ConvertTo-Cached) }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ AllowedDomains = @('sim.knowbe4.com'); RemoveExtraDomains = $true } }
        $Prepared = Get-CIPPBaselinePhishSimSpoofIntelligenceState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.extraDomains | Should -Contain 'operator-added.example'
        $Prepared.Current.extraItemIds | Should -Be @('id2')
    }

    It 'writes each missing domain as BOTH Internal and External spoof types' {
        Mock New-ExoBulkRequest { @() }
        $Current = [PSCustomObject]@{ missingDomains = @('sim.knowbe4.com'); extraItemIds = @() }
        Invoke-CIPPBaselinePhishSimSpoofIntelligence -Remediate $null -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoBulkRequest -Times 1 -Exactly -ParameterFilter {
            @($cmdletArray).Count -eq 2 -and @($cmdletArray.CmdletInput.Parameters.SpoofType) -contains 'Internal' -and @($cmdletArray.CmdletInput.Parameters.SpoofType) -contains 'External'
        }
    }
}

Describe 'Get-CIPPBaselinePhishingSimulationsState' {
    BeforeAll {
        $script:PsItem = [PSCustomObject]@{ Variables = [PSCustomObject]@{
                Domains = @('sim.example.com'); SenderIpRanges = @('10.1.1.0/24'); PhishingSimUrls = @('https://sim.example.com/*'); RemoveExtraUrls = $false } }
    }

    It 'grades the three legs separately so the drift row names the broken one' {
        Mock New-CIPPDbRequest {
            switch ($Type) {
                'ExoPhishSimOverridePolicy' { @(@{ Name = 'PhishSimOverridePolicy'; Enabled = $true } | ConvertTo-Cached) }
                'ExoPhishSimOverrideRule' { @(@{ Name = 'PhishSimOverrideRule'; Identity = 'r1'; SenderIpRanges = @('10.1.1.0/24'); Domains = @() } | ConvertTo-Cached) }
                default { @(@{ Value = 'https://sim.example.com/*' } | ConvertTo-Cached) }
            }
        }
        $Prepared = Get-CIPPBaselinePhishingSimulationsState -Item $script:PsItem -TenantFilter $script:Tenant
        $Prepared.Current.policyEnabled | Should -BeTrue
        $Prepared.Current.missingDomains | Should -Be @('sim.example.com')
        @($Prepared.Current.missingUrls).Count | Should -Be 0
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'uses add/remove DELTAS on an existing rule, never replacement lists' {
        Mock New-ExoRequest { }
        $Current = [PSCustomObject]@{
            policyEnabled = $true; policyExists = $true; ruleExists = $true; ruleIdentity = 'r1'
            missingDomains = @('sim.example.com'); missingSenderIpRanges = @(); extraDomains = @('old.example.com'); extraSenderIpRanges = @()
            missingUrls = @(); extraUrls = @()
        }
        Invoke-CIPPBaselinePhishingSimulations -Remediate ([PSCustomObject]@{ domains = @('sim.example.com'); senderIpRanges = @('10.1.1.0/24') }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -Exactly -ParameterFilter {
            $cmdlet -eq 'Set-ExoPhishSimOverrideRule' -and $cmdParams.AddDomains -contains 'sim.example.com' -and $cmdParams.RemoveDomains -contains 'old.example.com'
        }
    }
}

Describe 'Get-CIPPBaselineSpamFilterPolicyState block-list write params' {
    BeforeAll {
        . (Join-Path (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public') 'PrepareHooks/Get-CIPPBaselineSpamFilterPolicyState.ps1')
        $script:SpamPolicy = @{ Name = 'CIPP Default Spam Filter Policy'; EnableRegionBlockList = $true; EnableLanguageBlockList = $false }
        $script:SpamRule = @{ Name = 'CIPP Default Spam Filter Policy'; State = 'Enabled'; Priority = 0; HostedContentFilterPolicy = 'CIPP Default Spam Filter Policy'; RecipientDomainIs = @('contoso.com') }
    }
    BeforeEach {
        Mock New-CIPPDbRequest {
            switch ($Type) {
                'ExoHostedContentFilterPolicy' { @($script:SpamPolicy | ConvertTo-Cached) }
                'ExoHostedContentFilterRule' { @($script:SpamRule | ConvertTo-Cached) }
                'ExoAcceptedDomains' { @(@{ Name = 'contoso.com' } | ConvertTo-Cached) }
            }
        }
    }

    It 'forces the block-list switches OFF in the write when disabled - omitting them left a tenant-side On in place forever' {
        # The classic explicitly wrote EnableRegionBlockList=$false when disabled; the
        # rendered spec omitted it, so grade said Off while the tenant stayed On (proven
        # live: enableRegionBlockList exp=false got=true after a clean remediation).
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ EnableRegionBlockList = $false } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.extraPolicyParams.PSObject.Properties.Name | Should -Contain 'EnableRegionBlockList'
        $Prepared.Current.extraPolicyParams.PSObject.Properties.Name | Should -Contain 'EnableLanguageBlockList'
        $Prepared.Current.extraPolicyParams.EnableRegionBlockList | Should -BeFalse
        $Prepared.Current.extraPolicyParams.EnableLanguageBlockList | Should -BeFalse
        $Prepared.Current.extraPolicyParams.PSObject.Properties.Name | Should -Not -Contain 'RegionBlockList'
        $Prepared.Expected.enableRegionBlockList | Should -BeFalse
    }

    It 'writes the switch AND the normalized list when enabled with entries, exactly as graded' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ EnableRegionBlockList = $true; RegionBlockList = @('ru', 'kp') } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.extraPolicyParams.EnableRegionBlockList | Should -BeTrue
        @($Prepared.Current.extraPolicyParams.RegionBlockList) | Should -BeExactly @('KP', 'RU')
        $Prepared.Expected.enableRegionBlockList | Should -BeTrue
    }

    It 'never grades or writes BulkMovesEnabled unless explicitly configured - the parameter is in Preview and not available in every organization' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'bulkMovesEnabled'
        $Prepared.Current.extraPolicyParams.PSObject.Properties.Name | Should -Not -Contain 'BulkMovesEnabled'
    }

    It 'grades and writes BulkMovesEnabled when configured On, unwrapping an option wrapper if the picker saved one' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ BulkMovesEnabled = [PSCustomObject]@{ label = 'On'; value = 'On' } } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Expected.bulkMovesEnabled | Should -BeExactly 'On'
        $Prepared.Current.extraPolicyParams.BulkMovesEnabled | Should -BeExactly 'On'
    }

    It 'writes the allowed sender domains it grades' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ AllowedSenderDomains = @('b.example.com', 'a.example.com') } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        @($Prepared.Current.extraPolicyParams.AllowedSenderDomains) | Should -BeExactly @('a.example.com', 'b.example.com')
    }

    It 'clears the allowed sender domains on the existing policy when the list is blank' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ AllowedSenderDomains = @() } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.extraPolicyParams.AllowedSenderDomains['@odata.type'] | Should -Be '#Exchange.GenericHashTable'
        $Prepared.Current.extraPolicyParams.AllowedSenderDomains.Keys.Count | Should -Be 1
    }
}

Describe 'Get-CIPPBaselineSpamFilterPolicyState policy resolution' {
    BeforeAll {
        . (Join-Path (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public') 'PrepareHooks/Get-CIPPBaselineSpamFilterPolicyState.ps1')
    }
    BeforeEach {
        Mock New-CIPPDbRequest {
            switch ($Type) {
                'ExoHostedContentFilterPolicy' { @(@{ Name = 'Default'; IsDefault = $true } | ConvertTo-Cached) }
                'ExoAcceptedDomains' { @(@{ Name = 'contoso.com' } | ConvertTo-Cached) }
            }
        }
    }

    It 'creates a custom-named policy and its rule instead of adopting the built-in Default' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ name = 'Contoso Spam Policy' } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.policyName | Should -BeExactly 'Contoso Spam Policy'
        $Prepared.Current.policyExists | Should -BeFalse
        $Prepared.Current.skipRule | Should -BeFalse
        $Prepared.Expected.rule.priority | Should -Be 0
    }

    It 'adopts the built-in Default policy when the configured name is the portal alias' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ name = 'Anti-spam inbound policy' } }
        $Prepared = Get-CIPPBaselineSpamFilterPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.policyName | Should -BeExactly 'Default'
        $Prepared.Current.skipRule | Should -BeTrue
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'rule'
    }
}

Describe 'Get-CIPPBaselineSafeLinksPolicyState DoNotRewriteUrls write' {
    BeforeAll {
        . (Join-Path (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public') 'PrepareHooks/Get-CIPPBaselineSafeLinksPolicyState.ps1')
    }
    BeforeEach {
        $script:SafeLinksPolicies = @(@{ Name = 'CIPP Default SafeLinks Policy'; DoNotRewriteUrls = @('old.example.com') })
        Mock New-CIPPDbRequest {
            switch ($Type) {
                'ExoSafeLinksPolicies' { @($script:SafeLinksPolicies | ConvertTo-Cached) }
                'ExoSafeLinksRules' { @(@{ Name = 'CIPP Default SafeLinks Policy_Rule'; SafeLinksPolicy = 'CIPP Default SafeLinks Policy'; Priority = 0 } | ConvertTo-Cached) }
                'ExoAcceptedDomains' { @(@{ Name = 'contoso.com' } | ConvertTo-Cached) }
            }
        }
    }

    It 'writes the configured URLs' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ DoNotRewriteUrls = @('new.example.com') } }
        $Prepared = Get-CIPPBaselineSafeLinksPolicyState -Item $Item -TenantFilter $script:Tenant
        @($Prepared.Current.extraPolicyParams.DoNotRewriteUrls) | Should -BeExactly @('new.example.com')
    }

    It 'clears the URLs on the existing policy when the list is blank, matching the empty list it grades' {
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ DoNotRewriteUrls = '' } }
        $Prepared = Get-CIPPBaselineSafeLinksPolicyState -Item $Item -TenantFilter $script:Tenant
        @($Prepared.Expected.doNotRewriteUrls).Count | Should -Be 0
        $Prepared.Current.extraPolicyParams.DoNotRewriteUrls['@odata.type'] | Should -Be '#Exchange.GenericHashTable'
    }

    It 'sends nothing for a blank list when the policy is being created' {
        $script:SafeLinksPolicies = @(@{ Name = 'Some Other Policy' })
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ DoNotRewriteUrls = '' } }
        $Prepared = Get-CIPPBaselineSafeLinksPolicyState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Current.policyExists | Should -BeFalse
        $Prepared.Current.extraPolicyParams.PSObject.Properties.Name | Should -Not -Contain 'DoNotRewriteUrls'
    }
}

Describe 'Get-CIPPBaselineSpoofWarnState allow list' {
    BeforeAll {
        . (Join-Path (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public') 'PrepareHooks/Get-CIPPBaselineSpoofWarnState.ps1')
        $script:Grade = {
            param($Allow, $TenantList)
            $script:ExternalInOutlook = @{ Enabled = $true; AllowList = $TenantList }
            $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ externalWarningEnabled = $true; allowListAdd = $Allow } }
            $Prepared = Get-CIPPBaselineSpoofWarnState -Item $Item -TenantFilter $script:Tenant
            @(Compare-CIPPIntuneObject -ReferenceObject $Prepared.Expected -DifferenceObject $Prepared.Current | Where-Object { $_ })
        }
    }
    BeforeEach {
        Mock New-CIPPDbRequest { if ($Type -eq 'ExoExternalInOutlook') { @($script:ExternalInOutlook | ConvertTo-Cached) } }
    }

    It 'drifts when a configured entry is missing from the tenant' {
        $Diff = & $script:Grade @('sim.example.com', 'vendor.example.com') @('vendor.example.com')
        @($Diff.Property -like 'AllowList*').Count | Should -BeGreaterThan 0
    }

    It 'is compliant when every configured entry is present, ignoring case and entries added elsewhere' {
        @(& $script:Grade @('Sim.Example.com') @('sim.example.com', 'portal-added.example.com', '')).Count | Should -Be 0
    }

    It 'is compliant with a blank list - the allow list is add-only' {
        @(& $script:Grade @() @('portal-added.example.com')).Count | Should -Be 0
    }

    It 'still grades the warning switch' {
        $script:ExternalInOutlook = @{ Enabled = $false; AllowList = @() }
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ externalWarningEnabled = $true; allowListAdd = @() } }
        $Prepared = Get-CIPPBaselineSpoofWarnState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Expected.Enabled | Should -BeTrue
        $Prepared.Current.Enabled | Should -BeFalse
    }
}

Describe 'Get-CIPPBaselineMailboxDefaultAuditSetState' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public/PrepareHooks/Get-CIPPBaselineMailboxDefaultAuditSetState.ps1')
        . (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public/Executors/Invoke-CIPPBaselineMailboxDefaultAuditSet.ps1')
        $script:AuditMailboxes = @(
            @{ UPN = 'default@contoso.com'; recipientTypeDetails = 'UserMailbox'; DefaultAuditSet = @('Admin', 'Delegate', 'Owner') }
            @{ UPN = 'owner@contoso.com'; recipientTypeDetails = 'UserMailbox'; DefaultAuditSet = @('Admin', 'Delegate') }
            @{ UPN = 'shared@contoso.com'; recipientTypeDetails = 'SharedMailbox'; DefaultAuditSet = @() }
            @{ UPN = 'room@contoso.com'; recipientTypeDetails = 'RoomMailbox'; DefaultAuditSet = @('Owner') }
            @{ UPN = 'discovery@contoso.com'; recipientTypeDetails = 'DiscoveryMailbox'; DefaultAuditSet = @() }
        ) | ConvertTo-Cached
    }

    It 'offends every mailbox type it can write that is missing any default sign-in type' {
        Mock New-CIPPDbRequest { $script:AuditMailboxes }
        $Prepared = Get-CIPPBaselineMailboxDefaultAuditSetState -Item ([PSCustomObject]@{}) -TenantFilter $script:Tenant
        $Prepared.Current.offenders | Should -Be @('owner@contoso.com', 'room@contoso.com', 'shared@contoso.com')
        (Get-Verdict -Expected ([PSCustomObject]@{ offenders = @() }) -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'is compliant when every mailbox still uses the default set' {
        Mock New-CIPPDbRequest { @($script:AuditMailboxes[0]) }
        $Prepared = Get-CIPPBaselineMailboxDefaultAuditSetState -Item ([PSCustomObject]@{}) -TenantFilter $script:Tenant
        (Get-Verdict -Expected ([PSCustomObject]@{ offenders = @() }) -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'reports No Data when the cache is empty' {
        Mock New-CIPPDbRequest { @() }
        (Get-CIPPBaselineMailboxDefaultAuditSetState -Item ([PSCustomObject]@{}) -TenantFilter $script:Tenant).Current | Should -BeNullOrEmpty
    }

    It 'writes Set-Mailbox -DefaultAuditSet Admin,Delegate,Owner anchored to each mailbox, concurrently' {
        Mock New-ExoBulkRequest {}
        $Current = [PSCustomObject]@{ targets = @([PSCustomObject]@{ id = 'a@contoso.com' }, [PSCustomObject]@{ id = 'b@contoso.com' }) }
        Invoke-CIPPBaselineMailboxDefaultAuditSet -Remediate $null -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoBulkRequest -Times 1 -ParameterFilter {
            $AnchorPerMailbox -and $MaxConcurrency -eq 10 -and @($cmdletArray).Count -eq 2 -and
            @($cmdletArray)[1].OperationGuid -eq 'b@contoso.com' -and
            @($cmdletArray)[1].CmdletInput.CmdletName -eq 'Set-Mailbox' -and
            @($cmdletArray)[1].CmdletInput.Parameters.Identity -eq 'b@contoso.com' -and
            (@($cmdletArray)[1].CmdletInput.Parameters.DefaultAuditSet -join ',') -eq 'Admin,Delegate,Owner'
        }
    }

    It 'continues past a failed mailbox and throws only when every write failed' {
        Mock Write-LogMessage {}
        $Current = [PSCustomObject]@{ targets = @([PSCustomObject]@{ id = 'a@contoso.com' }, [PSCustomObject]@{ id = 'b@contoso.com' }) }
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ error = 'proxy'; OperationGuid = 'a@contoso.com' }, [PSCustomObject]@{ Success = $true; OperationGuid = 'b@contoso.com' }) }
        { Invoke-CIPPBaselineMailboxDefaultAuditSet -Remediate $null -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $message -like '*1 of 2*a@contoso.com -> proxy*' }
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ error = 'proxy'; OperationGuid = 'a@contoso.com' }, [PSCustomObject]@{ error = 'proxy'; OperationGuid = 'b@contoso.com' }) }
        { Invoke-CIPPBaselineMailboxDefaultAuditSet -Remediate $null -TenantFilter $script:Tenant -Current $Current } | Should -Throw '*all 2 writes failed*a@contoso.com -> proxy*'
    }
}

Describe 'Get-CIPPBaselineEnableMailboxAuditingState' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public/PrepareHooks/Get-CIPPBaselineEnableMailboxAuditingState.ps1')
        . (Join-Path $script:RepoRoot 'Modules/CIPPBaselines/Public/Executors/Invoke-CIPPBaselineEnableMailboxAuditing.ps1')
        $script:Enforce = [PSCustomObject]@{ Variables = [PSCustomObject]@{ auditDisabled = $false } }
    }

    BeforeEach {
        Mock Write-LogMessage {}
        Mock New-CIPPDbRequest {
            switch ($Type) {
                'ExoOrganizationConfig' { @($script:OrgConfig | ConvertTo-Cached) }
                'Mailboxes' { @($script:Mailboxes | ConvertTo-Cached) }
                'ExoMailboxAuditBypass' { @($script:Bypass | ConvertTo-Cached) }
            }
        }
        $script:OrgConfig = @(@{ AuditDisabled = $false })
        $script:Bypass = @()
        $script:Mailboxes = @(
            @{ UPN = 'user@contoso.com'; recipientTypeDetails = 'UserMailbox'; AuditEnabled = $false }
            @{ UPN = 'room2@contoso.com'; recipientTypeDetails = 'RoomMailbox'; AuditEnabled = $false }
            @{ UPN = 'room1@contoso.com'; recipientTypeDetails = 'RoomMailbox'; AuditEnabled = $true }
            @{ UPN = 'equip@contoso.com'; recipientTypeDetails = 'EquipmentMailbox'; AuditEnabled = 'False' }
            @{ UPN = 'discovery@contoso.com'; recipientTypeDetails = 'DiscoveryMailbox'; AuditEnabled = $false }
            @{ UPN = 'bookings@contoso.com'; recipientTypeDetails = 'SchedulingMailbox'; AuditEnabled = $false }
            @{ UPN = 'old@contoso.com'; recipientTypeDetails = 'RoomMailbox' }
        )
    }

    It 'reports drift for mailboxes outside the tenant default that have auditing off, with the tenant flag correct' {
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $Prepared.Current.MailboxesWithoutAuditing | Should -Be @('bookings@contoso.com', 'discovery@contoso.com', 'equip@contoso.com', 'room2@contoso.com')
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'is compliant when the tenant flag is set and every such mailbox has auditing on' {
        $script:Mailboxes = @($script:Mailboxes[0], $script:Mailboxes[2])
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'reports drift for accounts with audit bypass enabled and hands their ids to the executor' {
        $script:Mailboxes = @($script:Mailboxes[2])
        $script:Bypass = @(@{ Name = 'svc-b'; Guid = 'bbbbbbbb-0000-0000-0000-000000000002' }, @{ Name = 'svc-a'; Guid = 'aaaaaaaa-0000-0000-0000-000000000001' })
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $Prepared.Current.AccountsWithAuditBypass | Should -Be @('svc-a', 'svc-b')
        @($Prepared.Current.bypassTargets.id) | Should -Contain 'aaaaaaaa-0000-0000-0000-000000000001'
        $script:Bypass = @(@{ Name = 'no-id' })
        $NoId = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $NoId.Current.AccountsWithAuditBypass | Should -Be @('no-id')
        @($NoId.Current.bypassTargets).Count | Should -Be 0
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'bypassTargets'
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'reports No Data when the audit bypass list was never collected' {
        Mock Get-CIPPDbItem {}
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $Prepared.Current | Should -BeNullOrEmpty
        $Prepared.NoDataReason | Should -BeLike '*audit bypass*'
    }

    It 'still grades the tenant flag' {
        $script:OrgConfig = @(@{ AuditDisabled = $true })
        $script:Mailboxes = @($script:Mailboxes[2])
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -BeGreaterThan 0
    }

    It 'does not grade mailboxes when the operator deliberately keeps auditing off' {
        $script:OrgConfig = @(@{ AuditDisabled = $true })
        $script:Mailboxes = @()
        $Item = [PSCustomObject]@{ Variables = [PSCustomObject]@{ auditDisabled = $true } }
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $Item -TenantFilter $script:Tenant
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'MailboxesWithoutAuditing'
        $Prepared.Expected.PSObject.Properties.Name | Should -Not -Contain 'AccountsWithAuditBypass'
        (Get-Verdict -Expected $Prepared.Expected -Current $Prepared.Current).Count | Should -Be 0
    }

    It 'names why it cannot grade when the organization config or the mailbox list is missing' {
        $script:Mailboxes = @()
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $Prepared.Current | Should -BeNullOrEmpty
        $Prepared.NoDataReason | Should -BeLike '*mailbox list*'
        $script:OrgConfig = @()
        $Prepared = Get-CIPPBaselineEnableMailboxAuditingState -Item $script:Enforce -TenantFilter $script:Tenant
        $Prepared.Current | Should -BeNullOrEmpty
        $Prepared.NoDataReason | Should -BeLike '*organization settings*'
    }

    It 'turns auditing on per mailbox, anchored to each mailbox' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ Success = $true; OperationGuid = 'a@contoso.com' }, [PSCustomObject]@{ Success = $true; OperationGuid = 'b@contoso.com' }) }
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com', 'b@contoso.com') }
        Invoke-CIPPBaselineEnableMailboxAuditing -Remediate ([PSCustomObject]@{ auditDisabled = $false }) -TenantFilter $script:Tenant -Current $Current | Should -BeNullOrEmpty
        Should -Invoke New-ExoRequest -Times 0
        Should -Invoke New-ExoBulkRequest -Times 1 -ParameterFilter {
            $AnchorPerMailbox -and $MaxConcurrency -eq 10 -and @($cmdletArray).Count -eq 2 -and
            @($cmdletArray)[1].OperationGuid -eq 'b@contoso.com' -and
            @($cmdletArray)[1].CmdletInput.CmdletName -eq 'Set-Mailbox' -and
            @($cmdletArray)[1].CmdletInput.Parameters.Identity -eq 'b@contoso.com' -and
            @($cmdletArray)[1].CmdletInput.Parameters.AuditEnabled -eq $true
        }
    }

    It 'sets the tenant flag only when it differs and leaves mailboxes alone when auditing is kept off' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest {}
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com') }
        Invoke-CIPPBaselineEnableMailboxAuditing -Remediate ([PSCustomObject]@{ auditDisabled = $true }) -TenantFilter $script:Tenant -Current $Current
        Should -Invoke New-ExoRequest -Times 1 -ParameterFilter { $cmdlet -eq 'Set-OrganizationConfig' -and $cmdParams.AuditDisabled -eq $true }
        Should -Invoke New-ExoBulkRequest -Times 0
    }

    It 'clears audit bypass by id, without a mailbox anchor' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ Success = $true; OperationGuid = 'aaaaaaaa-0000-0000-0000-000000000001' }) }
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @(); bypassTargets = @([PSCustomObject]@{ id = 'aaaaaaaa-0000-0000-0000-000000000001'; name = 'svc-a' }) }
        Invoke-CIPPBaselineEnableMailboxAuditing -Remediate ([PSCustomObject]@{ auditDisabled = $false }) -TenantFilter $script:Tenant -Current $Current | Should -BeNullOrEmpty
        Should -Invoke New-ExoBulkRequest -Times 1 -ParameterFilter {
            -not $AnchorPerMailbox -and @($cmdletArray).Count -eq 1 -and
            @($cmdletArray)[0].CmdletInput.CmdletName -eq 'Set-MailboxAuditBypassAssociation' -and
            @($cmdletArray)[0].CmdletInput.Parameters.Identity -eq 'aaaaaaaa-0000-0000-0000-000000000001' -and
            @($cmdletArray)[0].CmdletInput.Parameters.AuditBypassEnabled -eq $false
        }
    }

    It 'names the account when clearing audit bypass fails' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest {
            if (@($cmdletArray)[0].CmdletInput.CmdletName -eq 'Set-Mailbox') { [PSCustomObject]@{ Success = $true; OperationGuid = 'a@contoso.com' } }
            else { [PSCustomObject]@{ error = 'denied'; OperationGuid = 'aaaaaaaa-0000-0000-0000-000000000001' } }
        }
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com'); bypassTargets = @([PSCustomObject]@{ id = 'aaaaaaaa-0000-0000-0000-000000000001'; name = 'svc-a' }) }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate ([PSCustomObject]@{ auditDisabled = $false }) -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $message -like '*1 of 2*svc-a (audit bypass) -> denied*' }
    }

    It 'still clears audit bypass when the mailbox writes throw, and does not fail a run that changed the tenant flag' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest {
            if (@($cmdletArray)[0].CmdletInput.CmdletName -eq 'Set-Mailbox') { throw 'exchange down' }
            [PSCustomObject]@{ Success = $true; OperationGuid = 'aaaaaaaa-0000-0000-0000-000000000001' }
        }
        $Remediate = [PSCustomObject]@{ auditDisabled = $false }
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com'); bypassTargets = @([PSCustomObject]@{ id = 'aaaaaaaa-0000-0000-0000-000000000001'; name = 'svc-a' }) }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke New-ExoBulkRequest -Times 1 -ParameterFilter { @($cmdletArray)[0].CmdletInput.CmdletName -eq 'Set-MailboxAuditBypassAssociation' }
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $message -like '*1 of 2*a@contoso.com -> exchange down*' }

        $Current = [PSCustomObject]@{ AuditDisabled = $true; MailboxesWithoutAuditing = @('a@contoso.com') }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke New-ExoRequest -Times 1 -ParameterFilter { $cmdlet -eq 'Set-OrganizationConfig' }
    }

    It 'reports no change when the tenant flag and every mailbox are already right' {
        Mock New-ExoRequest {}
        Mock New-ExoBulkRequest {}
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @() }
        (Invoke-CIPPBaselineEnableMailboxAuditing -Remediate ([PSCustomObject]@{ auditDisabled = $false }) -TenantFilter $script:Tenant -Current $Current).Changed | Should -BeFalse
        Should -Invoke New-ExoRequest -Times 0
        Should -Invoke New-ExoBulkRequest -Times 0
    }

    It 'counts a mailbox Exchange did not answer for as failed' {
        Mock New-ExoRequest {}
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com', 'b@contoso.com') }
        $Remediate = [PSCustomObject]@{ auditDisabled = $false }
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ Success = $true; OperationGuid = 'b@contoso.com' }) }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $message -like '*1 of 2*a@contoso.com -> no response*' }
        Mock New-ExoBulkRequest {}
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Throw '*all 2 writes failed*'
    }

    It 'continues past a failed mailbox and throws only when every write failed' {
        Mock New-ExoRequest {}
        $Current = [PSCustomObject]@{ AuditDisabled = $false; MailboxesWithoutAuditing = @('a@contoso.com', 'b@contoso.com') }
        $Remediate = [PSCustomObject]@{ auditDisabled = $false }
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ error = 'proxy'; OperationGuid = 'a@contoso.com' }, [PSCustomObject]@{ Success = $true; OperationGuid = 'b@contoso.com' }) }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Not -Throw
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $message -like '*1 of 2*a@contoso.com -> proxy*' }
        Mock New-ExoBulkRequest { @([PSCustomObject]@{ error = 'proxy'; OperationGuid = 'a@contoso.com' }, [PSCustomObject]@{ error = 'proxy'; OperationGuid = 'b@contoso.com' }) }
        { Invoke-CIPPBaselineEnableMailboxAuditing -Remediate $Remediate -TenantFilter $script:Tenant -Current $Current } | Should -Throw '*all 2 writes failed*a@contoso.com -> proxy*'
    }
}
