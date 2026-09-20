function Get-CIPPCAPersonaMatrix {
    <#
    .SYNOPSIS
        Builds the "who is protected by what" matrix: four personas by eight controls.
    .DESCRIPTION
        Personas come from how policies TARGET identities, never from policy names, so the matrix
        is truthful for tenants that follow no naming convention:
          Admins              - policies that include privileged roles, or All users without excluding roles
          Users               - policies that include All users (group-scoped policies never prove everyone is covered)
          Guests              - policies that include guests/external users, or All users without excluding them
          Workload identities - policies that include service principals
        A cell is Enforced when an enabled policy in the persona's bucket implements the control,
        ReportOnly when only a report-only policy does, Missing otherwise, NotApplicable when the
        persona does not need that control. Missing controls for Admins, Users and Guests become
        "Persona coverage" findings with a suggested policy. Returns personas, controls, cells,
        findings and overallScore (coverage percentage, report-only counting half).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Context
    )

    $ControlMeta = $Context.Data.Personas.controls
    $ControlOrder = @('require-mfa', 'phishing-resistant-mfa', 'require-compliant-device', 'block-legacy-auth', 'sign-in-risk', 'user-risk', 'session-sif', 'block-countries')
    $Personas = @(
        [PSCustomObject]@{ id = 'admins'; label = 'Admins'; expected = $ControlOrder }
        [PSCustomObject]@{ id = 'users'; label = 'Users'; expected = @($ControlOrder | Where-Object { $_ -ne 'phishing-resistant-mfa' }) }
        [PSCustomObject]@{ id = 'guests'; label = 'Guests'; expected = @('require-mfa', 'block-legacy-auth', 'sign-in-risk', 'session-sif', 'block-countries') }
        [PSCustomObject]@{ id = 'workloadIdentities'; label = 'Workload identities'; expected = @('sign-in-risk', 'block-countries') }
    )
    $Round = { param($Value) [int][math]::Round([double]$Value, [System.MidpointRounding]::AwayFromZero) }

    $PolicyPersonas = {
        param($P)
        $Out = [System.Collections.Generic.List[string]]::new()
        $U = $P.conditions.users
        $All = @($U.includeUsers) -contains 'All'
        $ExcludesGuests = ($null -ne $U.excludeGuestsOrExternalUsers -and "$($U.excludeGuestsOrExternalUsers.guestOrExternalUserTypes)") -or (@($U.excludeUsers) -contains 'GuestsOrExternalUsers')
        $IncludesGuests = ($null -ne $U.includeGuestsOrExternalUsers -and "$($U.includeGuestsOrExternalUsers.guestOrExternalUserTypes)") -or (@($U.includeUsers) -contains 'GuestsOrExternalUsers')
        if (@($U.includeRoles).Count -gt 0 -or ($All -and @($U.excludeRoles).Count -eq 0)) { $Out.Add('admins') }
        if ($All) { $Out.Add('users') }
        if ($IncludesGuests -or ($All -and -not $ExcludesGuests)) { $Out.Add('guests') }
        if (@($P.conditions.clientApplications.includeServicePrincipals).Count -gt 0) { $Out.Add('workloadIdentities') }
        $Out.ToArray()
    }

    $Detectors = @{
        'block-legacy-auth'        = {
            param($P)
            $Types = @($P.conditions.clientAppTypes)
            (($Types -contains 'exchangeActiveSync') -or ($Types -contains 'other')) -and (@($P.grantControls.builtInControls) -contains 'block')
        }
        'require-mfa'              = {
            param($P)
            (@($P.grantControls.builtInControls) -contains 'mfa') -or (-not [string]::IsNullOrWhiteSpace("$($P.grantControls.authenticationStrength.id)"))
        }
        'require-compliant-device' = {
            param($P)
            $C = @($P.grantControls.builtInControls)
            ($C -contains 'compliantDevice') -or ($C -contains 'domainJoinedDevice')
        }
        'sign-in-risk'             = {
            param($P)
            (@($P.conditions.signInRiskLevels).Count -gt 0) -or (@($P.conditions.servicePrincipalRiskLevels).Count -gt 0)
        }
        'user-risk'                = { param($P) @($P.conditions.userRiskLevels).Count -gt 0 }
        'session-sif'              = {
            param($P)
            ($P.sessionControls.signInFrequency.isEnabled -eq $true) -or ($P.sessionControls.persistentBrowser.isEnabled -eq $true)
        }
        'block-countries'          = {
            param($P)
            $L = $P.conditions.locations
            ($null -ne $L) -and ((@($L.includeLocations).Count -gt 0) -or (@($L.excludeLocations).Count -gt 0)) -and (@($P.grantControls.builtInControls) -contains 'block')
        }
        'phishing-resistant-mfa'   = { param($P) Test-CIPPCAPolicyPhishingResistant -Policy $P -Context $Context }
    }

    $SeverityForGap = {
        param($PersonaId, $Control)
        switch ($PersonaId) {
            'admins' { if ($Control -in @('require-mfa', 'phishing-resistant-mfa')) { 'Critical' } else { 'High' } }
            'users' { if ($Control -eq 'require-mfa') { 'Critical' } elseif ($Control -eq 'block-legacy-auth') { 'High' } else { 'Medium' } }
            'guests' { if ($Control -eq 'require-mfa') { 'High' } else { 'Medium' } }
            default { 'Low' }
        }
    }

    $Buckets = @{}
    foreach ($Persona in $Personas) { $Buckets[$Persona.id] = [System.Collections.Generic.List[object]]::new() }
    foreach ($Policy in @($Context.Policies)) {
        foreach ($PersonaId in @(& $PolicyPersonas $Policy)) {
            $Buckets[$PersonaId].Add($Policy)
        }
    }

    $Cells = [System.Collections.Generic.List[object]]::new()
    $Findings = [System.Collections.Generic.List[object]]::new()
    $TotalExpected = 0
    $TotalCovered = 0.0

    foreach ($Persona in $Personas) {
        $Assigned = @($Buckets[$Persona.id])
        foreach ($Control in $ControlOrder) {
            $ControlLabel = "$($ControlMeta.$Control.label)"
            if ($Persona.expected -notcontains $Control) {
                $Cells.Add([PSCustomObject]@{ persona = $Persona.label; control = $ControlLabel; state = 'NotApplicable'; policies = [string[]]@() })
                continue
            }
            $TotalExpected++
            $Detector = $Detectors[$Control]
            $EnabledHits = [string[]]@($Assigned | Where-Object { $_.state -eq 'enabled' -and (& $Detector $_) } | ForEach-Object { "$($_.displayName)" })
            $ReportOnlyHits = [string[]]@($Assigned | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' -and (& $Detector $_) } | ForEach-Object { "$($_.displayName)" })

            if ($EnabledHits.Count -gt 0) {
                $State = 'Enforced'; $Names = $EnabledHits; $TotalCovered += 1
            } elseif ($ReportOnlyHits.Count -gt 0) {
                $State = 'ReportOnly'; $Names = $ReportOnlyHits; $TotalCovered += 0.5
            } else {
                $State = 'Missing'; $Names = [string[]]@()
            }
            $Cells.Add([PSCustomObject]@{ persona = $Persona.label; control = $ControlLabel; state = $State; policies = $Names })

            if ($State -eq 'Missing' -and $Persona.id -ne 'workloadIdentities') {
                $Params = @{
                    Severity    = & $SeverityForGap $Persona.id $Control
                    Category    = 'Persona coverage'
                    Title       = "$($Persona.label): no policy applies ""$ControlLabel"""
                    Description = "No enforced Conditional Access policy that targets $($Persona.label) applies ""$ControlLabel"". $($ControlMeta.$Control.description)"
                    Remediation = "Deploy a Conditional Access policy for $($Persona.label) that applies this control, or extend one that already targets them."
                    CaTemplate  = "$ControlLabel for $($Persona.label)"
                }
                $Findings.Add((New-CIPPCAGapFinding @Params))
            }
        }
    }

    $OverallScore = if ($TotalExpected -eq 0) { 100 } else { & $Round (($TotalCovered / $TotalExpected) * 100) }

    [PSCustomObject]@{
        personas     = [string[]]@($Personas | ForEach-Object { $_.label })
        controls     = [string[]]@($ControlOrder | ForEach-Object { "$($ControlMeta.$_.label)" })
        cells        = @($Cells)
        findings     = @($Findings)
        overallScore = $OverallScore
    }
}
