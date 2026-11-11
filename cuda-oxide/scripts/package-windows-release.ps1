# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

param(
    [string]$Version = "",
    [ValidateSet("release", "debug")]
    [string]$Profile = "release",
    [string]$TargetTriple = "x86_64-pc-windows-msvc",
    [string]$OutDir = "",
    [string]$SignScript = "",
    [Parameter(HelpMessage = 'Reuse existing artifacts only with -SkipSign. Signed packages always run Cargo builds to verify freshness.')]
    [switch]$SkipBuild,
    [Parameter(HelpMessage = 'Produce an unsigned, unpublished test package.')]
    [switch]$SkipSign
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$gitRoot = Split-Path -Parent $repoRoot

if ($TargetTriple -ne "x86_64-pc-windows-msvc") {
    throw "Only x86_64-pc-windows-msvc release archives are supported."
}

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $repoRoot "target\windows-release"
}

function Invoke-Checked {
    param(
        [string]$Name,
        [string]$Exe,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory = $repoRoot
    )

    Write-Host "RUN: $Name"
    Push-Location $WorkingDirectory
    try {
        & $Exe @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw "$Name failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
}

function Add-PathValue {
    param(
        [string]$Name,
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $existing = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($existing)) {
        [Environment]::SetEnvironmentVariable($Name, $Path, "Process")
    } else {
        [Environment]::SetEnvironmentVariable($Name, "$Path;$existing", "Process")
    }
}

function Get-CargoMetadata([string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        $json = cargo metadata --locked --no-deps --format-version 1
        if ($LASTEXITCODE -ne 0) { throw "Could not read Cargo metadata in $WorkingDirectory." }
        return ($json | ConvertFrom-Json)
    } finally {
        Pop-Location
    }
}

function Get-RustcFingerprint([string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        $fingerprint = (rustc -vV) -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Could not fingerprint rustc in $WorkingDirectory." }
        $hostMatch = [regex]::Match($fingerprint, '(?m)^host: ([^\r\n]+)$')
        if (-not $hostMatch.Success -or $hostMatch.Groups[1].Value -ne $TargetTriple) {
            throw "Packaging requires a rustc host of $TargetTriple. Select the pinned MSVC toolchain before building."
        }
        return $fingerprint
    } finally { Pop-Location }
}

function Build-CargoArtifact([string]$WorkingDirectory, [string]$Package, [string]$FileName, [string[]]$ProfileArguments) {
    Write-Host "RUN: cargo build -p $Package $Profile for $TargetTriple"
    Push-Location $WorkingDirectory
    try {
        $messages = @(cargo build --locked -p $Package --target $TargetTriple --message-format=json-render-diagnostics @ProfileArguments)
        if ($LASTEXITCODE -ne 0) { throw "Cargo build failed for $Package with exit code $LASTEXITCODE." }
        $paths = @($messages | ForEach-Object {
            $message = $_ | ConvertFrom-Json
            if ($message.reason -eq 'compiler-artifact' -and $message.target.name -eq $Package) {
                $message.filenames | Where-Object { [IO.Path]::GetFileName($_) -eq $FileName }
            }
        } | Select-Object -Unique)
        if ($paths.Count -ne 1) { throw "Cargo did not report one $FileName artifact for $Package." }
        return $paths[0]
    } finally { Pop-Location }
}

function Get-ExistingArtifact([string]$TargetDirectory, [string]$FileName) {
    foreach ($directory in @((Join-Path $TargetDirectory "$TargetTriple\$Profile"), (Join-Path $TargetDirectory $Profile))) {
        $candidate = Join-Path $directory $FileName
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw "Missing $FileName in Cargo target directory $TargetDirectory. Omit -SkipBuild to build it."
}

function Find-Libffi {
    $candidates = @()

    if ($env:LIBFFI_LIB_DIR) {
        $candidates += [pscustomobject]@{
            LibDir = $env:LIBFFI_LIB_DIR
            BinDir = $env:LIBFFI_BIN_DIR
        }
    }

    if ($env:LIB) {
        foreach ($libDir in ($env:LIB -split ";")) {
            if (-not [string]::IsNullOrWhiteSpace($libDir)) {
                $candidates += [pscustomobject]@{
                    LibDir = $libDir
                    BinDir = ""
                }
            }
        }
    }

    $roots = @()
    if ($env:VCPKG_ROOT) {
        $roots += $env:VCPKG_ROOT
    }

    $vcpkg = Get-Command vcpkg -ErrorAction SilentlyContinue
    if ($vcpkg) {
        $roots += Split-Path -Parent $vcpkg.Source
    }

    foreach ($root in $roots | Select-Object -Unique) {
        $installed = Join-Path $root "installed\x64-windows"
        $candidates += [pscustomobject]@{
            LibDir = Join-Path $installed "lib"
            BinDir = Join-Path $installed "bin"
        }
    }

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate.LibDir)) {
            $lib = Join-Path $candidate.LibDir "ffi.lib"
            if (Test-Path -LiteralPath $lib) {
                return $candidate
            }
        }
    }

    return $null
}

