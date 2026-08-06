function Invoke-CippMcpApiRequest {
    <#
    .SYNOPSIS
        Executes one catalog tool by re-dispatching it through the CIPP API router.
    .DESCRIPTION
        Invokes the corresponding /api endpoint via New-CippCoreRequest using the caller's own
        principal headers. This guarantees Test-CIPPAccess (RBAC + tenant scoping + logging) runs
        for every tool call exactly as for a normal API request. The synthetic request is tagged
        with 'X-CIPP-Origin: mcp' so model-initiated calls are distinguishable in logs.
        Returns an MCP tool result object ({ content, isError }). Not an HTTP entrypoint.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        $Request,
        $TriggerMetadata,
        [string]$ToolName,
        $Arguments,
        [string]$Method = 'GET'
    )

    $ArgHash = ConvertTo-CippMcpHashtable -InputObject $Arguments

    # Clone caller headers (preserves the EasyAuth principal) and tag the origin for auditing.
    $Headers = ConvertTo-CippMcpHashtable -InputObject $Request.Headers
    $Headers['X-CIPP-Origin'] = 'mcp'

    $Query = @{}
    $Body = @{}
    if ($Method -eq 'POST') { $Body = $ArgHash } else { $Query = $ArgHash }

    $InnerRequest = [pscustomobject]@{
        Params  = @{ CIPPEndpoint = $ToolName }
        Method  = $Method
        Headers = $Headers
        Query   = $Query
        Body    = $Body
    }

    try {
        $Response = New-CippCoreRequest -Request $InnerRequest -TriggerMetadata $TriggerMetadata
    } catch {
        return [ordered]@{
            content = @(@{ type = 'text'; text = "Tool execution failed: $($_.Exception.Message)" })
            isError = $true
        }
    }

    $ResultBody = $Response.Body
    $Text = if ($ResultBody -is [string]) { $ResultBody } else { $ResultBody | ConvertTo-Json -Depth 20 -Compress }
    $IsError = $null -ne $Response.StatusCode -and [int]$Response.StatusCode -ge 400

    return [ordered]@{
        content = @(@{ type = 'text'; text = "$Text" })
        isError = $IsError
    }
}
