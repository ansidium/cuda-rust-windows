# Windows Setup

`cuda-oxide` supports `x86_64-pc-windows-msvc` on Windows 10 22H2 and Windows 11.
For Linux, see [Installation](installation.md).

## Requirements

- NVIDIA GPU and a driver compatible with the installed CUDA Toolkit.
- [CUDA Toolkit 13.0+](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/).
- Visual Studio 2022 or newer with MSVC x64 Build Tools and a Windows SDK.
- Rust 1.99.1 with `rust-src`, `rustc-dev`, `rust-analyzer`, `rustfmt`,
  `clippy`, and `llvm-tools`.
- LLVM/Clang with `libclang.dll`.

Install the pinned Rust toolchain and components:

```powershell
rustup toolchain install 1.99.1
rustup component add rust-src rustc-dev rust-analyzer rustfmt clippy llvm-tools --toolchain 1.99.1
```

## Use the release archive

Download the ZIP and SHA-256 checksum from
[Releases](https://github.com/ansidium/cuda-rust-windows/releases/latest).
Extract the ZIP and keep `cargo-oxide.exe` and `rustc_codegen_cuda.dll` together.

```powershell
.\smoketest.ps1
.\cargo-oxide.exe new my-kernel
cd my-kernel
..\cargo-oxide.exe doctor
..\cargo-oxide.exe run
```

The CLI finds the adjacent backend DLL automatically.

## CUDA environment

Use the CUDA version installed on your machine:

```powershell
$env:CUDA_PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.4"
$env:CUDA_TOOLKIT_PATH = $env:CUDA_PATH
$env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"
$env:PATH = "$env:CUDA_PATH\bin\x64;$env:CUDA_PATH\bin;$env:LIBCLANG_PATH;$env:PATH"
```

## Build from source

Open a Developer PowerShell for MSVC. Building the backend also requires
`libffi:x64-windows` from vcpkg; set `VCPKG_ROOT` to your vcpkg checkout:

```powershell
$env:VCPKG_ROOT = "C:\vcpkg"
& "$env:VCPKG_ROOT\vcpkg.exe" install libffi:x64-windows
cd cuda-oxide
cargo install --locked --path crates/cargo-oxide
cargo oxide setup
cargo oxide doctor
cargo oxide run vecadd
```

For a build-only check without a GPU, run `scripts/smoketest.ps1 -BuildOnly`
from `cuda-oxide/`:

```powershell
.\scripts\smoketest.ps1 -BuildOnly
```

Maintainers can package the CLI and backend from the repository root with:

```powershell
.\cuda-oxide\scripts\package-windows-release.ps1
```

## Compute Sanitizer on Windows (WDDM)

When running `cargo oxide sanitize` on a Windows GPU using the WDDM driver model, enable the WDDM debugger interface once from an elevated Administrator prompt:

```powershell
& "$env:CUDA_PATH\compute-sanitizer\EnableDebuggerInterface.bat"
```
