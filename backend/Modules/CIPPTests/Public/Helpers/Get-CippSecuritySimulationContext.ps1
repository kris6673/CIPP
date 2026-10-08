function Get-CippSecuritySimulationContext {
    <#
    .SYNOPSIS
        Everything the Security Simulation tests read for a tenant, fetched once.
    .DESCRIPTION
        Loads the scenarios, picks the account each persona signs in as, evaluates every What If step in one
        batch and grades each distinct standard once: from the tenant's BaselineAlignment row when a baseline
        covers it, otherwise live in compare mode. During a suite run Initialize-CippTestSuiteSecuritySimulations
        shares one context across all scenario tests; a single test builds one for its own scenario.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Tenant,
        [string]$ScenarioId
    )

    if ($script:CippSecuritySimulationContext.Tenant -eq $Tenant) { return $script:CippSecuritySimulationContext }

    $Path = Join-Path $env:CIPPRootPath 'Modules\CIPPTests\Public\Tests\SecuritySimulations\scenarios.json'
    $Scenarios = @([System.IO.File]::ReadAllText($Path) | ConvertFrom-Json -Depth 20 | Where-Object { -not $ScenarioId -or $_.id -eq $ScenarioId })
    $AlignmentTable = Get-CippTable -tablename 'BaselineAlignment'
    $SafeTenant = ConvertTo-CIPPODataFilterValue -Value $Tenant
    $AlignmentRows = @(Get-CIPPAzDataTableEntity @AlignmentTable -Filter "PartitionKey eq '$SafeTenant'")
    $Context = @{
        Tenant    = $Tenant
        Scenarios = $Scenarios
        Plans     = @{}
        WhatIf    = @{}
        Standards = @{}
        Timings   = [System.Collections.Generic.List[object]]::new()
        Rules     = $null
    }

    $Directory = $null
    $Identities = @{}
    $WhatIfKeys = [System.Collections.Generic.List[string]]::new()
    $WhatIfBodies = [System.Collections.Generic.List[object]]::new()
    foreach ($Scenario in $Scenarios) {
        $TestId = "SecuritySimulation_$($Scenario.id)"
        $Licensed = -not $Scenario.licensePresets -or (Test-CIPPStandardLicense -StandardName $TestId -TenantFilter $Tenant -Preset $Scenario.licensePresets -SkipLog)
        $Persona = $(if ("$($Scenario.persona)") { "$($Scenario.persona)" } else { 'user' })
        $WhatIfSteps = @($Scenario.steps | Where-Object { $_.whatIf })
        # The What If API itself needs Entra ID P1 or P2, whatever else the scenario is licensed for.
        $CALicensed = $WhatIfSteps.Count -gt 0 -and $Licensed -and (Test-CIPPStandardLicense -StandardName $TestId -TenantFilter $Tenant -Preset Entra -SkipLog)
        $Identity = $null
        if ($CALicensed) {
            if (-not $Identities.ContainsKey($Persona)) {
                $Directory ??= @{
                    Users    = @(Get-CIPPSimulationCache -TenantFilter $Tenant -Type 'Users')
                    Roles    = @(Get-CIPPSimulationCache -TenantFilter $Tenant -Type 'Roles')
                    Policies = @(Get-CIPPSimulationCache -TenantFilter $Tenant -Type 'ConditionalAccessPolicies')
                }
                $Identities[$Persona] = Resolve-CIPPSimulationIdentity -TenantFilter $Tenant -Persona $Persona -Users $Directory.Users -Roles $Directory.Roles -Policies $Directory.Policies
            }
            $Identity = $Identities[$Persona]
        }
        if ($Identity) {
            foreach ($Step in $WhatIfSteps) {
                $WhatIfKeys.Add("$($Scenario.id)|$($Step.id)")
                $WhatIfBodies.Add((New-CIPPCAWhatIfRequest -UserId $Identity.userId -IncludeApplications $Step.whatIf.includeApplications -Conditions ($Step.whatIf | Select-Object -Property * -ExcludeProperty includeApplications)))
            }
        }
        $Context.Plans["$($Scenario.id)"] = [PSCustomObject]@{ Licensed = [bool]$Licensed; CALicensed = [bool]$CALicensed; Persona = $Persona; Identity = $Identity }
    }

    if ($WhatIfBodies.Count -gt 0) {
        $Evaluations = @(Invoke-CIPPCAWhatIf -TenantFilter $Tenant -Bodies @($WhatIfBodies))
        for ($i = 0; $i -lt $WhatIfKeys.Count; $i++) { $Context.WhatIf[$WhatIfKeys[$i]] = $Evaluations[$i] }
    }

    $Names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($Reference in @($Scenarios.steps.standards | Where-Object { $_ })) { $null = $Names.Add("$($Reference.name)") }
    foreach ($Name in $Names) {
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $Definition = Get-CIPPBaselineDefinition -Name $Name | Select-Object -First 1
        $State = [PSCustomObject]@{
            name      = $Name
            label     = "$($Definition.label ?? $Name)"
            status    = 'Not in a baseline'
            compliant = $false
            assigned  = $false
            detail    = ''
        }
        $Row = @($AlignmentRows | Where-Object { ("$($_.StandardName)" -split '#')[0] -eq $Name }) |
            Sort-Object -Property { [int64]($_.LastRun ?? 0) } -Descending | Select-Object -First 1
        if ($Row) {
            $State.assigned = $true
            switch -Regex ("$($Row.Status)") {
                '^Compliant$' { $State.status = 'Compliant'; $State.compliant = $true }
                '^(Accepted|Partially Accepted)$' { $State.status = 'Accepted deviation'; $State.compliant = $false; $State.detail = "$($Row.DeviationReason)" }
                '^(Denied|Drift)' { $State.status = 'Drift'; $State.compliant = $false }
                '^Skipped - No License$' { $State.status = 'License missing'; $State.compliant = $null }
                default { $State.status = 'No data'; $State.compliant = $null }
            }
        } elseif ($Definition.requiredCapabilities -and -not (Test-CIPPStandardLicense -StandardName $Name -TenantFilter $Tenant -RequiredCapabilities @($Definition.requiredCapabilities | ForEach-Object { $_ }) -SkipLog)) {
            $State.status = 'License missing'
            $State.compliant = $null
        } else {
            try {
                $Item = @{
                    TenantFilter     = $Tenant
                    TenantName       = $Tenant
                    Standard         = $Name
                    BaseName         = $Name
                    Variables        = $null
                    Tiers            = @()
                    Stage            = 1
                    StageName        = ''
                    TemplateId       = ''
                    SourceScope      = 'test'
                    SourceTemplate   = 'Security Simulation'
                    RemediateEnabled = $false
                    AlertEnabled     = $false
                }
                $Graded = Invoke-CIPPBaselineStandard -Item $Item -Mode 'compare' -GradeOnly
                if ($null -eq $Graded) {
                    $State.status = 'Needs configuration'
                    $State.detail = 'This standard needs its settings chosen in a baseline before it can be checked.'
                } elseif ($Graded.Compliant -eq $true) {
                    $State.status = 'Compliant'
                    $State.compliant = $true
                } else {
                    $State.status = 'Not configured'
                    $Properties = @($Graded.Diff | ForEach-Object { $_.Property } | Where-Object { $_ } | Select-Object -Unique)
                    if ($Properties.Count -gt 0) { $State.detail = 'Differs on: {0}' -f ($Properties -join ', ') }
                }
            } catch {
                $State.status = 'Could not evaluate'
                $State.compliant = $null
                $State.detail = $_.Exception.Message
            }
        }
        $Context.Standards[$Name] = $State
        $Context.Timings.Add([PSCustomObject]@{ Name = $Name; Seconds = $Stopwatch.Elapsed.TotalSeconds })
    }
    $Context
}
