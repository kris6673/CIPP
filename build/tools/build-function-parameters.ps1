# Generate Config/function-parameters.json, the pregenerated help cache
# Invoke-ListFunctionParameters serves from. Without it the endpoint runs
# Get-Help across every CIPPCore public function per request (minutes -> timeout).
# Extracts comment-based help straight from the module source via the AST
# (FunctionDefinitionAst.GetHelpContent), no module import, runs in seconds,
# so every build regenerates it.
param(
    [string]$ModulePath = "$PSScriptRoot/../../backend/Modules/CIPPCore",
    [string]$OutputPath = "$PSScriptRoot/../../backend/Config/function-parameters.json"
)

$ErrorActionPreference = 'Stop'

$publicPath = Join-Path $ModulePath 'Public'
if (-not (Test-Path $publicPath)) {
    throw "Module source not found at '$publicPath'."
}

# keep in sync with $CommonParameters in Invoke-ListFunctionParameters.ps1
$commonParameters = @(
    'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable',
    'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable',
    'TenantFilter', 'APIName', 'Headers', 'ProgressAction', 'WhatIf', 'Confirm', 'NoAuthCheck'
)

function Test-MandatoryParameter {
    param([Parameter(Mandatory = $true)]$ParameterAst)

    foreach ($attr in $ParameterAst.Attributes) {
        if ($attr -isnot [System.Management.Automation.Language.AttributeAst]) {
            continue
        }
        if ($attr.TypeName.Name -notin @('Parameter', 'ParameterAttribute')) {
            continue
        }
        foreach ($namedArg in $attr.NamedArguments) {
            if ($namedArg.ArgumentName -eq 'Mandatory' -and (Test-AttributeArgTrue -NamedArg $namedArg)) {
                return $true
            }
        }
    }
    return $false
}

function Test-AttributeArgTrue {
    param([Parameter(Mandatory = $true)]$NamedArg)

    # [Parameter(Mandatory)] flag form, or any truthy constant (= $true, = 1)
    if ($NamedArg.ExpressionOmitted) {
        return $true
    }
    try {
        return [bool]$NamedArg.Argument.SafeGetValue()
    } catch {
        return $false
    }
}

