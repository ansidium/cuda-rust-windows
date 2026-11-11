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

## Install the Windows release

Download `cuda-oxide-v0.4.0-windows-x64-setup.exe` from
[Releases](https://github.com/ansidium/cuda-rust-windows/releases/latest).
The signed onni installer supports 24 interface languages, installs for the current
user, and offers to add the tools to PATH. CUDA, Rust and Visual Studio are separate
prerequisites; the installer lists them before installation.

Open **CUDA Rust developer shell** from the Start menu. It locates the MSVC tools
and a standard LLVM installation, and selects the pinned Rust toolchain for that
shell. Then run:

```powershell
cargo oxide new my-kernel
cd my-kernel
cargo oxide doctor
cargo oxide run
```

Update the installed distribution with `cargo oxide windows update`. To select a
release, add `--version 0.4.0`; `--download-only` verifies and saves its installer
without opening it. `cargo oxide windows rollback` opens the installer for the
previously installed version, when one has been recorded. A first installation
has no previous installer version. These commands verify the publisher signature,
timestamp, product name and version before opening the wizard.

Remove the tools through Windows **Installed apps**. Uninstallation removes the
PATH entry only if this installation added it; project directories are kept.

## Use the portable archive

Download the ZIP and SHA-256 checksum from
[Releases](https://github.com/ansidium/cuda-rust-windows/releases/latest).
Extract the ZIP and keep `cargo-oxide.exe` and `rustc_codegen_cuda.dll` together.

```powershell
$oxide = Join-Path (Get-Location) "cargo-oxide.exe"
cd $HOME
& $oxide new my-kernel
cd my-kernel
& $oxide doctor
& $oxide run
```

The CLI checks the adjacent backend against the signed manifest, the project's
resolved runtime revision, and the complete Rust compiler fingerprint before
using it. Keep every file in the portable directory, including the manifest.
Store your projects outside that directory.

When a CLI installed from source needs the matching release backend, it can fetch
the signed package into its cache instead of compiling the backend. Other runtime
revisions continue to build from their own source. Set `CUDA_OXIDE_PREBUILT=0` to
bypass adjacent and downloaded packages and use source builds. Explicit
`CUDA_OXIDE_BACKEND` and project backend settings still take precedence. Set
`CARGO_NET_OFFLINE=true` to prevent the automatic release download when working
offline; an already cached release can still be verified and reused.

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
.\cuda-oxide\scripts\package-windows-release.ps1 -SignScript C:\Build\sign-payload.ps1
```

The maintainer's signing wrapper accepts file paths as separate arguments. The
package script signs executables and PowerShell helpers, hashes the payload, then
signs the manifest. Use `-SkipSign` only for unpublished test packages. Build the
installer from `release/windows/installer.oss` with onni 1.1.0 and an external
signing profile; see `release/windows/BUILD.md` in the repository.

## Compute Sanitizer on Windows (WDDM)

When running `cargo oxide sanitize` on a Windows GPU using the WDDM driver model, enable the WDDM debugger interface once from an elevated Administrator prompt:

```powershell
& "$env:CUDA_PATH\compute-sanitizer\EnableDebuggerInterface.bat"
```
