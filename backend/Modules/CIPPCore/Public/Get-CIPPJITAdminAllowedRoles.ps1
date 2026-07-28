function Get-CIPPJITAdminAllowedRoles {
    <#
    .SYNOPSIS
    Resolve which directory roles the calling user is permitted to assign via JIT Admin.

    .DESCRIPTION
    JIT Role Templates are named allow-lists of Entra directory roles that can be attached to a
    CIPP custom role (via the AllowedRolesTemplate property on the CustomRoles row). This function
    resolves the calling user's roles and returns the effective allow-list.

    Default-open semantics (so existing configurations are not disturbed):
      - Base roles (superadmin/admin/editor/readonly) and users with no custom role are unrestricted.
      - A custom role with NO JIT Role Template assigned grants access to all roles. Because access is
        a union across the caller's roles, holding any such role makes the caller unrestricted.
      - Only when EVERY one of the caller's custom roles carries a template is the caller restricted,
        in which case the allow-list is the union of those templates' role IDs.

    Fails closed for restricted callers: if a template reference cannot be read, that role contributes
    no allowed IDs (rather than opening access), so a lookup failure cannot be used to escalate.

    .PARAMETER Headers
    The request headers (containing x-ms-client-principal) used to resolve the caller.

    .OUTPUTS
    PSCustomObject with:
      Restricted     [bool]    - $true when the allow-list should be enforced.
      AllowedRoleIds [string[]] - directory role template IDs the caller may assign (only meaningful when Restricted).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Headers
    )

    $Unrestricted = [PSCustomObject]@{ Restricted = $false; AllowedRoleIds = @() }

    # Resolve the calling user's roles, including Entra group-based roles (mirrors Invoke-ExecRestoreBackup)
    try {
        $CallingUser = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Headers.'x-ms-client-principal')) | ConvertFrom-Json
    } catch {
        # Without a resolvable principal we cannot determine a custom role, so nothing is restricted.
        return $Unrestricted
    }

    if (($CallingUser.userRoles | Measure-Object).Count -eq 2 -and $CallingUser.userRoles -contains 'authenticated' -and $CallingUser.userRoles -contains 'anonymous') {
        $CallingUser = Test-CIPPAccessUserRole -User $CallingUser
    }

    $DefaultRoles = @('superadmin', 'admin', 'editor', 'readonly', 'anonymous', 'authenticated')
    $CustomRoleNames = @($CallingUser.userRoles | Where-Object { $DefaultRoles -notcontains $_ })

    # No custom role -> unrestricted (base roles have no template concept).
    if ($CustomRoleNames.Count -eq 0) {
        return $Unrestricted
    }

    $Table = Get-CIPPTable -tablename 'CustomRoles'
    $TemplateTable = Get-CIPPTable -tablename 'templates'
    $AllowedRoleIds = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($RoleName in $CustomRoleNames) {
        try {
            $SafeRole = ConvertTo-CIPPODataFilterValue -Value ($RoleName.ToLower()) -Type String
            $RoleRow = Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq 'CustomRoles' and RowKey eq '$SafeRole'"
        } catch {
            Write-Warning "JIT allowed-roles: failed to read custom role '$RoleName': $($_.Exception.Message)"
            # Cannot confirm a template for this role -> treat as restricted-but-empty (fail closed).
            continue
        }

        # A role with no template assigned grants all roles -> the caller is unrestricted.
        if (-not $RoleRow -or [string]::IsNullOrWhiteSpace($RoleRow.AllowedRolesTemplate)) {
            return $Unrestricted
        }

        try {
            $TemplateRef = $RoleRow.AllowedRolesTemplate | ConvertFrom-Json -ErrorAction Stop
        } catch {
            $TemplateRef = $RoleRow.AllowedRolesTemplate
        }
        $TemplateGuid = if ($TemplateRef -is [string]) { $TemplateRef } else { $TemplateRef.value ?? $TemplateRef.GUID }

        # An empty/blank template reference is equivalent to no template -> unrestricted.
        if ([string]::IsNullOrWhiteSpace($TemplateGuid)) {
            return $Unrestricted
        }

        try {
            $SafeGuid = ConvertTo-CIPPODataFilterValue -Value $TemplateGuid -Type Guid
            $TemplateRow = Get-CIPPAzDataTableEntity @TemplateTable -Filter "PartitionKey eq 'JITRoleTemplate' and RowKey eq '$SafeGuid'"
        } catch {
            Write-Warning "JIT allowed-roles: failed to read JIT Role Template '$TemplateGuid': $($_.Exception.Message)"
            $TemplateRow = $null
        }

        # Unresolved template contributes no allowed IDs (fail closed) but keeps the caller restricted.
        if (-not $TemplateRow) {
            continue
        }

        try {
            $TemplateData = $TemplateRow.JSON | ConvertFrom-Json -Depth 10 -ErrorAction Stop
        } catch {
            continue
        }
        foreach ($Role in @($TemplateData.roles)) {
            $Id = if ($Role -is [string]) { $Role } else { $Role.value ?? $Role.ObjectId }
            if (-not [string]::IsNullOrWhiteSpace($Id)) {
                [void]$AllowedRoleIds.Add([string]$Id)
            }
        }
    }

    return [PSCustomObject]@{
        Restricted     = $true
        AllowedRoleIds = @($AllowedRoleIds)
    }
}
