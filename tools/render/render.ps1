<#
.SYNOPSIS
    Render a .scad file to a mesh using the dockerized OpenSCAD renderer.
    Builds the renderer image on first use, then bind-mounts the repo and renders.

.EXAMPLE
    .\tools\render\render.ps1 gridfinity_paper_organizer.scad out\paper_organizer.stl

.EXAMPLE
    # Parametric override:
    .\tools\render\render.ps1 gridfinity_basic_cup.scad out\cup.stl -Define width=2,depth=3

.EXAMPLE
    # Raw OpenSCAD passthrough (e.g. binary STL):
    .\tools\render\render.ps1 src\box.scad out\box.stl -OpenscadArg '--export-format=binstl'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputScad,
    [Parameter(Mandatory)][string]$OutputMesh,
    [string[]]$Define,        # OpenSCAD -D overrides, e.g. -Define Width=84,Length=84
    [string[]]$OpenscadArg    # raw extra openscad args, e.g. -OpenscadArg '--backend=manifold'
)
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Image    = 'gfx-render'

# The container is Linux: pass repo-relative paths with forward slashes.
$InputScad  = $InputScad  -replace '\\', '/'
$OutputMesh = $OutputMesh -replace '\\', '/'

# Build the image once (subsequent runs reuse it; force a rebuild with: docker rmi gfx-render)
if (-not (docker images -q $Image)) {
    Write-Host "Building '$Image' renderer image (first run only)..." -ForegroundColor Cyan
    docker build -t $Image $PSScriptRoot
    if ($LASTEXITCODE -ne 0) { throw "docker build failed" }
}

# /work = repo root. All includes in this repo are repo-relative, so one mount suffices.

# Expand -Define entries into repeated "-D key=val" openscad args.
$DefineArgs = @()
foreach ($d in $Define) { $DefineArgs += '-D'; $DefineArgs += $d }

docker run --rm `
    -v "${RepoRoot}:/work" `
    $Image $InputScad $OutputMesh @DefineArgs @OpenscadArg
if ($LASTEXITCODE -ne 0) { throw "render failed (exit $LASTEXITCODE)" }

Write-Host "Wrote $RepoRoot\$OutputMesh" -ForegroundColor Green
