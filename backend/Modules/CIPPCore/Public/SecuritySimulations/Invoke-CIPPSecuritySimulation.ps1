function Invoke-CIPPSecuritySimulation {
    <#
    .SYNOPSIS
        Plays one security scenario against one tenant and reports how it would go.
    .DESCRIPTION
        For every step of the scenario: the standards tagged to that step are graded (alignment row if
        assigned, engine -GradeOnly otherwise), a whatIf step is evaluated live through the What If API for
        the scenario's persona, and alert steps check whether an audit-log alert rule would fire.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$TenantFilter,
        [Parameter(Mandatory = $true)]$ScenarioId
    )

    $Scenario = Get-CIPPSecuritySimulationDefinition -Id $ScenarioId | Select-Object -First 1
    if (-not $Scenario) { throw "Unknown scenario '$ScenarioId'." }

    $Definitions = @(Get-CIPPBaselineDefinition)
    $StandardMap = Get-CIPPSecuritySimulationStandardMap -Definitions $Definitions
    $StepStandards = if ($StandardMap.ContainsKey("$($Scenario.id)")) { $StandardMap["$($Scenario.id)"] } else { @{} }

    $Capabilities = $(try { Get-CIPPTenantCapabilities -TenantFilter $TenantFilter } catch { $null })
    $Required = @($Scenario.requiredCapabilities | Where-Object { $_ })
    $Licensed = $Required.Count -eq 0 -or @($Required | Where-Object { $Capabilities.$_ -eq $true }).Count -gt 0

    $AlignmentTable = Get-CippTable -tablename 'BaselineAlignment'
    $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $TenantFilter
    $AlignmentRows = @(Get-CIPPAzDataTableEntity @AlignmentTable -Filter "PartitionKey eq '$SafeTenant'")

    $Steps = @($Scenario.steps | Where-Object { $_ })
    $NeedsIdentity = @($Steps | Where-Object { $_.whatIf }).Count -gt 0
    $NeedsAlerts = @($Steps | Where-Object { $_.alerts }).Count -gt 0
    $Rules = if ($NeedsAlerts) { @(Get-CIPPSimulationAlertRules -TenantFilter $TenantFilter) } else { @() }
    $Persona = $(if ("$($Scenario.persona)") { "$($Scenario.persona)" } else { 'user' })
    $Identity = if ($NeedsIdentity -and $Licensed) { Resolve-CIPPSimulationIdentity -TenantFilter $TenantFilter -Persona $Persona } else { $null }
    $AttackerCanSatisfy = @($Scenario.attackerCanSatisfy | Where-Object { $_ })

    $WhatIfCalls = 0
    $Results = [System.Collections.Generic.List[object]]::new()
    $Reached = $true
    $ReachedWhenFixed = $true
    $PreventedAt = $null
    $PreventedWhenFixedAt = $null
    $Index = 0

    foreach ($Step in $Steps) {
        $Index++
        $StepId = "$($Step.id)"
        $Standards = [System.Collections.Generic.List[object]]::new()
        if ($StepStandards.ContainsKey($StepId)) {
            foreach ($Entry in $StepStandards[$StepId]) {
                $Standards.Add((Get-CIPPSimulationStandardState -TenantFilter $TenantFilter -Definition $Entry.Definition -Role $Entry.Role -AlignmentRows $AlignmentRows -Capabilities $Capabilities))
            }
        }

        $Alerts = [System.Collections.Generic.List[object]]::new()
        foreach ($Alert in @($Step.alerts | Where-Object { $_ })) {
            $Alerts.Add((Test-CIPPSimulationAlertRule -Rules $Rules -Operation "$($Alert.operation)" -Logbook "$($Alert.logbook)" -Preset "$($Alert.preset)"))
        }

        $WhatIf = $null
        if ($Step.whatIf) {
            if (-not $Licensed) {
                $WhatIf = [PSCustomObject]@{ verdict = 'unknown'; detail = 'unlicensed'; error = 'This tenant is not licensed for Conditional Access.'; gaps = @(); policies = @() }
            } elseif (-not $Identity) {
                $WhatIf = [PSCustomObject]@{ verdict = 'unknown'; detail = 'noIdentity'; error = "No $Persona account is available in the cache to evaluate this sign-in."; gaps = @(); policies = @() }
            } else {
                $Body = New-CIPPCAWhatIfRequest -UserId $Identity.userId -IncludeApplications $Step.whatIf.includeApplications -Conditions ($Step.whatIf | Select-Object -Property * -ExcludeProperty includeApplications)
                $WhatIfCalls++
                $Evaluation = @(Invoke-CIPPCAWhatIf -TenantFilter $TenantFilter -Bodies @($Body))[0]
                if ($Evaluation.Error) {
                    $WhatIf = [PSCustomObject]@{ verdict = 'unknown'; detail = 'error'; error = "$($Evaluation.Error)"; gaps = @(); policies = @() }
                } else {
                    $Verdict = Get-CIPPCAWhatIfVerdict -Policies $Evaluation.Policies -AttackerCanSatisfy $AttackerCanSatisfy
                    $Gaps = [System.Collections.Generic.List[object]]::new()
                    foreach ($Gap in @($Step.gaps | Where-Object { $_ })) {
                        $GapRequired = @($Gap.requiredCapabilities | Where-Object { $_ })
                        $GapLicensed = $GapRequired.Count -eq 0 -or @($GapRequired | Where-Object { $Capabilities.$_ -eq $true }).Count -gt 0
                        $When = @($Gap.when | Where-Object { $_ } | ForEach-Object { "$_".ToLower() })
                        $Triggered = $GapLicensed -and (
                            ($When -contains 'allowed' -and $Verdict.verdict -eq 'allowed') -or
                            ($When -contains 'weakgrant' -and $Verdict.detail -eq 'grantSatisfied') -or
                            ($When -contains 'reportonly' -and @($Verdict.reportOnlyWouldStop).Count -gt 0)
                        )
                        $Gaps.Add([PSCustomObject]@{
                                text       = "$($Gap.text)"
                                role       = $(if ("$($Gap.role)") { "$($Gap.role)" } else { 'prevents' })
                                fix        = $Gap.fix
                                triggered  = [bool]$Triggered
                                unlicensed = -not $GapLicensed
                            })
                    }
                    $WhatIf = [PSCustomObject]@{
                        verdict             = $Verdict.verdict
                        detail              = $Verdict.detail
                        requiredControls    = @($Verdict.requiredControls)
                        blockedBy           = @($Verdict.blockedBy)
                        challengedBy        = @($Verdict.challengedBy)
                        reportOnlyWouldStop = @($Verdict.reportOnlyWouldStop)
                        policies            = @($Verdict.policies)
                        conditions          = $Step.whatIf
                        gaps                = @($Gaps)
                        error               = $null
                    }
                }
            }
        }

        $Checks = [System.Collections.Generic.List[bool]]::new()
        foreach ($Standard in $Standards) { if ($null -ne $Standard.compliant) { $Checks.Add([bool]$Standard.compliant) } }
        foreach ($Alert in $Alerts) { $Checks.Add([bool]$Alert.configured) }
        $Passed = @($Checks | Where-Object { $_ }).Count
        $Kind = if ($WhatIf -and ($Standards.Count -gt 0 -or $Alerts.Count -gt 0)) { 'mixed' } elseif ($WhatIf) { 'whatIf' } elseif ($Standards.Count -gt 0 -or $Alerts.Count -gt 0) { 'checks' } else { 'narrative' }

        $Verdict = if ($WhatIf) {
            $WhatIf.verdict
        } elseif ($Checks.Count -eq 0) {
            $(if ($Standards.Count -gt 0 -or $Alerts.Count -gt 0) { 'unknown' } else { 'info' })
        } elseif ($Passed -eq $Checks.Count) { 'pass' } elseif ($Passed -eq 0) { 'fail' } else { 'partial' }

        $VerdictLabel = switch ($Verdict) {
            'blocked' { $(if (@($WhatIf.blockedBy).Count -gt 0) { 'Blocked by policy' } else { 'Stopped - the attacker cannot satisfy the required controls' }) }
            'allowed' { $(if ($WhatIf.detail -eq 'grantSatisfied') { 'Allowed - the required controls are satisfied by the attacker' } else { 'Allowed - no enforced policy applies' }) }
            'pass' { 'Protected' }
            'partial' { 'Partly protected' }
            'fail' { 'Unprotected' }
            'unknown' { 'Could not be evaluated' }
            default { '' }
        }

        $HasFix = ($WhatIf -and @($WhatIf.gaps | Where-Object { $_.triggered }).Count -gt 0) -or
        @($Standards | Where-Object { $_.compliant -eq $false }).Count -gt 0 -or
        @($Alerts | Where-Object { -not $_.configured }).Count -gt 0
        $VerdictWhenFixed = if ($WhatIf) {
            $(if ($WhatIf.verdict -eq 'blocked' -or @($WhatIf.gaps | Where-Object { $_.triggered }).Count -gt 0) { 'blocked' } else { $WhatIf.verdict })
        } elseif ($Checks.Count -gt 0 -or $Standards.Count -gt 0 -or $Alerts.Count -gt 0) { 'pass' } else { 'info' }

        $Fixes = [System.Collections.Generic.List[object]]::new()
        foreach ($Standard in @($Standards | Where-Object { $_.compliant -eq $false })) {
            $Fixes.Add([PSCustomObject]@{ type = 'standard'; name = $Standard.name; label = $Standard.label; role = $Standard.role; status = $Standard.status; assigned = $Standard.assigned; step = $StepId })
        }
        if ($WhatIf) {
            foreach ($Gap in @($WhatIf.gaps | Where-Object { $_.triggered })) {
                $Fixes.Add([PSCustomObject]@{ type = 'caTemplate'; name = "$($Gap.fix.caTemplate)"; label = $Gap.text; role = $Gap.role; status = 'Missing'; assigned = $false; step = $StepId })
            }
        }
        foreach ($Alert in @($Alerts | Where-Object { -not $_.configured })) {
            $Fixes.Add([PSCustomObject]@{ type = 'alertPreset'; name = $(if ($Alert.preset) { $Alert.preset } else { $Alert.operation }); label = "Alert on $($Alert.operation)"; role = 'detects'; status = 'Not configured'; assigned = $false; step = $StepId })
        }

        $StepReached = $Reached
        $StepReachedWhenFixed = $ReachedWhenFixed
        $Results.Add([PSCustomObject]@{
                id               = $StepId
                index            = $Index
                title            = "$($Step.title)"
                text             = "$($Step.text)"
                kind             = $Kind
                verdict          = $Verdict
                verdictLabel     = $VerdictLabel
                reached          = $StepReached
                reachedWhenFixed = $StepReachedWhenFixed
                verdictWhenFixed = $VerdictWhenFixed
                whenFixed        = $(if ("$($Step.whenFixed)") { "$($Step.whenFixed)" } else { $null })
                hasFix           = [bool]$HasFix
                standards        = @($Standards)
                whatIf           = $WhatIf
                alerts           = @($Alerts)
                fixes            = @($Fixes)
            })

        $StopsWhen = "$($Step.stopsChainWhen)".ToLower()
        if ($StopsWhen -and $Reached -and $Verdict -eq $StopsWhen) { $Reached = $false; $PreventedAt = $StepId }
        if ($StopsWhen -and $ReachedWhenFixed -and $VerdictWhenFixed -eq $StopsWhen) { $ReachedWhenFixed = $false; $PreventedWhenFixedAt = $StepId }
    }

    $AllStandards = @($Results | ForEach-Object { $_.standards })
    $AllFixes = @($Results | ForEach-Object { $_.fixes })
    $UniqueFixes = [System.Collections.Generic.List[object]]::new()
    $Seen = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($Fix in $AllFixes) {
        if ($Seen.Add("$($Fix.type)|$($Fix.name)")) { $UniqueFixes.Add($Fix) }
    }
    $Detected = @($Results | Where-Object { $_.reached } | ForEach-Object { $_.alerts } | Where-Object { $_.configured }).Count -gt 0
    $LastRun = ($AlignmentRows | ForEach-Object { [int64]($_.LastRun ?? 0) } | Measure-Object -Maximum).Maximum

    [PSCustomObject]@{
        scenario     = [PSCustomObject]@{
            id       = "$($Scenario.id)"
            title    = "$($Scenario.title)"
            category = "$($Scenario.category)"
            severity = "$($Scenario.severity)"
            summary  = "$($Scenario.summary)"
            outcome  = $Scenario.outcome
        }
        tenantFilter = $TenantFilter
        licensed     = [bool]$Licensed
        identity     = $Identity
        steps        = @($Results)
        summary      = [PSCustomObject]@{
            prevented                = $null -ne $PreventedAt
            preventedAtStep          = $PreventedAt
            preventedWhenFixed       = $null -ne $PreventedWhenFixedAt
            preventedWhenFixedAtStep = $PreventedWhenFixedAt
            detected                 = [bool]$Detected
            standardsTotal           = $AllStandards.Count
            standardsCompliant       = @($AllStandards | Where-Object { $_.compliant -eq $true }).Count
            standardsGap             = @($AllStandards | Where-Object { $_.compliant -eq $false }).Count
            standardsUnknown         = @($AllStandards | Where-Object { $null -eq $_.compliant }).Count
            fixCount                 = $UniqueFixes.Count
            fixes                    = @($UniqueFixes)
        }
        evidence     = [PSCustomObject]@{
            whatIfCalls      = $WhatIfCalls
            alignmentLastRun = $(if ($LastRun) { [int64]$LastRun } else { $null })
            alertRules       = $Rules.Count
        }
    }
}