function Get-SyntaxSynopsis {
    param(
        [Parameter(Mandatory = $true)]$Definition,
        $AstParameters
    )

    # mirrors the syntax line Get-Help synthesizes as the synopsis for functions
    # with no comment help; the scheduler form shows it under "PowerShell Command:"
    $isAdvanced = $false
    $shouldProcess = $false
    $defaultSetName = $null
    $blockAttributes = @()
    if ($Definition.Body.ParamBlock) {
        $blockAttributes = $Definition.Body.ParamBlock.Attributes
    }
    foreach ($attr in @($blockAttributes)) {
        if ($attr.TypeName.Name -notin @('CmdletBinding', 'CmdletBindingAttribute')) {
            continue
        }
        $isAdvanced = $true
        foreach ($namedArg in $attr.NamedArguments) {
            if ($namedArg.ArgumentName -eq 'SupportsShouldProcess' -and (Test-AttributeArgTrue -NamedArg $namedArg)) {
                $shouldProcess = $true
            }
            if ($namedArg.ArgumentName -eq 'DefaultParameterSetName') {
                $defaultSetName = $namedArg.Argument.Value
            }
        }
    }

    # flatten each parameter to name/type/switch plus its [Parameter] attrs
    # (set name, mandatory, explicit position)
    $paramInfos = [System.Collections.Generic.List[object]]::new()
    foreach ($parameter in @($AstParameters)) {
        if (-not $parameter) {
            continue
        }
        $info = [ordered]@{
            Name     = $parameter.Name.VariablePath.UserPath
            TypeText = 'Object'
            IsSwitch = $false
            Attrs    = [System.Collections.Generic.List[object]]::new()
        }
        foreach ($attr in $parameter.Attributes) {
            if ($attr -is [System.Management.Automation.Language.TypeConstraintAst]) {
                $reflectionType = $attr.TypeName.GetReflectionType()
                if ($reflectionType) {
                    # accelerated types render as their accelerator (string, psobject);
                    # others render namespace-stripped (List[Object], X509Certificate2)
                    $typeText = [Microsoft.PowerShell.ToStringCodeMethods]::Type([psobject]$reflectionType)
                    if ($reflectionType -eq [System.Management.Automation.SwitchParameter]) {
                        $info.IsSwitch = $true
                    }
                } else {
                    # unresolvable on this build host, strip the namespace the same
                    # way so image and dev-host output can't diverge
                    $typeText = $attr.TypeName.ToString()
                }
                $info.TypeText = $typeText -replace '(?:\w+\.)+(?=\w)', ''
            } elseif ($attr -is [System.Management.Automation.Language.AttributeAst] -and $attr.TypeName.Name -in @('Parameter', 'ParameterAttribute')) {
                $isAdvanced = $true
                $pa = [ordered]@{ SetName = $null; Mandatory = $false; Position = $null }
                foreach ($namedArg in $attr.NamedArguments) {
                    switch ($namedArg.ArgumentName) {
                        'ParameterSetName' {
                            $pa.SetName = $namedArg.Argument.Value
                        }
                        'Mandatory' {
                            if (Test-AttributeArgTrue -NamedArg $namedArg) {
                                $pa.Mandatory = $true
                            }
                        }
                        'Position' {
                            try {
                                $pa.Position = [int]$namedArg.Argument.SafeGetValue()
                            } catch {
                                # non-constant position, treat as named
                                Write-Verbose "Ignoring non-constant Position on $($info.Name): $($_.Exception.Message)"
                            }
                        }
                    }
                }
                $info.Attrs.Add($pa)
            }
        }
        $paramInfos.Add($info)
    }

    # parameter sets: default set renders first (even when no parameter names it,
    # Get-Help still emits a block for it), the rest by first appearance.
    # set names are case-sensitive identities, so all matching is ordinal
    $setNames = [System.Collections.Generic.List[string]]::new()
    $anyExplicitPosition = $false
    foreach ($info in $paramInfos) {
        foreach ($pa in $info.Attrs) {
            if ($pa.SetName -and $pa.SetName -cne '__AllParameterSets' -and -not $setNames.Contains($pa.SetName)) {
                $setNames.Add($pa.SetName)
            }
            if ($null -ne $pa.Position) {
                $anyExplicitPosition = $true
            }
        }
    }
    if ($defaultSetName -and $setNames.Count -gt 0) {
        $null = $setNames.Remove($defaultSetName)
        $setNames.Insert(0, $defaultSetName)
    }

    # positions are auto-assigned in declaration order only when there are no
    # parameter sets and no explicit Position anywhere; otherwise only explicitly
    # positioned parameters render positionally and the rest render named
    $autoPositional = ($setNames.Count -eq 0) -and (-not $anyExplicitPosition)

    $blocks = [System.Collections.Generic.List[string]]::new()
    if ($setNames.Count -eq 0) {
        # no parameter sets, render the single implicit set
        $setNames.Add($null)
    }
    foreach ($setName in $setNames) {
        $positionalEntries = [System.Collections.Generic.List[object]]::new()
        $mandatoryTokens = [System.Collections.Generic.List[string]]::new()
        $optionalTokens = [System.Collections.Generic.List[string]]::new()
        $declIndex = 0
        foreach ($info in $paramInfos) {
            $declIndex++
            # attr scoped to this set wins; set-less attrs apply to every set
            $effective = $info.Attrs | Where-Object { $_.SetName -ceq $setName } | Select-Object -First 1
            if (-not $effective) {
                $effective = $info.Attrs | Where-Object { -not $_.SetName -or $_.SetName -ceq '__AllParameterSets' } | Select-Object -First 1
            }
            if (-not $effective -and $info.Attrs.Count -gt 0) {
                # every attr names some other set, param not in this one
                continue
            }
            $mandatory = $effective -and $effective.Mandatory
            $position = if ($effective) { $effective.Position } else { $null }
            if ($info.IsSwitch) {
                $token = if ($mandatory) { "-$($info.Name)" } else { "[-$($info.Name)]" }
                if ($null -ne $position) {
                    $positionalEntries.Add([pscustomobject]@{ Position = $position; Token = $token })
                } elseif ($mandatory -and -not $autoPositional) {
                    $mandatoryTokens.Add($token)
                } else {
                    # auto-positional mode keeps every switch in one trailing
                    # declaration-order group, matching Get-Help
                    $optionalTokens.Add($token)
                }
            } elseif ($autoPositional -or $null -ne $position) {
                $token = if ($mandatory) { "[-$($info.Name)] <$($info.TypeText)>" } else { "[[-$($info.Name)] <$($info.TypeText)>]" }
                $sortKey = if ($null -ne $position) { $position } else { $declIndex }
                $positionalEntries.Add([pscustomobject]@{ Position = $sortKey; Token = $token })
            } elseif ($mandatory) {
                $mandatoryTokens.Add("-$($info.Name) <$($info.TypeText)>")
            } else {
                $optionalTokens.Add("[-$($info.Name) <$($info.TypeText)>]")
            }
        }
        $tokens = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in ($positionalEntries | Sort-Object -Property Position -Stable)) {
            $tokens.Add($entry.Token)
        }
        $tokens.AddRange($mandatoryTokens)
        $tokens.AddRange($optionalTokens)
        if ($shouldProcess) {
            $tokens.Add('[-WhatIf]')
            $tokens.Add('[-Confirm]')
        }
        if ($isAdvanced) {
            $tokens.Add('[<CommonParameters>]')
        }
        $blocks.Add((@($Definition.Name) + $tokens) -join ' ')
    }
    return $blocks -join "`r`n`r`n"
}

