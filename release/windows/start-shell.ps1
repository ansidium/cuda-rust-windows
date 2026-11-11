# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Launch with powershell.exe -NoExit -ExecutionPolicy Bypass -File start-shell.ps1.
# Environment changes are limited to this developer shell.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:PSModulePath = (Join-Path $PSHOME 'Modules') + ';' + $env:PSModulePath
$root = $PSScriptRoot
$env:PATH = "$root;$env:PATH"

function Test-MsvcX64Environment([string]$VsDirectory) {
    if ($env:VSCMD_ARG_HOST_ARCH -ne 'x64' -or $env:VSCMD_ARG_TGT_ARCH -ne 'x64' -or
        -not $env:VSINSTALLDIR -or -not $env:VCToolsInstallDir -or -not $env:LIB -or -not $env:INCLUDE) {
        return $false
    }
    try {
        if ([IO.Path]::GetFullPath($env:VSINSTALLDIR).TrimEnd('\') -ne [IO.Path]::GetFullPath($VsDirectory).TrimEnd('\')) {
            return $false
        }
        $tools = [IO.Path]::GetFullPath($env:VCToolsInstallDir)
        foreach ($name in @('cl.exe', 'link.exe')) {
            $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
            $expected = Join-Path $tools "bin\Hostx64\x64\$name"
            if (-not $command -or [IO.Path]::GetFullPath($command.Source) -ne $expected) { return $false }
        }
        $libraries = @($env:LIB -split ';' | Where-Object { $_ } | ForEach-Object {
            [IO.Path]::GetFullPath($_).TrimEnd('\')
        })
        return $libraries -contains (Join-Path $tools 'lib\x64')
    } catch { return $false }
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) {
        # Re-entering vcvars can overflow cmd's expanded command line and leave
        # a previous target active. Reuse only the verified x64 environment.
        if ($env:VSCMD_VER -or $env:__VSCMD_PREINIT_PATH) {
            if (-not (Test-MsvcX64Environment $vs)) {
                throw 'The inherited Visual Studio environment is not the expected x64 toolchain. Open CUDA Rust developer shell from a fresh PowerShell window.'
            }
        } else {
            Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
            Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
            if (-not (Test-MsvcX64Environment $vs)) {
                throw 'Visual Studio did not initialize the MSVC x64 tools and libraries. Check the C++ Build Tools and Windows SDK installation.'
            }
        }
    }
}
if (-not $env:LIBCLANG_PATH) {
    $clang = Join-Path $env:ProgramFiles 'LLVM\bin'
    if (Test-Path -LiteralPath (Join-Path $clang 'libclang.dll')) { $env:LIBCLANG_PATH = $clang }
}
if ($env:CUDA_PATH) { $env:PATH = (Join-Path $env:CUDA_PATH 'bin') + ';' + $env:PATH }
$env:RUSTUP_TOOLCHAIN = '1.99.1-x86_64-pc-windows-msvc'
$env:RUSTC_BOOTSTRAP = '1'
Set-Location ([Environment]::GetFolderPath('UserProfile'))
Write-Host "`nCUDA Rust Windows" -ForegroundColor Green
Write-Host 'Create a project:  cargo oxide new my-kernel'
Write-Host 'Then:              cd my-kernel; cargo oxide doctor; cargo oxide run'
Write-Host 'Update:            cargo oxide windows update'
Write-Host 'Setup guide:       https://github.com/ansidium/cuda-rust-windows/blob/main/cuda-oxide/cuda-oxide-book/getting-started/windows.md'
Write-Host ''
& (Join-Path $root 'cargo-oxide.exe') --version
