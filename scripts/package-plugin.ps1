param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifestPath = Join-Path $projectRoot 'manifest.json'
$distDir = Join-Path $projectRoot 'dist'
$releaseDir = Join-Path $projectRoot 'release'
$stagingRoot = Join-Path $releaseDir '.staging'

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "manifest.json not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Encoding UTF8 -Raw | ConvertFrom-Json
$pluginId = [string]$manifest.id
$version = [string]$manifest.version

if ([string]::IsNullOrWhiteSpace($pluginId) -or [string]::IsNullOrWhiteSpace($version)) {
    throw 'manifest.json must contain id and version'
}

if (-not $SkipBuild) {
    Push-Location $projectRoot
    try {
        & npm.cmd run build
        if ($LASTEXITCODE -ne 0) {
            throw "npm run build failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

$requiredFiles = @('main.js', 'manifest.json', 'style.css')
foreach ($fileName in $requiredFiles) {
    $sourcePath = Join-Path $distDir $fileName
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Required build artifact not found: $sourcePath"
    }
}

New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

$releaseFullPath = [System.IO.Path]::GetFullPath($releaseDir)
$stagingFullPath = [System.IO.Path]::GetFullPath($stagingRoot)
$releasePrefix = $releaseFullPath.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $stagingFullPath.StartsWith($releasePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe staging path: $stagingFullPath"
}

if (Test-Path -LiteralPath $stagingFullPath) {
    Remove-Item -LiteralPath $stagingFullPath -Recurse -Force
}

$pluginStagingDir = Join-Path $stagingFullPath $pluginId
New-Item -ItemType Directory -Path $pluginStagingDir -Force | Out-Null

foreach ($fileName in $requiredFiles) {
    Copy-Item -LiteralPath (Join-Path $distDir $fileName) -Destination $pluginStagingDir
}

$themesDir = Join-Path $distDir 'themes'
if (Test-Path -LiteralPath $themesDir) {
    Copy-Item -LiteralPath $themesDir -Destination $pluginStagingDir -Recurse
}

Copy-Item -LiteralPath (Join-Path $projectRoot 'INSTALL.md') -Destination $pluginStagingDir
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $pluginStagingDir

$zipPath = Join-Path $releaseDir "$pluginId-$version.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -LiteralPath $pluginStagingDir -DestinationPath $zipPath -CompressionLevel Optimal
Remove-Item -LiteralPath $stagingFullPath -Recurse -Force

$zipInfo = Get-Item -LiteralPath $zipPath
Write-Output "Created install package: $($zipInfo.FullName)"
Write-Output "Size: $($zipInfo.Length) bytes"
