<#
.SYNOPSIS
    Render PNG snapshots of a .scad from standard named directions, so renders can be
    visually evaluated. Uses the same dockerized OpenSCAD image as render.ps1.

.EXAMPLE
    .\tools\render\snapshot.ps1 gridfinity_paper_organizer.scad out\paper_organizer

.EXAMPLE
    .\tools\render\snapshot.ps1 gridfinity_basic_cup.scad out\shots -Views iso,front,top,bottom -Define width=2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputScad,
    [Parameter(Mandatory)][string]$OutDir,
    [string]$Views = 'iso,front,right,top',   # comma-separated: iso,front,back,left,right,top,bottom
    [string[]]$Define,                        # OpenSCAD -D overrides, e.g. -Define Part=bottom
    [string]$ImgSize = '1000x750',
    [switch]$FullRender                        # full CGAL render (slower, exact) vs fast preview
)
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Image    = 'gfx-render'
$InputScad = $InputScad -replace '\\', '/'
$OutDir    = $OutDir    -replace '\\', '/'

if (-not (docker images -q $Image)) {
    Write-Host "Building '$Image' renderer image (first run only)..." -ForegroundColor Cyan
    docker build -t $Image $PSScriptRoot
    if ($LASTEXITCODE -ne 0) { throw "docker build failed" }
}

$DefineArgs = @(); foreach ($d in $Define) { $DefineArgs += '-D'; $DefineArgs += $d }
$EnvArgs = @('-e', "IMGSIZE=$ImgSize"); if ($FullRender) { $EnvArgs += @('-e', 'RENDER=1') }

docker run --rm --entrypoint snapshot `
    @EnvArgs `
    -v "${RepoRoot}:/work" `
    $Image $InputScad $OutDir $Views @DefineArgs
if ($LASTEXITCODE -ne 0) { throw "snapshot failed (exit $LASTEXITCODE)" }

Write-Host "Wrote snapshots to $RepoRoot\$OutDir" -ForegroundColor Green
