function Get-CIPPCAPostureScore {
    <#
    .SYNOPSIS
        Computes the Conditional Access score on a 1-10 scale.
    .DESCRIPTION
        Half of the score is persona coverage (the share of applicable persona-matrix cells that
        an enforced policy covers, report-only counting half), half is configuration quality
        (finding deductions with per-severity caps: Critical 10 each up to 30, High 3 up to 20,
        Medium 1 up to 16, Low 0.5 up to 6). The 0-100 sum divides by ten and rounds, with a
        floor of 1. Only the score itself is exposed - the halves are an implementation detail.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Findings,
        [Parameter(Mandatory = $true)]
        $PersonaMatrix
    )

    $Round = { param($Value) [int][math]::Round([double]$Value, [System.MidpointRounding]::AwayFromZero) }

    $Applicable = @($PersonaMatrix.cells | Where-Object { $_.state -ne 'NotApplicable' })
    $Covered = 0.0
    foreach ($Cell in $Applicable) {
        if ($Cell.state -eq 'Enforced') { $Covered += 1 }
        elseif ($Cell.state -eq 'ReportOnly') { $Covered += 0.5 }
    }
    $CoveragePoints = if ($Applicable.Count -gt 0) { ($Covered / $Applicable.Count) * 50 } else { 0 }

    $Counts = @{ Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
    foreach ($Finding in @($Findings)) {
        $Key = "$($Finding.severity)"
        if ($Counts.ContainsKey($Key)) { $Counts[$Key]++ }
    }
    $Penalty = [math]::Min($Counts['Critical'] * 10, 30) +
    [math]::Min($Counts['High'] * 3, 20) +
    [math]::Min($Counts['Medium'] * 1, 16) +
    [math]::Min($Counts['Low'] * 0.5, 6)
    $QualityPoints = 50 - [math]::Min($Penalty, 50)

    $TotalPoints = [math]::Max(0, [math]::Min(100, $CoveragePoints + $QualityPoints))
    $Score = [math]::Max(1, [math]::Min(10, (& $Round ($TotalPoints / 10))))

    [PSCustomObject]@{
        score         = [int]$Score
        scoreMax      = 10
        findingCounts = [PSCustomObject]@{
            critical = $Counts['Critical']
            high     = $Counts['High']
            medium   = $Counts['Medium']
            low      = $Counts['Low']
            info     = $Counts['Info']
        }
    }
}
