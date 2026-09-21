function Get-CIPPSimulationAlertRules {
    <#
    .SYNOPSIS
        Returns the audit-log alert rules that cover a tenant, with their operations extracted.
    .DESCRIPTION
        Reads the WebhookRules table the alert wizard writes (Invoke-AddAlert) and keeps the enabled rules
        whose tenant scope includes this tenant (tenant groups expanded, exclusions honored - the same
        resolution the alert engine applies).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$TenantFilter)

    $Table = Get-CippTable -TableName 'WebhookRules'
    $Rows = @(Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq 'Webhookv2'")
    $Rules = [System.Collections.Generic.List[object]]::new()

    foreach ($Row in $Rows) {
        if ($Row.Disabled -eq $true) { continue }
        if ([string]::IsNullOrEmpty($Row.Tenants)) { continue }
        $Tenants = $(try { $Row.Tenants | ConvertFrom-Json -ErrorAction Stop } catch { $null })
        if ($null -eq $Tenants) { continue }
        $Expanded = @(Expand-CIPPTenantGroups -TenantFilter $Tenants)
        if (-not ($Expanded.value -contains $TenantFilter -or $Expanded.value -contains 'AllTenants')) { continue }
        $Excluded = $(try { $Row.excludedTenants | ConvertFrom-Json -ErrorAction Stop } catch { $null })
        if ($Excluded) {
            $Excluded = @(Expand-CIPPTenantGroups -TenantFilter $Excluded)
            if ($Excluded.value -contains $TenantFilter) { continue }
        }

        $Conditions = @($(try { $Row.Conditions | ConvertFrom-Json -ErrorAction Stop } catch { @() }) | Where-Object { $_ })
        $Operations = [System.Collections.Generic.List[string]]::new()
        foreach ($Condition in $Conditions) {
            $IsOperation = "$($Condition.Property.label)" -eq 'Operation' -or "$($Condition.Property.value)" -eq 'List:Operation'
            if (-not $IsOperation) { continue }
            $Operator = "$($Condition.Operator.value)".ToLower()
            if ($Operator -notin @('eq', 'in', 'like', 'contains', 'match')) { continue }
            $Inputs = if ($Condition.Input -is [array]) { $Condition.Input } else { @($Condition.Input) }
            foreach ($Input in $Inputs) {
                $Value = "$($Input.value ?? $Input)"
                if (-not $Value) { continue }
                if ($Operator -eq 'contains') { $Value = "*$Value*" }
                if (-not $Operations.Contains($Value)) { $Operations.Add($Value) }
            }
        }

        $Rules.Add([PSCustomObject]@{
                RowKey     = "$($Row.RowKey)"
                Logbook    = "$($Row.type)"
                Comment    = "$($Row.AlertComment)"
                Operations = @($Operations)
            })
    }
    @($Rules)
}
