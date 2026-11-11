# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

param(
    [ValidateSet('Backend', 'Install', 'Update', 'Rollback', 'Register', 'Unregister')]
    [string]$Action = 'Install',
    [string]$Version = '',
    [string]$Destination = '',
    [string]$ExpectedRevision = '',
    [string]$ExpectedRustc = '',
    [string]$Archive = '',
    [switch]$AddPath,
    [switch]$DownloadOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# A PowerShell 7 parent can export its incompatible module directories to 5.1.
# Resolve the built-in Windows trust and registry commands from this interpreter.
$env:PSModulePath = Join-Path $PSHOME 'Modules'
$script:PublisherThumbprint = 'DAE6944E8E0D8F7A445351FC5E0D0BFFC31EA4C3'
$script:Repository = 'https://github.com/ansidium/cuda-rust-windows'
$script:StateKey = 'HKCU:\Software\CudaRustWindows'

function Assert-Version([string]$Value) {
    if ($Value -notmatch '^\d{1,5}\.\d{1,5}\.\d{1,5}$') { throw "Invalid release version: $Value" }
}

function Assert-Publisher([string]$Path) {
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne 'Valid' -or $null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Thumbprint -ne $script:PublisherThumbprint -or
        $null -eq $signature.TimeStamperCertificate) {
        throw "The publisher signature or trusted timestamp is invalid: $Path"
    }
}

function Get-DownloadTimeout([Diagnostics.Stopwatch]$Timer) {
    $remaining = 120000L - $Timer.ElapsedMilliseconds
    if ($remaining -le 0) { throw 'Release download timed out.' }
    return [int]$remaining
}

function Copy-ReleaseStream([IO.Stream]$Source, [IO.Stream]$Target, [long]$Limit, [long]$ExpectedLength = -1, [Diagnostics.Stopwatch]$Timer = $null) {
    $buffer = New-Object byte[] 81920
    $total = 0L
    while ($true) {
        if ($null -ne $Timer) {
            $remaining = Get-DownloadTimeout $Timer
            if ($Source.CanTimeout) { $Source.ReadTimeout = $remaining }
        }
        $read = $Source.Read($buffer, 0, [int][Math]::Min($buffer.Length, $Limit - $total + 1))
        if ($read -eq 0) { break }
        $total += $read
        if ($total -gt $Limit) { throw 'Release stream exceeds its size limit.' }
        if ($ExpectedLength -ge 0 -and $total -gt $ExpectedLength) { throw 'Release stream exceeds its declared size.' }
        $Target.Write($buffer, 0, $read)
    }
    if ($ExpectedLength -ge 0 -and $total -ne $ExpectedLength) { throw 'Release stream does not match its declared size.' }
    return $total
}

function Get-ReleaseFile([string]$Url, [string]$Path) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = [uri]$Url
    $timer = [Diagnostics.Stopwatch]::StartNew()
    for ($redirects = 0; $redirects -le 5; $redirects++) {
        if (-not $uri.IsAbsoluteUri -or $uri.Scheme -ne 'https') { throw 'Release downloads require HTTPS.' }
        $request = [Net.WebRequest]::CreateHttp($uri)
        $request.AllowAutoRedirect = $false
        $request.UserAgent = 'cuda-rust-windows'
        $request.Timeout = Get-DownloadTimeout $timer
        $request.ReadWriteTimeout = $request.Timeout
        $response = $null
        try {
            $response = $request.GetResponse()
            if ([int]$response.StatusCode -in @(301, 302, 303, 307, 308)) {
                if ($redirects -eq 5 -or -not $response.Headers['Location']) { throw 'Invalid or excessive release download redirects.' }
                $uri = [uri]::new($uri, $response.Headers['Location'])
                continue
            }
            if ([int]$response.StatusCode -ne 200) { throw 'Unexpected release download response.' }
            if ($response.ContentLength -gt 160MB) { throw 'Release download exceeds 160 MiB.' }
            $source = $response.GetResponseStream()
            $target = $null
            try {
                $target = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                $null = Copy-ReleaseStream $source $target 160MB $response.ContentLength $timer
            } catch {
                if ($null -ne $target) {
                    $target.Dispose()
                    [IO.File]::Delete($Path)
                }
                throw
            } finally {
                if ($null -ne $target) { $target.Dispose() }
                $source.Dispose()
            }
            return
        } finally {
            if ($null -ne $response) { $response.Dispose() }
            $request.Abort()
        }
    }
}

