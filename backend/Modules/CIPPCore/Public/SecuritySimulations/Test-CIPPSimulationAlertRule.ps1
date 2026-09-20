function Test-CIPPSimulationAlertRule {
    <#
    .SYNOPSIS
        Answers whether an audit-log alert rule would fire for an operation in this tenant.
    .DESCRIPTION
        Rules come from Get-CIPPSimulationAlertRules (already scoped to the tenant). A rule
        matches when one of its Operation conditions equals the operation or, for like/contains
        conditions, wildcard-matches it. The logbook is only enforced when both sides declare one.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        $Rules,
        [Parameter(Mandatory = $true)][string]$Operation,
        [string]$Logbook,
        [string]$Preset
    )

    $Matched = @($Rules | Where-Object {
            $Rule = $_
            if ($Logbook -and $Rule.Logbook -and $Rule.Logbook -ne $Logbook) { return $false }
            @($Rule.Operations | Where-Object { $Operation -eq $_ -or $Operation -like $_ }).Count -gt 0
        })

    [PSCustomObject]@{
        operation  = $Operation
        logbook    = $Logbook
        preset     = $Preset
        configured = $Matched.Count -gt 0
        rules      = @($Matched | ForEach-Object { if ($_.Comment) { $_.Comment } else { $_.Operations -join ', ' } })
    }
}
