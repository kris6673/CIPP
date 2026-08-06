function Invoke-ListOpenApiSpec {
    <#
    .FUNCTIONALITY
        Entrypoint,AnyTenant
    .ROLE
        CIPP.Core.Read
    .DESCRIPTION
        Returns the CIPP OpenAPI 3.1 specification describing every HTTP endpoint, for the
        in-app API documentation browser. The document is generated from the entrypoint
        sources at build time, so it always matches the running version.
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $SpecPath = Join-Path -Path $env:CIPPRootPath -ChildPath 'Config/openapi.json'

    if (-not (Test-Path $SpecPath)) {
        return ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::NotFound
                Body       = @{ Results = 'OpenAPI specification not found. It is generated during the build; this deployment may predate it.' }
            })
    }

    # Streamed as the raw file rather than parsed and re-serialised: it is ~1.5 MB, the
    # round trip through ConvertFrom-Json/ConvertTo-Json costs real time per request, and
    # the spec deliberately contains keys differing only in case (displayName /
    # DisplayName) which a PSCustomObject would silently collapse.
    return ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Headers    = @{ 'Content-Type' = 'application/json' }
            Body       = [System.IO.File]::ReadAllText($SpecPath)
        })
}