function Read-ReleaseManifest([string]$Directory) {
    $path = Join-Path $Directory 'release-manifest.ps1'
    Assert-Publisher $path
    $text = [IO.File]::ReadAllText($path)
    $match = [regex]::Match($text, '(?s)\r?\nCUDA-OXIDE-RELEASE\r?\n(.*?)\r?\nCUDA-OXIDE-END\r?\n')
    if (-not $match.Success) { throw 'The signed release manifest has an invalid format.' }
    $manifest = $match.Groups[1].Value | ConvertFrom-Json
    if ($manifest.schema_version -ne 1 -or $manifest.target -ne 'x86_64-pc-windows-msvc') {
        throw 'The release manifest is not a supported Windows x64 package.'
    }
    Assert-Version $manifest.version
    return $manifest
}

function Assert-Release([string]$Directory, [string]$ReleaseVersion, [string]$Revision, [string]$Rustc) {
    $manifest = Read-ReleaseManifest $Directory
    if ($manifest.version -ne $ReleaseVersion) { throw 'The archive belongs to another release.' }
    if ($Revision -and $manifest.runtime_revision -ne $Revision) { throw 'The backend does not match the project dependency revision.' }
    if ($Rustc -and $manifest.rustc_fingerprint.Replace("`r`n", "`n").Trim() -ne $Rustc.Replace("`r`n", "`n").Trim()) { throw 'The backend requires a different Rust compiler. Use the toolchain in the Windows setup guide.' }
    $names = @('release-manifest.ps1')
    foreach ($file in $manifest.files) {
        if ($file.name -notmatch '^[a-zA-Z0-9_.-]+$' -or $file.sha256 -notmatch '^[0-9a-f]{64}$' -or $names -contains $file.name) {
            throw 'The release manifest contains an invalid or duplicate file.'
        }
        $names += $file.name
        $path = Join-Path $Directory $file.name
        if (-not [IO.File]::Exists($path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) {
            throw "Release checksum mismatch: $($file.name)"
        }
        if ($file.name -match '\.(exe|dll|ps1)$') { Assert-Publisher $path }
    }
    foreach ($required in @('cargo-oxide.exe', 'rustc_codegen_cuda.dll', 'manage-windows.ps1')) {
        if ($names -notcontains $required) { throw "Required release file is missing: $required" }
    }
    foreach ($item in Get-ChildItem -LiteralPath $Directory -Force) {
        if ($item.PSIsContainer -or $names -notcontains $item.Name -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Unexpected release entry: $($item.Name)"
        }
    }
    return $manifest
}

function Expand-Release([string]$Zip, [string]$Directory) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archiveFile = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $total = 0L
        $names = @{}
        if ($archiveFile.Entries.Count -gt 24) { throw 'Too many files in release archive.' }
        foreach ($entry in $archiveFile.Entries) {
            if ($entry.FullName -notmatch '^[a-zA-Z0-9_.-]+$' -or $names.ContainsKey($entry.FullName)) { throw 'Unsafe or duplicate archive entry.' }
            $names[$entry.FullName] = $true
            $remaining = 320MB - $total
            if ($entry.Length -gt $remaining) { throw 'Expanded release exceeds 320 MiB.' }
            $source = $entry.Open()
            $target = $null
            try {
                $target = [IO.File]::Open((Join-Path $Directory $entry.FullName), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                $total += Copy-ReleaseStream $source $target $remaining $entry.Length
            } finally {
                if ($null -ne $target) { $target.Dispose() }
                $source.Dispose()
            }
        }
    } finally { $archiveFile.Dispose() }
}