function Enable-LibffiForBuild {
    $libffi = Find-Libffi
    if (-not $libffi) {
        throw "ffi.lib was not found. Install libffi:x64-windows with vcpkg or set LIBFFI_LIB_DIR."
    }

    Add-PathValue "LIB" $libffi.LibDir
    if (-not [string]::IsNullOrWhiteSpace($libffi.BinDir)) {
        Add-PathValue "PATH" $libffi.BinDir
    }

    Write-Host "Using libffi import library: $(Join-Path $libffi.LibDir 'ffi.lib')"
}

$metadata = Get-CargoMetadata $repoRoot
$pkg = $metadata.packages | Where-Object { $_.name -eq 'cargo-oxide' } | Select-Object -First 1
if (-not $pkg) { throw 'cargo-oxide package was not found in Cargo metadata.' }
if ([string]::IsNullOrWhiteSpace($Version)) { $Version = $pkg.version }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version.' }
if ($Version -ne $pkg.version) { throw "Requested release $Version differs from cargo-oxide $($pkg.version). Update Cargo.toml and rebuild before packaging." }
if (-not $SkipSign -and -not (Test-Path -LiteralPath $SignScript -PathType Leaf)) {
    throw 'A signing wrapper is required. Use -SkipSign only for unpublished test builds.'
}
$backendRoot = Join-Path $repoRoot 'crates\rustc-codegen-cuda'
$backendMetadata = Get-CargoMetadata $backendRoot
$rustc = Get-RustcFingerprint $repoRoot
if ((Get-RustcFingerprint $backendRoot) -cne $rustc) { throw 'The CLI and backend workspaces select different Rust compilers.' }
if ($env:RUSTC) { throw 'Custom RUSTC is unsupported for release packaging. Clear RUSTC and use the pinned rustup toolchain.' }
$buildRequired = -not $SkipBuild -or -not $SkipSign
if ($SkipBuild -and -not $SkipSign) { Write-Host 'Ignoring -SkipBuild: signed packages always verify artifact freshness with Cargo.' }
if ($SkipBuild -and $SkipSign) { Write-Warning 'Unsigned test package: existing artifact freshness is not certified.' }

$profileArgs = @()
if ($Profile -eq "release") {
    $profileArgs += "--release"
}

if ($buildRequired) {
    Enable-LibffiForBuild
    $cargoOxide = Build-CargoArtifact $repoRoot 'cargo-oxide' 'cargo-oxide.exe' $profileArgs
    $backend = Build-CargoArtifact $backendRoot 'rustc_codegen_cuda' 'rustc_codegen_cuda.dll' $profileArgs
    if ((Get-RustcFingerprint $repoRoot) -cne $rustc -or (Get-RustcFingerprint $backendRoot) -cne $rustc) {
        throw 'The Rust compiler changed while building. Re-run packaging with a stable toolchain selection.'
    }
} else {
    $cargoOxide = Get-ExistingArtifact $metadata.target_directory 'cargo-oxide.exe'
    $backend = Get-ExistingArtifact $backendMetadata.target_directory 'rustc_codegen_cuda.dll'
}

if (-not (Test-Path -LiteralPath $cargoOxide)) {
    throw "Missing artifact: $cargoOxide"
}
if (-not (Test-Path -LiteralPath $backend)) {
    throw "Missing artifact: $backend"
}
$cliVersion = (& $cargoOxide --version) -join "`n"
if ($LASTEXITCODE -ne 0 -or $cliVersion.Trim() -ne "cargo-oxide $Version") {
    throw "The built CLI version does not match release $Version. Rebuild cargo-oxide before packaging."
}

