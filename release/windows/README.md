# CUDA Rust Windows

Windows x64 tools for compiling and running Rust GPU kernels with cuda-oxide.

## Install

Use the signed onni setup from the release page for a per-user installation,
optional PATH registration, a Start menu developer shell and uninstallation
through Windows Installed apps. The installer supports 24 interface languages.

The portable ZIP contains the same tools. Extract all files together and keep
your projects outside that directory. Add the directory to your shell's PATH,
or start a prepared shell with:

```powershell
powershell.exe -NoProfile -NoExit -ExecutionPolicy Bypass -File .\start-shell.ps1
```

## Requirements

- Windows 10 22H2 or Windows 11, x64.
- Rustup with Rust 1.99.1 and the `rustc-dev`, `rust-src`, and `llvm-tools` components.
- CUDA Toolkit 13.0+, including `nvcc`, `cuda.h`, `cuda.lib`,
  `nvvm64_*.dll`, `nvJitLink_*.dll`, and `libdevice.10.bc`.
- Visual Studio 2022 Build Tools with MSVC x64 and a Windows SDK.
- LLVM/Clang with libclang available on `PATH` or through `LIBCLANG_PATH`.

The installer contains the CLI and ready-built rustc backend. CUDA Toolkit,
Rust, MSVC and LLVM are installed separately. Source builds of the backend also
need libffi; using the matching ready-built backend avoids that build step.

## First kernel

From the CUDA Rust developer shell:

```powershell
cargo oxide new my-kernel
cd my-kernel
cargo oxide doctor
cargo oxide run
```

The CLI verifies the signed manifest, file hashes, runtime revision and Rust
compiler fingerprint before loading the packaged backend. Dependencies at other
revisions use a backend from their own source. Keep release-manifest.ps1 and all
other package files beside cargo-oxide.exe.

## Update or remove

`cargo oxide windows update` downloads and verifies the latest installer.
Use `--version 0.4.0` to select a release or `--download-only` to save it without
opening the wizard. `cargo oxide windows rollback` opens the previous installed
version's installer, if recorded. It is unavailable on the first installation.

Uninstall a managed installation through Windows Installed apps. The portable
ZIP has no registration or uninstaller.

[Full setup guide](https://github.com/ansidium/cuda-rust-windows/blob/main/cuda-oxide/cuda-oxide-book/getting-started/windows.md)
· [Source and releases](https://github.com/ansidium/cuda-rust-windows)
