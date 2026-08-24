# Pester tests for Invoke-AddPIMRoleSettingsTemplate.
#
# A PIM role settings template that weakens a tenant below the secure floor must be rejected at
# save time with the reasons, and nothing may be written. A template above the recommended
# activation (8h) but inside the hard cap (24h) saves with a warning that reaches the logbook.

BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
    $FunctionPath = Join-Path $RepoRoot 'Modules/CIPPHTTP/Public/Entrypoints/HTTP Functions/Identity/Administration/Roles/Invoke-AddPIMRoleSettingsTemplate.ps1'
    if (-not (Test-Path $FunctionPath)) { throw "Could not locate Invoke-AddPIMRoleSettingsTemplate.ps1 at $FunctionPath" }

    class HttpResponseContext {
        [object]$StatusCode
        [object]$Body
    }
    $Accelerators = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    if (-not ('HttpStatusCode' -as [type])) {
        $Accelerators::Add('HttpStatusCode', [System.Net.HttpStatusCode])
    }

    . (Join-Path $RepoRoot 'Modules/CIPPCore/Public/PIM/ConvertTo-CIPPPIMRoleSettings.ps1')
    . (Join-Path $RepoRoot 'Modules/CIPPCore/Public/PIM/Test-CIPPPIMRoleSettingsFloor.ps1')

    function Get-CippTable { param($tablename) @{} }
    function Get-CIPPAzDataTableEntity { param($Filter) }
    function Add-CIPPAzDataTableEntity { param($Entity, $Force) }
    function ConvertTo-CIPPODataFilterValue { param($Value, $Type) $Value }
    function Write-LogMessage { param($headers, $API, $tenant, $message, $Sev, $LogData) }
    function Get-CippException { param($Exception) @{ NormalizedError = "$Exception" } }

    . $FunctionPath

    function New-TemplateRequest {
        param([hashtable]$Settings = @{}, [hashtable]$Body = @{})
        $DefaultSettings = @{
            activationMaxDuration                 = 'PT8H'
            activationRequires                    = @{ label = 'MFA'; value = 'MFA' }
            activationRequiresJustification       = $true
            eligibilityMaxDuration                = 'P365D'
            activeAssignmentMaxDuration           = 'P180D'
            activeAssignmentRequiresJustification = $true
        }
        foreach ($Key in $Settings.Keys) { $DefaultSettings[$Key] = $Settings[$Key] }
        $RequestBody = [pscustomobject]@{
            templateName = 'Secure PIM'
            description  = 'test'
            roleScope    = @{ label = 'Privileged roles'; value = 'PrivilegedRoles' }
            roles        = @()
            settings     = [pscustomobject]$DefaultSettings
        }
        foreach ($Key in $Body.Keys) { $RequestBody | Add-Member -NotePropertyName $Key -NotePropertyValue $Body[$Key] -Force }
        [pscustomobject]@{
            Body    = $RequestBody
            Headers = @{ 'x-ms-client-principal' = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('{"userDetails":"tester@cipp"}')) }
            Params  = @{ CIPPEndpoint = 'AddPIMRoleSettingsTemplate' }
        }
    }
}

Describe 'Invoke-AddPIMRoleSettingsTemplate' {
    BeforeEach {
        $script:Saved = $null
        Mock Get-CippTable { @{} }
        Mock Get-CIPPAzDataTableEntity { $null }
        Mock Add-CIPPAzDataTableEntity { $script:Saved = $Entity }
        Mock Write-LogMessage {}
    }

    It 'saves a template that meets the floor' {
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest)
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::OK)
        Should -Invoke Add-CIPPAzDataTableEntity -Times 1 -Exactly
        $script:Saved.PartitionKey | Should -Be 'PIMRoleSettingsTemplate'
        $Stored = $script:Saved.JSON | ConvertFrom-Json
        $Stored.templateName | Should -Be 'Secure PIM'
        $Stored.roleScope | Should -Be 'PrivilegedRoles'
        $Stored.settings.activationRequires | Should -Be 'MFA'
        $Stored.settings.activationMaxDuration | Should -Be 'PT8H'
        $Stored.createdBy | Should -Be 'tester@cipp'
    }

    It 'rejects a template below the floor and writes nothing' {
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest @{ activationRequires = 'None'; activationMaxDuration = 'PT48H' })
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::BadRequest)
        $Text = ($Response.Body.Results | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.resultText } }) -join ' '
        $Text | Should -Match 'below the secure floor'
        $Text | Should -Match 'exceeds the maximum of PT24H'
        $Text | Should -Match 'must require MFA or an authentication context'
        Should -Invoke Add-CIPPAzDataTableEntity -Times 0 -Exactly
    }

    It 'rejects a template that allows permanent eligibility' {
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest @{ eligibilityMaxDuration = '' })
        # An empty duration is normalised to the secure default, so permanence can only be
        # expressed by exceeding the cap - which is refused.
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::OK)
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest @{ eligibilityMaxDuration = 'P10Y' })
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::BadRequest)
    }

    It 'saves with a warning when activation exceeds the recommended 8h but not the 24h cap' {
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest @{ activationMaxDuration = 'PT12H' })
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::OK)
        $Warnings = @($Response.Body.Results | Where-Object { $_ -isnot [string] -and $_.state -eq 'warning' })
        $Warnings.Count | Should -Be 1
        $Warnings[0].resultText | Should -Match 'exceeds the recommended PT8H'
        Should -Invoke Write-LogMessage -Times 1 -ParameterFilter { $Sev -eq 'Warning' -and $message -match 'exceeds the recommended' }
    }

    It 'requires roles when the scope is Custom' {
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest -Body @{ roleScope = 'Custom'; roles = @() })
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::BadRequest)
        Should -Invoke Add-CIPPAzDataTableEntity -Times 0 -Exactly
    }

    It 'updates in place when a GUID is supplied and keeps the original creator' {
        $script:Existing = [pscustomobject]@{ RowKey = 'abc'; GUID = 'abc'; JSON = (@{ templateName = 'Old'; createdBy = 'first@cipp'; createdDate = '2026-01-01T00:00:00Z' } | ConvertTo-Json -Compress) }
        Mock Get-CIPPAzDataTableEntity { $script:Existing }
        $Response = Invoke-AddPIMRoleSettingsTemplate -Request (New-TemplateRequest -Body @{ GUID = 'abc' })
        $Response.StatusCode | Should -Be ([System.Net.HttpStatusCode]::OK)
        $script:Saved.RowKey | Should -Be 'abc'
        ($script:Saved.JSON | ConvertFrom-Json).createdBy | Should -Be 'first@cipp'
        ($script:Saved.JSON | ConvertFrom-Json).updatedBy | Should -Be 'tester@cipp'
    }
}
