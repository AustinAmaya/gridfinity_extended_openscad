<#
.SYNOPSIS
    One command from .scad to print-ready .3mf: render the model (dockerized OpenSCAD),
    verify the mesh is a single connected shell, then swap it into the saved Bambu Studio
    slicer template. Output lands in print-ready\<name>.3mf -- open, slice, print.

.EXAMPLE
    .\tools\slice\print-prep.ps1 gridfinity_paper_organizer.scad

.EXAMPLE
    .\tools\slice\print-prep.ps1 gridfinity_basic_cup.scad -Name cup_2x3 -Define width=2,depth=3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputScad,
    [string]$Name,                 # output base name (default: scad file basename)
    [string[]]$Define,             # OpenSCAD -D overrides, passed through to render.ps1
    [string]$Template = 'gridfinity-slicer-template.3mf'
)
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $Name) { $Name = [IO.Path]::GetFileNameWithoutExtension($InputScad) }

$stl = "out\$Name.stl"
& "$RepoRoot\tools\render\render.ps1" $InputScad $stl -Define $Define

python "$RepoRoot\tools\check_stl_bbox.py" $stl
if ($LASTEXITCODE -ne 0) { throw "mesh check failed (disconnected shells?)" }

& "$RepoRoot\tools\slice\prepare.ps1" -Parts $stl -Output "out\$Name.3mf" -Template $Template
