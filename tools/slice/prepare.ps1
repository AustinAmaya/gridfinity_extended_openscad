<#
.SYNOPSIS
    Prepare a Bambu Studio project .3mf by swapping freshly-rendered meshes into the saved
    slicer template, WITHOUT slicing. The output carries the template's H2D / PLA / supports
    config + plate binding and the new geometry -- open it in Bambu Studio, slice, print.

.EXAMPLE
    .\tools\slice\prepare.ps1 -Parts out\paper_organizer.stl -Output out\paper_organizer.3mf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Parts,
    [Parameter(Mandatory)][string]$Output,
    [string]$Template = 'gridfinity-slicer-template.3mf'
)
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

python "$RepoRoot\tools\slice\swap_mesh.py" $Template $Output @Parts
if ($LASTEXITCODE -ne 0) { throw "swap_mesh.py failed" }

# Deliver into the single print-ready\ folder (open these in Bambu Studio, slice, print).
$ready = Join-Path $RepoRoot "print-ready"
New-Item -ItemType Directory -Force $ready | Out-Null
Copy-Item $Output (Join-Path $ready (Split-Path $Output -Leaf)) -Force

Write-Host "Prepared -> $Output  (+ print-ready\$(Split-Path $Output -Leaf))" -ForegroundColor Green
Write-Host "  Open in Bambu Studio -> Slice -> Send/Print. Geometry + settings only; not sliced." -ForegroundColor Cyan
