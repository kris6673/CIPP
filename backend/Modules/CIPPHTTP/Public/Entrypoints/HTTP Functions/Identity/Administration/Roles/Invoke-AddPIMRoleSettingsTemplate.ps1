function Invoke-AddPIMRoleSettingsTemplate {
    <#
    .FUNCTIONALITY
        Entrypoint,AnyTenant
    .ROLE
        Identity.Role.ReadWrite
    .SYNOPSIS
        Create or update a PIM role settings template.
    .DESCRIPTION
        Saves a Privileged Identity Management role settings template. The settings are validated against CIPP's secure floor (activation must expire within 24 hours and require MFA or an authentication context plus a justification; eligibilities and active assignments must expire within a year; active assignments must require a justification). A template below the floor is rejected with the list of problems rather than silently adjusted. Pass GUID to update an existing template.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers

    try {
        # Existing template GUID when editing.
        $GUID = $Request.Body.GUID
        $TemplateName = "$($Request.Body.templateName)".Trim()
        $Description = "$($Request.Body.description)".Trim()
        # PrivilegedRoles | AllRoles | Custom
        $RoleScope = $Request.Body.roleScope.value ?? $Request.Body.roleScope
        # Roles (label/value pairs of role template ids) when roleScope is Custom.
        $Roles = @($Request.Body.roles | ForEach-Object {
                if ($null -eq $_) { return }
                $Value = $_.value ?? $_
                $Label = $_.label ?? $_.value ?? $_
                if ([string]::IsNullOrWhiteSpace("$Value")) { return }
                @{ label = "$Label"; value = "$Value" }
            })

        if ([string]::IsNullOrWhiteSpace($TemplateName)) { throw 'templateName is required' }
        if ([string]::IsNullOrWhiteSpace($RoleScope)) { $RoleScope = 'PrivilegedRoles' }
        if ($RoleScope -notin @('PrivilegedRoles', 'AllRoles', 'Custom')) { throw "roleScope '$RoleScope' is not valid. Use PrivilegedRoles, AllRoles or Custom." }
        if ($RoleScope -eq 'Custom' -and $Roles.Count -eq 0) { throw 'Select at least one role when roleScope is Custom.' }

        # Role activation, eligibility, assignment, approval and notification settings.
        $Settings = ConvertTo-CIPPPIMRoleSettings -InputObject $Request.Body.settings
        $Floor = Test-CIPPPIMRoleSettingsFloor -Settings $Settings
        if (-not $Floor.Valid) {
            $Message = "PIM role settings template '$TemplateName' was not saved because it is below the secure floor: $($Floor.Errors -join ' ')"
            Write-LogMessage -headers $Headers -API $APIName -message $Message -Sev 'Error'
            return [HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = @{ Results = @($Message) + @($Floor.Errors | ForEach-Object { @{ resultText = $_; state = 'error' } }) }
            }
        }

        $UserDetails = try {
            ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Headers.'x-ms-client-principal')) | ConvertFrom-Json).userDetails
        } catch { 'Unknown' }
        $Now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

        $Table = Get-CippTable -tablename 'templates'
        $Existing = $null
        if (-not [string]::IsNullOrWhiteSpace($GUID)) {
            $SafeGUID = ConvertTo-CIPPODataFilterValue -Value $GUID -Type String
            $Existing = Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq 'PIMRoleSettingsTemplate' and RowKey eq '$SafeGUID'"
            if (-not $Existing) { throw "PIM role settings template $GUID was not found" }
        } else {
            $GUID = (New-Guid).Guid
        }

        $ExistingData = if ($Existing) { $Existing.JSON | ConvertFrom-Json -Depth 100 } else { $null }
        $TemplateObject = [ordered]@{
            templateName = $TemplateName
            description  = $Description
            roleScope    = $RoleScope
            roles        = @($Roles)
            settings     = $Settings
            createdBy    = $ExistingData.createdBy ?? $UserDetails
            createdDate  = $ExistingData.createdDate ?? $Now
            updatedBy    = $UserDetails
            updatedDate  = $Now
            GUID         = $GUID
        }

        $JSON = ConvertTo-Json -InputObject $TemplateObject -Depth 20 -Compress
        $Table.Force = $true
        Add-CIPPAzDataTableEntity @Table -Entity @{
            JSON         = "$JSON"
            RowKey       = "$GUID"
            PartitionKey = 'PIMRoleSettingsTemplate'
            GUID         = "$GUID"
        }

        $Verb = if ($Existing) { 'Updated' } else { 'Created' }
        $Result = "$Verb PIM role settings template '$TemplateName' with GUID $GUID"
        Write-LogMessage -headers $Headers -API $APIName -message $Result -Sev 'Info'
        foreach ($Warning in $Floor.Warnings) {
            # Above the recommended value but inside the hard cap: allowed, and visible in the logbook.
            Write-LogMessage -headers $Headers -API $APIName -message "PIM role settings template '$TemplateName': $Warning" -Sev 'Warning'
        }
        $Results = @($Result) + @($Floor.Warnings | ForEach-Object { @{ resultText = $_; state = 'warning' } })
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        $Results = @("Failed to save PIM role settings template: $($ErrorMessage.NormalizedError)")
        Write-LogMessage -headers $Headers -API $APIName -message $Results[0] -Sev 'Error' -LogData $ErrorMessage
        $StatusCode = [HttpStatusCode]::BadRequest
    }

    return [HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = @{ Results = @($Results) }
    }
}
