function Find-CippMcpTool {
    <#
    .SYNOPSIS
        Searches and browses the read-only MCP tool catalog without dumping full schemas.
    .DESCRIPTION
        Backs the SearchTools core tool. Three modes, all returning compact, token-cheap results
        (name + category + one-line summary — never inputSchema):
          - No query and no category: an overview of every category with tool counts.
          - Category only: every tool in that category.
          - Query (optionally scoped to a category): keyword search ranked by relevance —
            exact name match, then name hits, then description hits, then category hits.
        Full schemas are fetched per-tool via GetToolInfo. Not an HTTP entrypoint.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        $Request,
        [string]$Query,
        [string]$Category,
        [int]$Limit = 25
    )

    if ($Limit -lt 1) { $Limit = 25 }
    if ($Limit -gt 100) { $Limit = 100 }

    # Dedupe by name: a path exposing both GET and POST projects one catalog entry per method.
    $ByName = [ordered]@{}
    foreach ($Entry in @(Get-CippMcpToolCatalog -Request $Request)) {
        $Name = [string]$Entry.name
        if (-not $ByName.Contains($Name) -or $Entry._method -eq 'POST') { $ByName[$Name] = $Entry }
    }
    $Catalog = @($ByName.Values)

    # Browse mode: no filters at all -> category overview.
    if ([string]::IsNullOrWhiteSpace($Query) -and [string]::IsNullOrWhiteSpace($Category)) {
        $Categories = [System.Collections.Generic.List[object]]::new()
        foreach ($Group in ($Catalog | Group-Object -Property { $_._category } | Sort-Object Name)) {
            $Categories.Add([ordered]@{ category = $Group.Name; toolCount = $Group.Count })
        }
        return [ordered]@{
            totalTools = $Catalog.Count
            categories = @($Categories)
            hint       = 'Call SearchTools with a category to list its tools, or with query keywords to search across all tools.'
        }
    }

    $Pool = $Catalog
    if (-not [string]::IsNullOrWhiteSpace($Category)) {
        $Pool = @($Catalog | Where-Object { [string]$_._category -eq $Category.Trim() })
        if ($Pool.Count -eq 0) {
            return [ordered]@{
                error      = "Unknown category '$Category'."
                categories = @($Catalog | ForEach-Object { [string]$_._category } | Sort-Object -Unique)
            }
        }
    }

    $Tokens = @($Query -split '[^\w]+' | Where-Object { $_ })
    $Scored = [System.Collections.Generic.List[object]]::new()
    foreach ($Entry in $Pool) {
        $Score = 0
        if ($Tokens.Count -gt 0) {
            $Name = [string]$Entry.name
            if ($Name -eq $Query.Trim()) { $Score += 200 }
            foreach ($Token in $Tokens) {
                $Pattern = [regex]::Escape($Token)
                if ($Name -match $Pattern) { $Score += 40 }
                elseif ([string]$Entry.description -match $Pattern) { $Score += 10 }
                if ([string]$Entry._category -match $Pattern) { $Score += 5 }
            }
            if ($Score -eq 0) { continue }
        }
        $Scored.Add([pscustomobject]@{ Score = $Score; Entry = $Entry })
    }

    $Ranked = @($Scored | Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, @{ Expression = { $_.Entry.name }; Descending = $false })

    $Results = [System.Collections.Generic.List[object]]::new()
    foreach ($Hit in ($Ranked | Select-Object -First $Limit)) {
        $Results.Add([ordered]@{
                name     = $Hit.Entry.name
                category = $Hit.Entry._category
                summary  = $Hit.Entry._summary
            })
    }

    Write-Information "[MCP] SearchTools query='$Query' category='$Category' -> $($Ranked.Count) matches, returning $($Results.Count)"

    $Hint = if ($Results.Count -eq 0) {
        'No matches. Try broader keywords, or call SearchTools with no arguments to browse categories.'
    } else {
        'Call GetToolInfo with names=[...] to get input schemas, then ExecTool with { name, arguments } to run one.'
    }

    return [ordered]@{
        matchCount = $Ranked.Count
        tools      = @($Results)
        hint       = $Hint
    }
}
