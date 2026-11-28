function Invoke-CIPPBaselinePurviewLabelConsent {
    <#
    .SYNOPSIS
        Executor for PurviewLabelConsent: extends sensitivity labeling to Purview Data Map assets.
    .DESCRIPTION
        Set-PolicyConfig throws when the consent is already on, and the Secure Score read lags
        the setting by a day or more, so a tenant that is already on is expected here. Only
        that error is swallowed, and reported as no change; anything else is a real failure.
        New-ExoRequest can Write-Error and return without sending, hence -ErrorAction Stop.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param($Remediate, $TenantFilter, $Current)

    try {
        $null = New-ExoRequest -tenantid $TenantFilter -cmdlet 'Set-PolicyConfig' -cmdParams @{ PurviewLabelConsent = $true } -Compliance -ErrorAction Stop
    } catch {
        if ($_.Exception.Message -notmatch 'PurviewLabelAlreadyTurnOn|already turned on') { throw }
        [PSCustomObject]@{ Changed = $false }
    }
}
