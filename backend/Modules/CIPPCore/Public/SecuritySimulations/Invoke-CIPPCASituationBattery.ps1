function Invoke-CIPPCASituationBattery {
    <#
    .SYNOPSIS
        Evaluates every predefined sign-in situation against a tenant's live Conditional Access.
    .DESCRIPTION
        Each situation names a persona and sign-in conditions. The persona resolves to a real
        account from the cache once per battery, every situation becomes one What If request, and
        all of them go out as Graph $batch calls. The outcome is judged against the situation's
        expectation ('blocked', 'mfa', 'phishingResistant'), and a situation that falls short names
        the control that is missing.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$TenantFilter)

    $Situations = @(Get-CIPPSecuritySimulationSituation)
    $Users = @(Get-CIPPSimulationCache -TenantFilter $TenantFilter -Type 'Users')
    $Roles = @(Get-CIPPSimulationCache -TenantFilter $TenantFilter -Type 'Roles')
    $Policies = @(Get-CIPPSimulationCache -TenantFilter $TenantFilter -Type 'ConditionalAccessPolicies')

    $Identities = @{}
    foreach ($Persona in @('admin', 'user', 'guest')) {
        $Identities[$Persona] = Resolve-CIPPSimulationIdentity -TenantFilter $TenantFilter -Persona $Persona -Users $Users -Roles $Roles -Policies $Policies
    }

    $Bodies = [System.Collections.Generic.List[object]]::new()
    $Evaluable = [System.Collections.Generic.List[object]]::new()
    foreach ($Situation in $Situations) {
        $Persona = $(if ("$($Situation.persona)") { "$($Situation.persona)" } else { 'user' })
        $Identity = $Identities[$Persona]
        if (-not $Identity) { continue }
        $Bodies.Add((New-CIPPCAWhatIfRequest -UserId $Identity.userId -IncludeApplications $Situation.includeApplications -Conditions $Situation.conditions))
        $Evaluable.Add($Situation)
    }

    $Evaluations = if ($Bodies.Count -gt 0) { @(Invoke-CIPPCAWhatIf -TenantFilter $TenantFilter -Bodies @($Bodies)) } else { @() }

    $Rows = [System.Collections.Generic.List[object]]::new()
    $EvaluableIndex = 0
    foreach ($Situation in $Situations) {
        $Persona = $(if ("$($Situation.persona)") { "$($Situation.persona)" } else { 'user' })
        $Identity = $Identities[$Persona]
        $Expected = $(if ("$($Situation.expected)") { "$($Situation.expected)" } else { 'blocked' })
        $Row = [PSCustomObject]@{
            id                  = "$($Situation.id)"
            group               = "$($Situation.group)"
            title               = "$($Situation.title)"
            persona             = $Persona
            identity            = $(if ($Identity) { $Identity.userPrincipalName } else { $null })
            expected            = $Expected
            outcome             = 'Not evaluated'
            pass                = $null
            requiredControls    = @()
            blockedBy           = @()
            reportOnlyWouldStop = @()
            missingControl      = $(if ($Situation.missingControl) { "$($Situation.missingControl.text)" } else { '' })
            fix                 = $Situation.missingControl.fix
            conditions          = $Situation.conditions
            policies            = @()
            error               = $null
        }
        if (-not $Identity) {
            $Row.error = "No $Persona account is available in the cache."
            $Rows.Add($Row)
            continue
        }
        $Evaluation = $Evaluations[$EvaluableIndex]
        $EvaluableIndex++
        if ($Evaluation.Error) {
            $Row.error = "$($Evaluation.Error)"
            $Rows.Add($Row)
            continue
        }
        # A situation that only asks "is MFA demanded here?" is a plain sign-in attempt: nothing is
        # pre-satisfied, otherwise every MFA challenge would read as "allowed".
        $CanSatisfy = if ($Expected -in @('mfa', 'phishingResistant')) { @() } else { @($Situation.attackerCanSatisfy | Where-Object { $_ }) }
        $Verdict = Get-CIPPCAWhatIfVerdict -Policies $Evaluation.Policies -AttackerCanSatisfy $CanSatisfy -Expected $Expected
        $Row.outcome = if ($Verdict.detail -eq 'blockedByPolicy') { 'Blocked' }
        elseif ($Verdict.detail -eq 'challenged') { 'Requires {0}' -f ($Verdict.requiredControls -join ', ') }
        elseif ($Verdict.detail -eq 'grantSatisfied') { 'Allowed - {0} satisfied' -f ($Verdict.requiredControls -join ', ') }
        else { 'Allowed' }
        $Row.pass = [bool]$Verdict.meetsExpectation
        $Row.requiredControls = @($Verdict.requiredControls)
        $Row.blockedBy = @($Verdict.blockedBy)
        $Row.reportOnlyWouldStop = @($Verdict.reportOnlyWouldStop)
        $Row.policies = @($Verdict.policies | Where-Object { $_.policyApplies })
        if ($Row.pass) { $Row.missingControl = '' }
        $Rows.Add($Row)
    }

    [PSCustomObject]@{
        identities = [PSCustomObject]$Identities
        situations = @($Rows)
        summary    = [PSCustomObject]@{
            total        = $Rows.Count
            protected    = @($Rows | Where-Object { $_.pass -eq $true }).Count
            unprotected  = @($Rows | Where-Object { $_.pass -eq $false }).Count
            notEvaluated = @($Rows | Where-Object { $null -eq $_.pass }).Count
            reportOnly   = @($Rows | Where-Object { $_.pass -eq $false -and @($_.reportOnlyWouldStop).Count -gt 0 }).Count
        }
    }
}
