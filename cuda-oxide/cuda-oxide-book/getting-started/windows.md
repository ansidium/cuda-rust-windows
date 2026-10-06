# Windows Setup

The Windows fork targets `x86_64-pc-windows-msvc` and tracks NVIDIA/cuda-rust.

## Support Matrix

| Platform | Target |
|----------|--------|
| Windows 10 22H2 / Windows 11 | `x86_64-pc-windows-msvc` |

For Linux, see [Installation](installation.md).

## Requirements

- Windows 10 22H2 or Windows 11.
- NVIDIA GPU and a driver compatible with the installed CUDA Toolkit.
- CUDA Toolkit 13.0+ and a CUDA 13.x-compatible driver (R580+), as required by
  the shared host runtime.
- Visual Studio 2022 Build Tools with the MSVC x64 toolchain and Windows SDK.
- Latest stable Rust selected by `rust-toolchain.toml`.
- Rust components: `rust-src`, `rustc-dev`, `rust-analyzer`, `rustfmt`,
  `clippy`, and `llvm-tools`.
- Clang and libclang for `bindgen`.

## Release Archive

Maintainers can build the Windows release archive with:

```powershell
.\cuda-oxide\scripts\package-windows-release.ps1
```

The script creates
`cuda-oxide\target\windows-release\cuda-oxide-v<version>-x86_64-pc-windows-msvc.zip`
with `cargo-oxide.exe`, `rustc_codegen_cuda.dll`, `README.md`, and
`smoketest.ps1`. The executable and backend DLL are packaged side-by-side so
the CLI can discover the backend without `CUDA_OXIDE_BACKEND`. A matching
`.zip.sha256` file is written next to the archive for download verification.

## Rust Toolchain

The repository selects the stable toolchain in `rust-toolchain.toml`. Rustup
will install it automatically when you run Cargo from the repository root, but the
manual commands are:

```powershell
rustup update stable
rustup component add rust-src rustc-dev rust-analyzer rustfmt clippy llvm-tools --toolchain stable
rustup target add x86_64-pc-windows-msvc --toolchain stable
```

## Visual Studio and Clang

Install Visual Studio 2022 Build Tools with "Desktop development with C++".
Open a Developer PowerShell, or ensure the MSVC tools are on `PATH` before
building.

Install LLVM/Clang so `clang.exe` and `libclang.dll` are available. A common
installation path is `C:\Program Files\LLVM\bin`.

## CUDA Environment

Adjust the CUDA version directory to match your installation:

```powershell
$env:CUDA_PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.0"
$env:CUDA_TOOLKIT_PATH = $env:CUDA_PATH
$env:CUDA_HOME = $env:CUDA_PATH
$env:PATH = "$env:CUDA_PATH\bin\x64;$env:CUDA_PATH\bin;C:\Program Files\LLVM\bin;$env:PATH"
$env:LIB = "$env:CUDA_PATH\lib\x64;$env:LIB"
$env:INCLUDE = "$env:CUDA_PATH\include;$env:INCLUDE"
$env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"
```

Use quotes around paths under `C:\Program Files\...`; Windows smoke and path
tests should keep this space-containing layout covered.

## Validation Commands

Run these from the repository's `cuda-oxide` directory:

```powershell
cd cuda-oxide
rustc -Vv
cargo -V
nvcc --version
clang --version

cargo build --locked -p cargo-oxide
.\target\debug\cargo-oxide.exe doctor
.\target\debug\cargo-oxide.exe build vecadd
.\target\debug\cargo-oxide.exe run vecadd
```

`cargo oxide build vecadd` is the build-only check. `cargo oxide run vecadd`
requires a usable NVIDIA GPU and driver. If the machine has no GPU, run the
PowerShell smoke script in build-only mode:

```powershell
.\scripts\smoketest.ps1 -BuildOnly
```

On a GPU machine, run:

```powershell
.\scripts\smoketest.ps1
```

The smoke script prints `SMOKE PASS`, `SMOKE FAIL`, and `SMOKE SKIP` verdicts
for each step.
