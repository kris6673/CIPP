function New-CIPPCAGapFinding {
    <#
    .SYNOPSIS
        Builds one Conditional Access gap finding in the shape every Test-CIPPCAGap* check returns.
    .DESCRIPTION
        Returns a PSCustomObject with id (stamped later by Get-CIPPCAGapAnalysis), title, severity, category,
        description, affectedPolicies (display names), remediation, fix ($null or @{ caTemplate = '<template name>' })
        and relatedIds (app/role/location IDs the finding refers to).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info')]
        [string]$Severity,
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Description,
        [AllowEmptyString()]
        [string]$Remediation = '',
        [AllowEmptyCollection()]
        [string[]]$AffectedPolicies = @(),
        [string]$CaTemplate,
        [AllowEmptyCollection()]
        [string[]]$RelatedIds = @()
    )

    $Fix = $null
    if (-not [string]::IsNullOrWhiteSpace($CaTemplate)) {
        $Fix = @{ caTemplate = $CaTemplate }
    }

    [PSCustomObject]@{
        id               = $null
        title            = $Title
        severity         = $Severity
        category         = $Category
        description      = $Description
        affectedPolicies = [string[]]@($AffectedPolicies | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        remediation      = $Remediation
        fix              = $Fix
        relatedIds       = [string[]]@($RelatedIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
}