$archiveBase = "cuda-oxide-v$Version-$TargetTriple"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$packageDir = Join-Path $OutDir $archiveBase

if (Test-Path -LiteralPath $packageDir) {
    $resolvedOut = (Resolve-Path -LiteralPath $OutDir).Path
    $resolvedPackage = (Resolve-Path -LiteralPath $packageDir).Path
    if (-not $resolvedPackage.StartsWith($resolvedOut.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove package directory outside OutDir: $resolvedPackage"
    }
    Remove-Item -LiteralPath $packageDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $packageDir | Out-Null

Copy-Item -LiteralPath $cargoOxide -Destination (Join-Path $packageDir "cargo-oxide.exe")
Copy-Item -LiteralPath $backend -Destination (Join-Path $packageDir "rustc_codegen_cuda.dll")
Copy-Item -LiteralPath (Join-Path $gitRoot "release\windows\README.md") -Destination (Join-Path $packageDir "README.md")
Copy-Item -LiteralPath (Join-Path $gitRoot "release\windows\smoketest.ps1") -Destination (Join-Path $packageDir "smoketest.ps1")
Copy-Item -LiteralPath (Join-Path $gitRoot "release\windows\start-shell.ps1") -Destination (Join-Path $packageDir "start-shell.ps1")
Copy-Item -LiteralPath (Join-Path $repoRoot "crates\cargo-oxide\src\windows_release.ps1") -Destination (Join-Path $packageDir "manage-windows.ps1")
Copy-Item -LiteralPath (Join-Path $gitRoot 'LICENSE') -Destination (Join-Path $packageDir 'LICENSE')
Copy-Item -LiteralPath (Join-Path $gitRoot 'release\windows\THIRD-PARTY-NOTICES.txt') -Destination (Join-Path $packageDir 'THIRD-PARTY-NOTICES.txt')
Copy-Item -LiteralPath (Join-Path $gitRoot 'release\windows\assets\chip-icon.ico') -Destination (Join-Path $packageDir 'cuda-rust.ico')

if (-not $SkipSign) {
    $signable = @(Get-ChildItem -LiteralPath $packageDir -File | Where-Object Extension -in '.exe', '.dll', '.ps1' | ForEach-Object FullName)
    Invoke-Checked "sign release payload" $SignScript $signable
}
$revisionSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'crates\cargo-oxide\src\backend.rs'))
$revision = [regex]::Match($revisionSource, 'PINNED_SOURCE_REVISION: &str = "([0-9a-f]{40})"').Groups[1].Value
if (-not $revision) { throw 'Missing pinned runtime revision.' }
$manifest = [ordered]@{
    schema_version = 1
    version = $Version
    target = $TargetTriple
    runtime_revision = $revision
    rustc_fingerprint = $rustc
    files = @(Get-ChildItem -LiteralPath $packageDir -File | Sort-Object Name | ForEach-Object {
        [ordered]@{ name = $_.Name; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
}
$manifestPath = Join-Path $packageDir 'release-manifest.ps1'
$json = $manifest | ConvertTo-Json -Depth 5
$manifestText = "# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.`n# SPDX-License-Identifier: Apache-2.0`n<#`nCUDA-OXIDE-RELEASE`n$json`nCUDA-OXIDE-END`n#>`n"
[IO.File]::WriteAllText($manifestPath, $manifestText, [Text.UTF8Encoding]::new($true))
if (-not $SkipSign) {
    Invoke-Checked "sign release manifest" $SignScript @($manifestPath)
    & (Join-Path $packageDir 'manage-windows.ps1') -Action Backend -Version $Version -Destination $packageDir -ExpectedRevision $revision -ExpectedRustc $rustc
}

$zipPath = Join-Path $OutDir "$archiveBase.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $packageDir "*") -DestinationPath $zipPath -Force
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
"$zipHash  $(Split-Path -Leaf $zipPath)" | Set-Content -LiteralPath "$zipPath.sha256" -Encoding ASCII

Write-Host "Package directory: $packageDir"
Write-Host "Release archive: $zipPath"
Write-Host "Release SHA256: $zipHash"
