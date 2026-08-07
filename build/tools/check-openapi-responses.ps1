#Requires -Version 7.0

# Compares the response schemas in Config/openapi.json against what the endpoints actually
# return, using a running CIPP instance and a real tenant.
#
# The generator infers response shapes from source - Select-Object lists, storage writers,
# Graph metadata - and every one of those inferences can be subtly wrong in a way no amount
# of re-reading the source will reveal. ListMailboxCAS documented IMAPEnabled, POPEnabled
# and EWSEnabled because that is how the Select-Object list spells them, but Exchange
# returns ImapEnabled, PopEnabled and EwsEnabled: Select-Object matches property names
# case-insensitively and emits the object's own casing. JSON is case-sensitive, so a caller
# keying on the documented name finds nothing. Only a live comparison finds that.
#
# This is a development and diagnostic tool, not part of the build: it needs a running
# instance and a tenant with data, and a tenant that happens to have no mailboxes would
# report every mailbox field as missing.
#
#   pwsh build/tools/check-openapi-responses.ps1 -TenantFilter contoso.onmicrosoft.com
#
# Only GET endpoints named List* whose sole required parameter is tenantFilter are called,
# so nothing here can mutate a tenant.

[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://127.0.0.1:5196',
    [Parameter(Mandatory)][string]$TenantFilter,
    [string]$SpecPath = "$PSScriptRoot/../../backend/Config/openapi.json",
    # Restrict to endpoints matching this wildcard, e.g. 'ListMailbox*'.
    [string]$Endpoint = '*',
    [int]$TimeoutSeconds = 120,
    # Report only endpoints with a finding.
    [switch]$OnlyProblems
)

$ErrorActionPreference = 'Stop'

$Spec = [System.IO.File]::ReadAllText($SpecPath) | ConvertFrom-Json -AsHashtable -Depth 100

# One reused client against an IP literal. 'localhost' resolves to ::1 first and the
# PowerShell web cmdlets stall ~21s per request on it before falling back.
$Handler = [System.Net.Http.HttpClientHandler]::new()
$Handler.UseProxy = $false
$Client = [System.Net.Http.HttpClient]::new($Handler)
$Client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)

function Get-JsonType {
    param($Value)
    if ($null -eq $Value) { return $null }   # null tells us nothing about the type
    if ($Value -is [bool]) { return 'boolean' }
    if ($Value -is [int] -or $Value -is [long]) { return 'integer' }
    if ($Value -is [double] -or $Value -is [decimal]) { return 'number' }
    if ($Value -is [string]) { return 'string' }
    if ($Value -is [System.Collections.IDictionary]) { return 'object' }
    if ($Value -is [System.Collections.IEnumerable]) { return 'array' }
    return 'object'
}

$Candidates = [System.Collections.Generic.List[object]]::new()
foreach ($Path in $Spec.paths.Keys) {
    $Name = $Path -replace '^/api/', ''
    if ($Name -notlike 'List*' -or $Name -notlike $Endpoint) { continue }
    $Operation = $Spec.paths[$Path]['get']
    if (-not $Operation) { continue }

    # Only endpoints whose sole requirement is a tenant; anything else would need an id we
    # would have to invent, and a wrong one produces a misleading empty result.
    $Required = @()
    foreach ($ParameterRaw in @($Operation.parameters)) {
        $Parameter = $ParameterRaw
        if ($Parameter.'$ref') {
            $Leaf = ($Parameter.'$ref' -split '/')[-1]
            $Parameter = $Spec.components.parameters[$Leaf]
        }
        if ($Parameter.required) { $Required += [string]$Parameter.name }
    }
    if (@($Required | Where-Object { $_ -ne 'tenantFilter' }).Count -gt 0) { continue }

    $Schema = $Operation.responses['200'].content.'application/json'.schema
    if ($Schema.'$ref') { continue }
    $Record = if ($Schema.type -eq 'array') { $Schema.items } else { $Schema }
    $Documented = @(($Record.properties ?? @{}).Keys)
    if ($Documented.Count -eq 0) { continue }

    $Candidates.Add(@{ Name = $Name; Documented = $Documented; Record = $Record })
}

Write-Host "Checking $($Candidates.Count) endpoints against $TenantFilter`n"

$Summary = [ordered]@{ Checked = 0; Clean = 0; Casing = 0; Missing = 0; Extra = 0; Failed = 0 }
$CasingFindings = [System.Collections.Generic.List[string]]::new()

