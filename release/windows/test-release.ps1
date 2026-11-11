# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

param([string]$Package = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../cuda-oxide/crates/cargo-oxide/src/windows_release.ps1')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('cuda-release-test-' + [guid]::NewGuid().ToString('N'))
$testKey = 'HKCU:\Software\CudaRustWindowsTest-' + [guid]::NewGuid().ToString('N')
$script:StateKey = $testKey
New-Item -ItemType Directory -Path $testRoot | Out-Null
$script:pathCalls = @()
$script:testUserPath = ''
# Registration tests use a private registry key and never change the user's PATH.
function Get-UserPath { return $script:testUserPath }
function Set-UserPath([string]$Directory, [bool]$Include) {
    $script:pathCalls += [pscustomobject]@{ Directory=$Directory; Include=$Include }
}
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Fails([scriptblock]$Operation, [string]$Message) {
    $failed = $false
    try { $null = & $Operation } catch { $failed = $true }
    Assert $failed $Message
}
function New-TestZip([string[]]$Names, [string]$Path) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($Path, 'Create')
    try {
        foreach ($name in $Names) {
            $entry = $zip.CreateEntry($name)
            $writer = [IO.StreamWriter]::new($entry.Open())
            try { $writer.Write('fixture') } finally { $writer.Dispose() }
        }
    } finally { $zip.Dispose() }
}
function Set-TestZipDeclaredSize([string]$Path, [uint32]$Size) {
    # Change only the central directory size. The decompressed data still has
    # its original length, which .NET Framework does not enforce for us.
    $bytes = [IO.File]::ReadAllBytes($Path)
    for ($i = 0; $i -lt $bytes.Length - 28; $i++) {
        if ($bytes[$i] -eq 0x50 -and $bytes[$i + 1] -eq 0x4b -and $bytes[$i + 2] -eq 0x01 -and $bytes[$i + 3] -eq 0x02) {
            [BitConverter]::GetBytes($Size).CopyTo($bytes, $i + 24)
            [IO.File]::WriteAllBytes($Path, $bytes)
            return
        }
    }
    throw 'Fixture has no ZIP central directory.'
}
try {
    Assert-Fails { Assert-Version '../0.4.0' } 'Traversal was accepted as a version.'
    Assert-Fails { Assert-Version '0.4.0/next' } 'A URL path was accepted as a version.'
    $extract = Join-Path $testRoot 'extract'
    New-Item -ItemType Directory -Path $extract | Out-Null
    $zip = Join-Path $testRoot 'traversal.zip'
    New-TestZip @('../escape.dll') $zip
    Assert-Fails { Expand-Release $zip $extract } 'Archive traversal was accepted.'
    Assert (-not (Test-Path (Join-Path $testRoot 'escape.dll'))) 'An archive escaped its directory.'
    $zip = Join-Path $testRoot 'duplicate.zip'
    New-TestZip @('backend.dll', 'BACKEND.dll') $zip
    Assert-Fails { Expand-Release $zip $extract } 'Case-insensitive archive duplicates were accepted.'
    $zip = Join-Path $testRoot 'size-mismatch.zip'
    New-TestZip @('payload.dll') $zip
    Set-TestZipDeclaredSize $zip 1
    $mismatchExtract = Join-Path $testRoot 'size-mismatch-extract'
    New-Item -ItemType Directory -Path $mismatchExtract | Out-Null
    Assert-Fails { Expand-Release $zip $mismatchExtract } 'Extraction trusted a false uncompressed size.'
    $Action = 'Backend'; $Version = '0.4.0'; $Destination = Join-Path $testRoot 'rejected-release'; $Archive = $zip
    Assert-Fails { Invoke-WindowsRelease } 'An archive with a false uncompressed size was accepted.'
    Assert (-not (Test-Path -LiteralPath $Destination)) 'A rejected archive became visible as an installed release.'
    Assert (@(Get-ChildItem -LiteralPath $testRoot -Directory -Filter '.download-*').Count -eq 0) 'A rejected archive left a staging directory.'
    $Archive = ''

    $input = [IO.MemoryStream]::new((New-Object byte[] 1025))
    $output = [IO.MemoryStream]::new()
    try {
        Assert-Fails { Copy-ReleaseStream $input $output 1024 } 'An unknown-length stream exceeded its byte limit.'
        Assert ($output.Length -le 1024) 'Excess stream bytes reached the destination.'
        $input.Position = 0; $output.SetLength(0)
        Assert-Fails { Copy-ReleaseStream $input $output 2048 2048 } 'A truncated stream was accepted.'
        $input.Position = 0; $output.SetLength(0)
        Assert ((Copy-ReleaseStream $input $output 1025 1025) -eq 1025) 'An exact-limit stream was rejected.'
    } finally { $input.Dispose(); $output.Dispose() }
    $insecureDownload = Join-Path $testRoot 'insecure-download'
    Assert-Fails { Get-ReleaseFile 'http://localhost/release.zip' $insecureDownload } 'An insecure download URL was accepted.'
    Assert (-not (Test-Path -LiteralPath $insecureDownload)) 'An insecure download created a file.'
    $unsigned = Join-Path $testRoot 'unsigned'
    New-Item -ItemType Directory -Path $unsigned | Out-Null
    '# unsigned fixture' | Set-Content (Join-Path $unsigned 'release-manifest.ps1')
    Assert-Fails { Read-ReleaseManifest $unsigned } 'An unsigned manifest was trusted.'

    $Action = 'Register'; $Version = '0.4.0'; $Destination = Join-Path $testRoot 'install'; $AddPath = $true
    Invoke-WindowsRelease
    $state = Get-ItemProperty -LiteralPath $testKey
    Assert ($state.PathAdded -eq 1 -and $state.PreviousVersion -eq '') 'First-install ownership is wrong.'
    $Version = '0.4.1'; Invoke-WindowsRelease
    $state = Get-ItemProperty -LiteralPath $testKey
    Assert ($state.PreviousVersion -eq '0.4.0') 'An upgrade did not record the prior version.'
    Invoke-WindowsRelease
    Assert ((Get-ItemProperty -LiteralPath $testKey).PreviousVersion -eq '0.4.0') 'Repair erased the prior version.'
    $Action = 'Unregister'; $Destination = Join-Path $testRoot 'other'; Invoke-WindowsRelease
    Assert (Test-Path -LiteralPath $testKey) 'A different installation removed the registered state.'
    $Destination = Join-Path $testRoot 'install'; Invoke-WindowsRelease
    Assert (-not (Test-Path -LiteralPath $testKey)) 'Uninstall retained its registration.'
    Assert ($script:pathCalls[-1].Include -eq $false) 'Uninstall did not remove its PATH entry.'

    # An equivalent preexisting entry remains user-owned, including its spelling
    # and position. Install, repair and uninstall must not rewrite that PATH.
    foreach ($entry in @($Destination, ($Destination.ToUpperInvariant() + '\'))) {
        $script:testUserPath = "C:\Before;$entry;C:\After"
        $callsBefore = $script:pathCalls.Count
        $Action = 'Register'; Invoke-WindowsRelease
        Assert ((Get-ItemProperty -LiteralPath $testKey).PathAdded -eq 0) 'A preexisting PATH entry became installer-owned.'
        Invoke-WindowsRelease
        Assert ((Get-ItemProperty -LiteralPath $testKey).PathAdded -eq 0) 'Repair took ownership of a preexisting PATH entry.'
        $Action = 'Unregister'; Invoke-WindowsRelease
        Assert ($script:pathCalls.Count -eq $callsBefore) 'A preexisting PATH entry was rewritten or removed.'
    }

    if ($Package) {
        $manifest = Read-ReleaseManifest $Package
        $null = Assert-Release $Package $manifest.version $manifest.runtime_revision $manifest.rustc_fingerprint
        Assert-Fails { Assert-Release $Package $manifest.version ('0' * 40) $manifest.rustc_fingerprint } 'Wrong runtime revision was accepted.'
        Assert-Fails { Assert-Release $Package $manifest.version $manifest.runtime_revision 'different rustc' } 'Wrong rustc was accepted.'
        $tampered = Join-Path $testRoot 'tampered'
        Copy-Item -LiteralPath $Package -Destination $tampered -Recurse
        Add-Content -LiteralPath (Join-Path $tampered 'README.md') -Value 'tampered'
        Assert-Fails { Assert-Release $tampered $manifest.version '' '' } 'A modified payload was accepted.'
    }
    Write-Output 'PASS: release trust, archive containment, registration ownership, upgrade and repair.'
} finally {
    if (Test-Path -LiteralPath $testKey) { Remove-Item -LiteralPath $testKey }
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $parent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolved.StartsWith($parent, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved) -match '^cuda-release-test-[0-9a-f]{32}$') {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
