function Get-CIPPCAAnalysisContext {
    <#
    .SYNOPSIS
        Builds the shared context every Conditional Access gap check reads from.
    .DESCRIPTION
        Reads the tenant's cached ConditionalAccessPolicies, NamedLocations, AuthenticationStrengths, ServicePrincipals,
        Roles and LicenseOverview rows once (cache only, no Graph calls), normalizes every policy, loads the static
        reference datasets and returns one hashtable:
          TenantFilter, Policies (normalized), Enabled, ReportOnly, Disabled, NamedLocations, NamedLocationById,
          AuthStrengths (id -> strength), ServicePrincipals (lower-case appId -> service principal),
          Roles (lower-case roleTemplateId -> display name), Licenses (HasEntraIdP1/P2, HasIntunePlan1,
          HasWorkloadIdPremium, Source), BreakGlass (candidate from Get-CIPPCABreakGlassCandidate with a display name
          resolved from the Users/Groups cache when available) and Data (reference datasets plus lower-cased lookup tables).
        When the LicenseOverview cache is empty, licensing is inferred from the policies themselves (risk conditions
        imply Entra ID P2, compliant-device grants imply Intune) exactly as the source analyzer does.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantFilter
    )

    # Emits the cached rows one by one (no comma-wrapping) so every caller can collect them with @(& $ReadCache ...).
    $ReadCache = {
        param($Type, $Fields)
        try {
            if ($Fields) {
                New-CIPPDbRequest -TenantFilter $TenantFilter -Type $Type -Fields $Fields | Where-Object { $_ }
            } else {
                New-CIPPDbRequest -TenantFilter $TenantFilter -Type $Type | Where-Object { $_ }
            }
        } catch {
            Write-Information "Get-CIPPCAAnalysisContext: could not read cached '$Type' for $TenantFilter - $($_.Exception.Message)"
        }
    }

    # --- policies
    # Collect on miss, exactly like the Baselines engine: a tenant whose Conditional Access cache
    # was never collected must not read as "no policies". The collector also fills NamedLocations
    # and AuthenticationStrengths, so it runs before those reads.
    $RawPolicies = @(Get-CIPPSimulationCache -TenantFilter $TenantFilter -Type 'ConditionalAccessPolicies')
    $Policies = [System.Collections.Generic.List[object]]::new()
    foreach ($Raw in $RawPolicies) {
        if (-not $Raw.id) { continue }
        $Policies.Add((ConvertTo-CIPPCANormalizedPolicy -Policy $Raw))
    }
    $Policies = @($Policies)
    $Enabled = @($Policies | Where-Object { $_.state -eq 'enabled' })
    $ReportOnly = @($Policies | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' })
    $Disabled = @($Policies | Where-Object { $_.state -eq 'disabled' })

    # --- named locations, authentication strengths, service principals, roles
    $NamedLocations = @(& $ReadCache 'NamedLocations' | Where-Object { $_.id })
    $NamedLocationById = @{}
    foreach ($Location in $NamedLocations) { $NamedLocationById["$($Location.id)"] = $Location }

    $AuthStrengths = @{}
    foreach ($Strength in @(& $ReadCache 'AuthenticationStrengths')) {
        if ($Strength.id) { $AuthStrengths["$($Strength.id)"] = $Strength }
    }

    $ServicePrincipals = @{}
    foreach ($ServicePrincipal in @(& $ReadCache 'ServicePrincipals' @('id', 'appId', 'displayName', 'servicePrincipalType', 'appOwnerOrganizationId'))) {
        if ($ServicePrincipal.appId) { $ServicePrincipals["$($ServicePrincipal.appId)".ToLowerInvariant()] = $ServicePrincipal }
    }

    $Roles = @{}
    foreach ($Role in @(& $ReadCache 'Roles' @('id', 'roleTemplateId', 'displayName'))) {
        $RoleKey = if ($Role.roleTemplateId) { "$($Role.roleTemplateId)" } else { "$($Role.id)" }
        if ($RoleKey -and $Role.displayName) { $Roles[$RoleKey.ToLowerInvariant()] = "$($Role.displayName)" }
    }

    # --- static reference data and lookup tables
    $Data = @{}
    foreach ($Name in @('Reference', 'Personas', 'KnownExclusions', 'AdminRoles', 'FociFamilies', 'BypassApps', 'FirstPartyApps', 'AppDescriptions')) {
        $Data[$Name] = Get-CIPPCAAnalysisData -Name $Name
    }
    $Data['KnownExclusions'] = @($Data['KnownExclusions'])

    $Data['FociApps'] = @($Data['FociFamilies'])
    $Data['FociById'] = @{}
    foreach ($App in $Data['FociApps']) { if ($App.appId) { $Data['FociById']["$($App.appId)".ToLowerInvariant()] = $App } }

    $Data['BypassAppById'] = @{}
    foreach ($App in @($Data['BypassApps'].bypassApps)) { if ($App.appId) { $Data['BypassAppById']["$($App.appId)".ToLowerInvariant()] = $App } }
    $Data['ImmuneResources'] = @($Data['BypassApps'].immuneResources)
    $Data['ImmuneById'] = @{}
    foreach ($Resource in $Data['ImmuneResources']) { if ($Resource.resourceId) { $Data['ImmuneById']["$($Resource.resourceId)".ToLowerInvariant()] = $Resource } }
    $Data['DeviceRegistrationResource'] = $Data['BypassApps'].deviceRegistrationResource
    $Data['WellKnownById'] = @{}
    foreach ($App in @($Data['BypassApps'].wellKnownApps)) { if ($App.appId) { $Data['WellKnownById']["$($App.appId)".ToLowerInvariant()] = $App } }
    $Data['HighValueApps'] = @($Data['BypassApps'].highValueApps)
    $Data['AppGroupAliases'] = @{}
    foreach ($Property in @($Data['BypassApps'].appGroupAliases.PSObject.Properties)) { $Data['AppGroupAliases'][$Property.Name.ToLowerInvariant()] = $Property.Value }

    $Data['FirstPartyNames'] = @{}
    foreach ($Property in @($Data['FirstPartyApps'].PSObject.Properties)) { $Data['FirstPartyNames'][$Property.Name.ToLowerInvariant()] = "$($Property.Value)" }

    $Data['AppDescriptionById'] = @{}
    foreach ($App in @($Data['AppDescriptions'])) { if ($App.appId) { $Data['AppDescriptionById']["$($App.appId)".ToLowerInvariant()] = $App } }

    $Data['HighPrivilegeRoleNames'] = @{}
    foreach ($Property in @($Data['AdminRoles'].highPrivilegeRoles.PSObject.Properties)) { $Data['HighPrivilegeRoleNames'][$Property.Name.ToLowerInvariant()] = "$($Property.Value)" }
    $Data['CriticalRoleIds'] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($RoleId in @($Data['AdminRoles'].criticalRoleIds)) { $null = $Data['CriticalRoleIds'].Add("$RoleId") }
    $Data['DirSyncRoleId'] = "$($Data['AdminRoles'].directorySynchronizationAccountsRoleId)"

    # --- licensing (cache only; falls back to policy-based inference when the license cache is empty)
    $PlanReference = $Data['Reference'].servicePlanIds
    $PlanIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $LicenseRows = @(& $ReadCache 'LicenseOverview' @('skuId', 'ServicePlans'))
    foreach ($Row in $LicenseRows) {
        foreach ($Plan in @($Row.ServicePlans)) {
            if ($Plan.servicePlanId) { $null = $PlanIds.Add("$($Plan.servicePlanId)") }
        }
    }
    if ($LicenseRows.Count -gt 0) {
        $Licenses = @{
            Source               = 'LicenseOverview'
            HasEntraIdP1         = $PlanIds.Contains("$($PlanReference.entraIdP1)") -or $PlanIds.Contains("$($PlanReference.entraIdP2)")
            HasEntraIdP2         = $PlanIds.Contains("$($PlanReference.entraIdP2)")
            HasIntunePlan1       = $PlanIds.Contains("$($PlanReference.intunePlan1)")
            HasWorkloadIdPremium = $PlanIds.Contains("$($PlanReference.workloadIdPremiumP1)") -or $PlanIds.Contains("$($PlanReference.workloadIdPremiumP2)")
        }
    } else {
        $ActivePolicies = @($Policies | Where-Object { $_.state -in @('enabled', 'enabledForReportingButNotEnforced') })
        $InferredP2 = @($ActivePolicies | Where-Object { @($_.conditions.signInRiskLevels).Count -gt 0 -or @($_.conditions.userRiskLevels).Count -gt 0 }).Count -gt 0
        $InferredIntune = @($ActivePolicies | Where-Object { @($_.grantControls.builtInControls) -contains 'compliantDevice' }).Count -gt 0
        $InferredWorkload = @($ActivePolicies | Where-Object { @($_.conditions.clientApplications.includeServicePrincipals).Count -gt 0 }).Count -gt 0
        $Licenses = @{
            Source               = 'InferredFromPolicies'
            HasEntraIdP1         = $true
            HasEntraIdP2         = $InferredP2
            HasIntunePlan1       = $InferredIntune
            HasWorkloadIdPremium = $InferredWorkload
        }
    }

    # --- break-glass candidate (display name is best-effort from the Users/Groups cache)
    $BreakGlass = Get-CIPPCABreakGlassCandidate -Policies $Policies
    if ($BreakGlass) {
        $DirectoryType = if ($BreakGlass.type -eq 'user') { 'Users' } else { 'Groups' }
        $Match = $null
        foreach ($Entry in @(& $ReadCache $DirectoryType @('id', 'displayName'))) {
            if ("$($Entry.id)" -eq $BreakGlass.id) { $Match = $Entry; break }
        }
        $ShortId = $BreakGlass.id.Substring(0, [math]::Min(8, $BreakGlass.id.Length))
        $BreakGlass.displayName = if ($Match.displayName) { "$($Match.displayName)" } else { "ID: $ShortId..." }
    }

    @{
        TenantFilter      = $TenantFilter
        Policies          = $Policies
        Enabled           = $Enabled
        ReportOnly        = $ReportOnly
        Disabled          = $Disabled
        NamedLocations    = $NamedLocations
        NamedLocationById = $NamedLocationById
        AuthStrengths     = $AuthStrengths
        ServicePrincipals = $ServicePrincipals
        Roles             = $Roles
        Licenses          = $Licenses
        BreakGlass        = $BreakGlass
        Data              = $Data
    }
}