foreach ($Candidate in $Candidates) {
    $Uri = '{0}/api/{1}?tenantFilter={2}' -f $BaseUrl, $Candidate.Name, [uri]::EscapeDataString($TenantFilter)
    try {
        $Response = $Client.GetAsync($Uri).GetAwaiter().GetResult()
        $Text = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $Response.IsSuccessStatusCode) { throw "HTTP $([int]$Response.StatusCode)" }
        $Data = $Text | ConvertFrom-Json -AsHashtable -Depth 40
    } catch {
        $Summary.Failed++
        if (-not $OnlyProblems) { Write-Host ('{0,-40} could not be checked: {1}' -f $Candidate.Name, $_.Exception.Message) -ForegroundColor DarkGray }
        continue
    }

    $Rows = if ($Data -is [System.Collections.IList]) { $Data } elseif ($Data.Results -is [System.Collections.IList]) { $Data.Results } else { $null }
    if (-not $Rows -or $Rows.Count -eq 0 -or $Rows[0] -isnot [System.Collections.IDictionary]) {
        $Summary.Failed++
        if (-not $OnlyProblems) { Write-Host ('{0,-40} no rows to compare' -f $Candidate.Name) -ForegroundColor DarkGray }
        continue
    }

    $Summary.Checked++

    # Union across rows: an endpoint can omit a null-valued field on some records.
    $Observed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $ObservedTypes = @{}
    foreach ($Row in ($Rows | Select-Object -First 25)) {
        foreach ($Key in $Row.Keys) {
            $null = $Observed.Add([string]$Key)
            $Type = Get-JsonType -Value $Row[$Key]
            if ($Type -and -not $ObservedTypes.ContainsKey($Key)) { $ObservedTypes[$Key] = $Type }
        }
    }

    $Missing = [System.Collections.Generic.List[string]]::new()
    $Casing = [System.Collections.Generic.List[string]]::new()
    foreach ($Field in $Candidate.Documented) {
        if ($Observed.Contains($Field)) { continue }
        # documented under a different case is a distinct, and worse, failure: the field is
        # there, but a case-sensitive consumer will never find it under the documented name
        $Actual = @($Observed | Where-Object { $_ -eq $Field })   # -eq on strings is case-insensitive
        if ($Actual.Count -gt 0) { $Casing.Add("$Field -> $($Actual[0])") } else { $Missing.Add($Field) }
    }
    $Extra = @($Observed | Where-Object { $_ -notin $Candidate.Documented })

    if ($Casing.Count) { $Summary.Casing++ }
    if ($Missing.Count) { $Summary.Missing++ }
    if ($Extra.Count) { $Summary.Extra++ }
    $IsClean = -not ($Casing.Count -or $Missing.Count -or $Extra.Count)
    if ($IsClean) { $Summary.Clean++ }
    if ($IsClean -and $OnlyProblems) { continue }

    $Colour = if ($Casing.Count) { 'Red' } elseif ($Missing.Count -or $Extra.Count) { 'Yellow' } else { 'Green' }
    Write-Host ('{0,-40} documented={1,-4} correct={2,-4} wrong-case={3,-3} not-returned={4,-3} undocumented={5}' -f
        $Candidate.Name, $Candidate.Documented.Count, ($Candidate.Documented.Count - $Casing.Count - $Missing.Count),
        $Casing.Count, $Missing.Count, $Extra.Count) -ForegroundColor $Colour

    foreach ($Item in $Casing) {
        Write-Host "     wrong case: $Item" -ForegroundColor Red
        $CasingFindings.Add("$($Candidate.Name): $Item")
    }
    if ($Missing.Count -and -not $OnlyProblems) { Write-Host "     not returned: $(($Missing | Select-Object -First 6) -join ', ')" -ForegroundColor DarkYellow }
    if ($Extra.Count -and -not $OnlyProblems) { Write-Host "     undocumented: $(($Extra | Select-Object -First 6) -join ', ')" -ForegroundColor DarkYellow }
}

$Client.Dispose()

Write-Host "`nchecked=$($Summary.Checked)  clean=$($Summary.Clean)  with-wrong-case=$($Summary.Casing)  with-missing=$($Summary.Missing)  with-undocumented=$($Summary.Extra)  uncheckable=$($Summary.Failed)"

if ($CasingFindings.Count -gt 0) {
    Write-Host "`nFields documented under the wrong case ($($CasingFindings.Count)). These are the ones that actively mislead:" -ForegroundColor Red
    $CasingFindings | ForEach-Object { Write-Host "  $_" }
}