function Get-UserPath {
    return [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Set-UserPath([string]$Directory, [bool]$Include) {
    $current = Get-UserPath
    $parts = @($current -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ine $Directory.TrimEnd('\') })
    if ($Include) { $parts = @($Directory) + $parts }
    [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
}

function Invoke-WindowsRelease {
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows x64 is required.' }
    if ($Action -eq 'Register' -or $Action -eq 'Unregister') {
        $directory = [IO.Path]::GetFullPath($Destination).TrimEnd('\')
        $old = Get-ItemProperty -LiteralPath $script:StateKey -ErrorAction SilentlyContinue
        if ($Action -eq 'Unregister') {
            if ($old -and $old.InstallDir -eq $directory) {
                if ($old.PathAdded) { Set-UserPath $directory $false }
                Remove-Item -LiteralPath $script:StateKey
            }
            return
        }
        Assert-Version $Version
        $previous = ''
        $pathWasAdded = $false
        if ($old) {
            $previous = $old.PreviousVersion
            if ($old.Version -ne $Version) { $previous = $old.Version }
            $pathWasAdded = [bool]$old.PathAdded
            if ($old.InstallDir -ne $directory) {
                if ($pathWasAdded) { Set-UserPath $old.InstallDir $false }
                $pathWasAdded = $false
            }
        }
        $alreadyPresent = @((Get-UserPath) -split ';' | ForEach-Object { $_.TrimEnd('\') }) -icontains $directory
        if ($AddPath -and -not $alreadyPresent) { Set-UserPath $directory $true }
        elseif (-not $AddPath -and $pathWasAdded) { Set-UserPath $directory $false }
        New-Item -Path $script:StateKey -Force | Out-Null
        foreach ($pair in @{Version=$Version; PreviousVersion=$previous; InstallDir=$directory}.GetEnumerator()) {
            New-ItemProperty -LiteralPath $script:StateKey -Name $pair.Key -Value $pair.Value -PropertyType String -Force | Out-Null
        }
        New-ItemProperty -LiteralPath $script:StateKey -Name PathAdded -Value ([int]($AddPath -and ($pathWasAdded -or -not $alreadyPresent))) -PropertyType DWord -Force | Out-Null
        return
    }

    if ($Action -eq 'Backend') {
        Assert-Version $Version
        $destinationPath = [IO.Path]::GetFullPath($Destination)
        if ([IO.Directory]::Exists($destinationPath)) {
            $null = Assert-Release $destinationPath $Version $ExpectedRevision $ExpectedRustc
            Write-Output (Join-Path $destinationPath 'rustc_codegen_cuda.dll')
            return
        }
        $parent = [IO.Path]::GetDirectoryName($destinationPath)
        [IO.Directory]::CreateDirectory($parent) | Out-Null
        $stage = Join-Path $parent ('.download-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($stage) | Out-Null
        try {
            $zip = Join-Path $stage 'release.zip'
            if ($Archive) { Copy-Item -LiteralPath $Archive -Destination $zip }
            else {
                $name = "cuda-oxide-v$Version-x86_64-pc-windows-msvc.zip"
                $url = "$script:Repository/releases/download/windows-v$Version/$name"
                Get-ReleaseFile $url $zip
                Get-ReleaseFile "$url.sha256" "$zip.sha256"
                $expected = ([IO.File]::ReadAllText("$zip.sha256") -split '\s+')[0]
                if ($expected -notmatch '^[0-9a-f]{64}$' -or (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expected) { throw 'Archive checksum mismatch.' }
            }
            $payload = Join-Path $stage 'payload'
            [IO.Directory]::CreateDirectory($payload) | Out-Null
            Expand-Release $zip $payload
            $null = Assert-Release $payload $Version $ExpectedRevision $ExpectedRustc
            # The fully verified directory becomes visible in one rename.
            [IO.Directory]::Move($payload, $destinationPath)
            Write-Output (Join-Path $destinationPath 'rustc_codegen_cuda.dll')
        } finally {
            $resolvedStage = [IO.Path]::GetFullPath($stage)
            if ($resolvedStage.StartsWith($parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolvedStage) -match '^\.download-[0-9a-f]{32}$') {
                Remove-Item -LiteralPath $resolvedStage -Recurse -Force
            }
        }
        return
    }

    $installed = Get-ItemProperty -LiteralPath $script:StateKey -ErrorAction SilentlyContinue
    if ($Action -eq 'Rollback') {
        if (-not $installed -or -not $installed.PreviousVersion) { throw 'No previous installer version is recorded.' }
        $Version = $installed.PreviousVersion
    } elseif ($Action -eq 'Update' -and -not $Version) {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/ansidium/cuda-rust-windows/releases/latest' -Headers @{'User-Agent'='cuda-rust-windows'} -TimeoutSec 60
        if ($release.tag_name -notmatch '^windows-v(\d+\.\d+\.\d+)$') { throw 'The latest release is not a Windows package.' }
        $Version = $Matches[1]
    }
    Assert-Version $Version
    $downloadRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'cuda-oxide\downloads'
    [IO.Directory]::CreateDirectory($downloadRoot) | Out-Null
    $name = "cuda-oxide-v$Version-windows-x64-setup.exe"
    $setup = Join-Path $downloadRoot $name
    $temporary = "$setup.$([guid]::NewGuid().ToString('N')).exe"
    try {
        Get-ReleaseFile "$script:Repository/releases/download/windows-v$Version/$name" $temporary
        Assert-Publisher $temporary
        $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($temporary)
        if ($info.ProductName -ne 'CUDA Rust Windows' -or $info.ProductVersion -notin @($Version, "$Version.0")) { throw 'The signed installer belongs to another product or version.' }
        Move-Item -LiteralPath $temporary -Destination $setup -Force
    } finally { if ([IO.File]::Exists($temporary)) { Remove-Item -LiteralPath $temporary } }
    if ($DownloadOnly) { Write-Output $setup; return }
    # The CLI exits before setup replaces it; the wizard owns the update.
    Start-Process -FilePath $setup | Out-Null
    Write-Output "Opened CUDA Rust Windows $Version setup."
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-WindowsRelease }
