# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Launch with powershell.exe -NoExit -File start-shell.ps1.
# Environment changes are limited to this developer shell.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:PSModulePath = (Join-Path $PSHOME 'Modules') + ';' + $env:PSModulePath
$root = $PSScriptRoot
$env:PATH = "$root;$env:PATH"
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) {
        Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
        Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
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