$functions = @{}
$parseFailures = 0

foreach ($file in Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse -File) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Host "Parse errors in $($file.FullName); skipping."
        $parseFailures++
        continue
    }

    # top-level definitions only, nested helpers are not module commands
    $definitions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)

    foreach ($definition in $definitions) {
        $help = $null
        try {
            $help = $definition.GetHelpContent()

            $helpParamMap = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
            if ($help -and $help.Parameters) {
                foreach ($entry in $help.Parameters.GetEnumerator()) {
                    $helpParamMap[$entry.Key] = ($entry.Value ?? '').Trim()
                }
            }

            # function Foo { param(...) } puts parameters on the body's param block
            $astParameters = $definition.Parameters
            if (-not $astParameters -and $definition.Body.ParamBlock) {
                $astParameters = $definition.Body.ParamBlock.Parameters
            }

            $parameterList = [System.Collections.Generic.List[object]]::new()
            foreach ($parameter in @($astParameters)) {
                if (-not $parameter) {
                    continue
                }
                $name = $parameter.Name.VariablePath.UserPath
                if ($commonParameters -contains $name) {
                    continue
                }
                $description = $null
                if ($helpParamMap.ContainsKey($name)) {
                    $description = $helpParamMap[$name]
                }
                $parameterList.Add([ordered]@{
                        Name        = $name
                        # StaticType falls back to System.Object for types the build host can't resolve
                        Type        = $parameter.StaticType.FullName
                        Description = $description
                        Required    = Test-MandatoryParameter -ParameterAst $parameter
                    })
            }

            # no comment help at all -> Get-Help would synthesize a syntax line
            # as the synopsis, match that (help present but no .SYNOPSIS stays empty)
            $synopsis = (($help.Synopsis ?? '') + '').Trim()
            if (-not $help) {
                $synopsis = Get-SyntaxSynopsis -Definition $definition -AstParameters $astParameters
            }

            $functions[$definition.Name] = [ordered]@{
                Functionality = (($help.Functionality ?? '') + '').Trim()
                Synopsis      = $synopsis
                Parameters    = @($parameterList)
            }
        } catch {
            # one exotic function must not fail the whole image build. keep the
            # Functionality when help parsed, it drives the endpoint's
            # Entrypoint/Internal filtering; a '' would unhide the function
            Write-Host "Failed to build metadata for $($definition.Name): $($_.Exception.Message). Writing fallback entry."
            $functions[$definition.Name] = [ordered]@{
                Functionality = (($help.Functionality ?? '') + '').Trim()
                Synopsis      = ''
                Parameters    = @()
            }
        }
    }
}

if ($parseFailures -gt 0) {
    throw "$parseFailures file(s) under '$publicPath' failed to parse; their functions would silently vanish from the cache."
}
if ($functions.Count -eq 0) {
    throw "No functions found under '$publicPath'."
}

$null = New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force

# ordinal sort so windows dev hosts and the linux build stage emit identical files
$sortedNames = [string[]]$functions.Keys
[System.Array]::Sort($sortedNames, [System.StringComparer]::Ordinal)
$functionParameters = [ordered]@{}
foreach ($name in $sortedNames) {
    $functionParameters[$name] = $functions[$name]
}

$json = $functionParameters | ConvertTo-Json -Depth 8 -Compress
# write-then-move so a dev container reading through the bind mount never sees
# a half-written file (a partial read knocks that worker onto the slow path)
Set-Content -Path "$OutputPath.tmp" -Value $json -Encoding UTF8
Move-Item -Path "$OutputPath.tmp" -Destination $OutputPath -Force

Write-Host "Wrote parameter metadata for $($functionParameters.Count) functions to $OutputPath ($parseFailures parse failures)"
