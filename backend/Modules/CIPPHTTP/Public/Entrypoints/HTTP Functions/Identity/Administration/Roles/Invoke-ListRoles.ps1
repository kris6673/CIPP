function Invoke-ListRoles {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Identity.Role.Read
    .DESCRIPTION
        Lists a tenant's Entra ID role definitions along with the members of each, via the unified RBAC API. Unlike the legacy /directoryRoles endpoint this includes every built-in and custom role definition, even ones with no assignments. On Entra ID P2 tenants each member carries its PIM assignment type (Permanent, Active, ActivatedFromEligible or Eligible) and the role carries permanent/eligible counts plus a summary of its PIM role settings.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)
    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.tenantFilter

    try {
        $Definitions = New-GraphGetRequest -uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?$select=id,templateId,displayName,description,isBuiltIn,isEnabled' -tenantid $TenantFilter

        $PIMCapable = [bool](Test-CIPPStandardLicense -StandardName 'ListRoles' -TenantFilter $TenantFilter -Preset EntraP2 -SkipLog)
        $PIMRows = $null
        $Policies = @{}
        if ($PIMCapable) {
            try {
                # Instances cover every active assignment (PIM-created or not) and eligibility adds
                # the members the legacy view could never show.
                $PIMRows = @(Get-CIPPPIMRoleAssignments -TenantFilter $TenantFilter)
                foreach ($Policy in @(Get-CIPPPIMRolePolicies -TenantFilter $TenantFilter)) {
                    $Policies[$Policy.RoleDefinitionId] = $Policy.Summary
                }
            } catch {
                Write-LogMessage -API 'ListRoles' -tenant $TenantFilter -message "PIM data unavailable, falling back to unified RBAC: $($_.Exception.Message)" -sev Warning
                $PIMRows = $null
            }
        }

        # Group members by role definition. A principal assigned at both tenant scope and an
        # administrative-unit scope appears once per scope; keep the first occurrence per principal,
        # preferring an active assignment over an eligibility.
        $MemberMap = @{}
        $TypeRank = @{ Permanent = 0; Active = 1; ActivatedFromEligible = 2; Eligible = 3 }
        if ($null -ne $PIMRows) {
            foreach ($Row in ($PIMRows | Sort-Object { $TypeRank[$_.AssignmentType] })) {
                if (-not $MemberMap.ContainsKey($Row.RoleDefinitionId)) {
                    $MemberMap[$Row.RoleDefinitionId] = [System.Collections.Generic.List[object]]::new()
                }
                if ($MemberMap[$Row.RoleDefinitionId].id -notcontains $Row.PrincipalId) {
                    $MemberMap[$Row.RoleDefinitionId].Add([PSCustomObject]@{
                            displayName       = $Row.PrincipalDisplayName
                            userPrincipalName = $Row.PrincipalUserPrincipalName
                            id                = $Row.PrincipalId
                            directoryScopeId  = $Row.DirectoryScopeId
                            AssignmentType    = $Row.AssignmentType
                            MemberType        = $Row.MemberType
                            PrincipalType     = $Row.PrincipalType
                            EndDateTime       = $Row.EndDateTime
                        })
                }
            }
        } else {
            $Assignments = New-GraphGetRequest -uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?$select=id,principalId,roleDefinitionId,directoryScopeId&$top=999' -tenantid $TenantFilter

            # Resolve principals in bulk; $expand=principal costs seconds of Graph server time
            # even for a handful of assignments, while getByIds returns in milliseconds.
            $Principals = @{}
            $PrincipalIds = @($Assignments.principalId | Sort-Object -Unique)
            for ($i = 0; $i -lt $PrincipalIds.Count; $i += 1000) {
                $Body = ConvertTo-Json -InputObject @{ ids = @($PrincipalIds[$i..([Math]::Min($i + 999, $PrincipalIds.Count - 1))]) } -Compress
                $Resolved = New-GraphPOSTRequest -tenantid $TenantFilter -uri 'https://graph.microsoft.com/v1.0/directoryObjects/getByIds?$select=id,displayName,userPrincipalName' -body $Body
                foreach ($Principal in $Resolved.value) { $Principals[$Principal.id] = $Principal }
            }

            foreach ($Assignment in $Assignments) {
                if (-not $MemberMap.ContainsKey($Assignment.roleDefinitionId)) {
                    $MemberMap[$Assignment.roleDefinitionId] = [System.Collections.Generic.List[object]]::new()
                }
                if ($MemberMap[$Assignment.roleDefinitionId].id -notcontains $Assignment.principalId) {
                    $PrincipalType = switch -Wildcard ($Principals[$Assignment.principalId].'@odata.type') {
                        '*user' { 'User' }
                        '*group' { 'Group' }
                        '*servicePrincipal' { 'ServicePrincipal' }
                        default { 'Unknown' }
                    }
                    $MemberMap[$Assignment.roleDefinitionId].Add([PSCustomObject]@{
                            displayName       = $Principals[$Assignment.principalId].displayName
                            userPrincipalName = $Principals[$Assignment.principalId].userPrincipalName
                            id                = $Assignment.principalId
                            directoryScopeId  = $Assignment.directoryScopeId
                            # Without PIM there is no eligibility and no end date: every assignment is permanent.
                            AssignmentType    = 'Permanent'
                            MemberType        = 'Direct'
                            PrincipalType     = $PrincipalType
                            EndDateTime       = $null
                        })
                }
            }
        }

        $GraphRequest = foreach ($Definition in $Definitions) {
            # Built-in definitions have id == templateId; custom roles have templateId = null
            $Members = if ($MemberMap.ContainsKey($Definition.id)) { @($MemberMap[$Definition.id]) } else { @() }
            $PermanentCount = @($Members | Where-Object { $_.AssignmentType -eq 'Permanent' }).Count
            $EligibleCount = @($Members | Where-Object { $_.AssignmentType -eq 'Eligible' }).Count
            $ActiveCount = @($Members | Where-Object { $_.AssignmentType -in @('Active', 'ActivatedFromEligible') }).Count
            $PolicySummary = $Policies[$Definition.id]
            [PSCustomObject]@{
                Id                  = $Definition.id
                roleTemplateId      = $Definition.templateId
                DisplayName         = $Definition.displayName
                Description         = $Definition.description
                Members             = @($Members)
                MemberCount         = $Members.Count
                PermanentCount      = $PermanentCount
                EligibleCount       = $EligibleCount
                ActiveCount         = $ActiveCount
                HasPermanentMembers = ($PermanentCount -gt 0)
                PIMCapable          = [bool]($null -ne $PIMRows)
                PIMPolicy           = $PolicySummary
                PIMPolicySummary    = if ($PolicySummary) { $PolicySummary.SummaryText } else { $null }
                isBuiltIn           = $Definition.isBuiltIn
                isEnabled           = $Definition.isEnabled
                SID                 = (Convert-AzureAdObjectIdToSid -ObjectID ($Definition.templateId ?? $Definition.id))
            }
        }
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        $GraphRequest = "Failed to list roles for tenant $TenantFilter. $($ErrorMessage.NormalizedError)"
        $StatusCode = [HttpStatusCode]::BadRequest
    }

    return [HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = $GraphRequest
    }
}
