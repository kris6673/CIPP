function Get-CippMcpToolCatalog {
    <#
    .SYNOPSIS
        Projects the CIPP OpenAPI spec into the full read-only tool catalog, with optional per-connection filtering.
    .DESCRIPTION
        Returns every operation whose x-cipp-role ends in '.Read' (never '.ReadWrite') as a catalog
        entry: name (the API endpoint), description, inputSchema (JSON Schema built from the
        operation's query parameters / request body with $ref inlined), read-only annotations, and
        internal routing fields (_category, _method, _summary). The projection is cached per worker;
        pass -Force to rebuild.

        The catalog is NOT advertised to MCP clients wholesale — Get-CippMcpToolList exposes a fixed
        five-tool gateway, and this catalog backs its SearchTools / GetToolInfo / ExecTool tools.

        The connector URL's query string filters the catalog (the query is NOT part of the OAuth
        resource, so it does not affect auth). One CIPP instance can therefore back several
        connector instances, each scoped to a subset. Supported query parameters:
          ?tags=Identity,Exchange     only tools in those top-level CIPP categories (the OpenAPI tag)
          ?tools=ListUsers,ListGroups explicit allow-list of tool names
          ?first=70 / ?limit=70       cap the catalog size
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        $Request,
        [switch]$Force
    )

    if (-not $script:CippMcpToolCatalogCache -or $Force) {
        $Spec = Get-CippMcpSpec
        $Tools = [System.Collections.Generic.List[object]]::new()

        foreach ($PathEntry in $Spec['paths'].GetEnumerator()) {
            $Endpoint = $PathEntry.Key -replace '^/api/', ''

            # Never expose the MCP transport itself as a tool.
            if ($Endpoint -eq 'ExecMcp') { continue }

            foreach ($MethodEntry in $PathEntry.Value.GetEnumerator()) {
                $Method = [string]$MethodEntry.Key
                if ($Method -notin @('get', 'post')) { continue }

                $Op = $MethodEntry.Value
                $Role = $Op['x-cipp-role']

                # Read-only surface only.
                if (-not $Role -or $Role -notmatch '\.Read$') { continue }

                # Defensive backstop: never expose an endpoint whose name implies a mutation,
                # even if its x-cipp-role is mislabeled '.Read' (e.g. AddTestReport, EditIntunePolicy).
                if ($Endpoint -match '^(Add|Set|Remove|Delete|Edit|New|Update|Disable|Enable|Reset|Revoke|Push|Clear|Start|Stop|Rename|Move|Copy)') { continue }

                $Properties = [ordered]@{}
                $RequiredList = [System.Collections.Generic.List[string]]::new()

                # Query / path parameters.
                foreach ($ParamRaw in @($Op['parameters'])) {
                    if (-not $ParamRaw) { continue }
                    $Param = Resolve-CippMcpNode -Node $ParamRaw -Spec $Spec
                    if ($Param['in'] -notin @('query', 'path')) { continue }
                    $Schema = if ($Param['schema']) { $Param['schema'] } else { @{ type = 'string' } }
                    $Properties[[string]$Param['name']] = $Schema
                    if ($Param['required']) { $RequiredList.Add([string]$Param['name']) }
                }

                # Request body (uncommon for reads; included for completeness).
                if ($Op['requestBody'] -and $Op['requestBody']['content'] -and $Op['requestBody']['content']['application/json']) {
                    $BodySchema = Resolve-CippMcpNode -Node $Op['requestBody']['content']['application/json']['schema'] -Spec $Spec
                    if ($BodySchema -and $BodySchema['properties']) {
                        foreach ($BodyProp in $BodySchema['properties'].GetEnumerator()) {
                            $Properties[[string]$BodyProp.Key] = $BodyProp.Value
                        }
                        foreach ($Req in @($BodySchema['required'])) { if ($Req) { $RequiredList.Add([string]$Req) } }
                    }
                }

                $InputSchema = [ordered]@{
                    type       = 'object'
                    properties = $Properties
                }
                if ($RequiredList.Count -gt 0) {
                    $InputSchema['required'] = @($RequiredList | Select-Object -Unique)
                }

                $Tag = @($Op['tags'])[0]
                $Category = if ($Tag) { ([string]$Tag -split '\s*>\s*')[0].Trim() } else { 'Uncategorized' }

                $Description = Get-CippMcpDescription -Operation $Op

                # Compact one-liner used by SearchTools results (schema-free, token-cheap).
                $Summary = [string]$Op['summary']
                if ([string]::IsNullOrWhiteSpace($Summary)) {
                    $Summary = (($Description -replace '^\[[^\]]+\]\s*', '') -split "\r?\n")[0].Trim()
                }
                if ($Summary.Length -gt 160) { $Summary = $Summary.Substring(0, 157) + '...' }

                $Tools.Add([ordered]@{
                        name        = $Endpoint
                        description = $Description
                        inputSchema = $InputSchema
                        annotations = [ordered]@{ title = $Endpoint; readOnlyHint = $true }
                        _category   = $Category
                        _method     = $Method.ToUpper()
                        _summary    = $Summary
                    })
            }
        }

        $script:CippMcpToolCatalogCache = $Tools
    }

    $Filtered = @($script:CippMcpToolCatalogCache)

    # Per-connection filtering from the connector URL's query string.
    $Query = $Request.Query
    $TagFilter = "$($Query.tags ?? $Query.category ?? $Query.tag)".Trim()
    if ($TagFilter) {
        $WantedCats = @($TagFilter -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $Filtered = @($Filtered | Where-Object { $_._category -in $WantedCats })
    }

    $ToolFilter = "$($Query.tools)".Trim()
    if ($ToolFilter) {
        $WantedTools = @($ToolFilter -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $Filtered = @($Filtered | Where-Object { $_.name -in $WantedTools })
    }

    $Limit = ($Query.first ?? $Query.limit) -as [int]
    if ($Limit -gt 0) {
        $Filtered = @($Filtered | Select-Object -First $Limit)
    }

    return $Filtered
}
