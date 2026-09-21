function Get-CIPPSimulationStandardState {
    <#
    .SYNOPSIS
        Reports whether one Baseline standard is in place on a tenant, for a simulation step.
    .DESCRIPTION
        No new evaluation logic: if the tenant has a BaselineAlignment row for the standard, that row is the
        answer (it is what the alignment page shows).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$TenantFilter,
        [Parameter(Mandatory = $true)]$Definition,
        [string]$Role = 'prevents',
        $AlignmentRows,
        $Capabilities,
        [switch]$RowsOnly
    )

    $Name = "$($Definition.name)"
    $State = [PSCustomObject]@{
        name       = $Name
        label      = "$($Definition.label ?? $Name)"
        category   = "$($Definition.cat ?? 'Uncategorized')"
        role       = $Role
        status     = 'Unknown'
        compliant  = $null
        source     = 'unavailable'
        assigned   = $false
        detail     = ''
        lastRun    = $null
    }

    $Row = @($AlignmentRows | Where-Object { ("$($_.StandardName)" -split '#')[0] -eq $Name }) |
        Sort-Object -Property { [int64]($_.LastRun ?? 0) } -Descending | Select-Object -First 1
    if ($Row) {
        $State.assigned = $true
        $State.source = 'baseline'
        $State.lastRun = $Row.LastRun
        $Status = "$($Row.Status)"
        switch -Regex ($Status) {
            '^Compliant$' { $State.status = 'Compliant'; $State.compliant = $true }
            '^(Accepted|Partially Accepted)$' { $State.status = 'Accepted deviation'; $State.compliant = $false; $State.detail = "$($Row.DeviationReason)" }
            '^Denied' { $State.status = 'Drift'; $State.compliant = $false }
            '^Drift$' { $State.status = 'Drift'; $State.compliant = $false }
            '^Skipped - No License$' { $State.status = 'License missing'; $State.compliant = $null }
            '^Conflict$' { $State.status = 'Conflict'; $State.compliant = $null }
            default { $State.status = 'No data'; $State.compliant = $null }
        }
        return $State
    }

    if ($RowsOnly) {
        $State.status = 'Not in a baseline'
        return $State
    }

    $Required = @($Definition.requiredCapabilities | Where-Object { $_ })
    if ($Required.Count -gt 0) {
        if ($null -eq $Capabilities) {
            $Capabilities = $(try { Get-CIPPTenantCapabilities -TenantFilter $TenantFilter } catch { $null })
        }
        $Licensed = @($Required | ForEach-Object { $_ } | Where-Object { $Capabilities.$_ -eq $true }).Count -gt 0
        if (-not $Licensed) {
            $State.status = 'License missing'
            $State.source = 'license'
            return $State
        }
    }

    try {
        $Item = @{
            TenantFilter     = $TenantFilter
            TenantName       = $TenantFilter
            Standard         = $Name
            BaseName         = $Name
            Variables        = $null
            Tiers            = @()
            Stage            = 1
            StageName        = ''
            TemplateId       = ''
            SourceScope      = 'simulation'
            SourceTemplate   = 'Security Simulation'
            RemediateEnabled = $false
            AlertEnabled     = $false
        }
        $Graded = Invoke-CIPPBaselineStandard -Item $Item -Mode 'compare' -GradeOnly
        $State.source = 'evaluated'
        if ($null -eq $Graded) {
            $State.status = 'Needs configuration'
            $State.detail = 'This standard has to be configured in a baseline before it can be checked.'
        } elseif ($Graded.Compliant -eq $true) {
            $State.status = 'Compliant'
            $State.compliant = $true
        } else {
            $State.status = 'Not configured'
            $State.compliant = $false
            $Properties = @($Graded.Diff | ForEach-Object { $_.Property } | Where-Object { $_ } | Select-Object -Unique)
            if ($Properties.Count -gt 0) { $State.detail = 'Differs on: {0}' -f ($Properties -join ', ') }
        }
    } catch {
        $State.status = 'Could not evaluate'
        $State.detail = $_.Exception.Message
    }
    $State
}
