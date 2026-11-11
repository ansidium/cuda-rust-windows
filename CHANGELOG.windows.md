# Windows Changelog

## [windows-v0.4.0](https://github.com/ansidium/cuda-rust-windows/releases/tag/windows-v0.4.0) - 2026-11-12

- Updated to cuda-oxide 0.4.0 and shared host crates 0.5.0, including the merged
  upstream Windows support.
- Added a signed onni installer with 24 languages, a developer shell, optional
  user PATH registration, repair and uninstallation.
- Added signed prebuilt backend delivery with exact runtime/compiler matching,
  bounded downloads and extraction, and an explicit source-only mode.
- Added `cargo oxide windows install`, `update` and `rollback` commands.
- Made `doctor` report the selected release backend and reject a missing release
  manifest without misleading warnings about an unused source cache.
- Added Windows release regressions and fixed the smoke guard's Windows null
  output path. Included dependency notices in the distribution.

## [windows-v0.3.0](https://github.com/ansidium/cuda-rust-windows/releases/tag/windows-v0.3.0) - 2026-11-02

- Updated to CUDA-Oxide 0.3.0 and the shared host runtime 0.5.0.
- Pinned Rust 1.99.1 across the host, SIMT, and Tile workspaces. CUDA Toolkit
  13.0 or newer is required.
- Preserved MSVC ABI conversions, COFF embedding, and Windows CUDA DLL discovery.
- Adopted upstream's backend cache publication fix and retained the fork's
  source pins for standalone projects.
- Fixed Windows archive extraction, PTX output path validation, and the
  CuTe comparison dispatch tests.
- Refreshed standalone example lockfiles and updated CI for the shared runtime.

## windows-v0.2.1 - 2026-06-14

- Updated to upstream CUDA-Oxide v0.2.1 at
  `cb318ad4e4e37f5e1913ed0a13478af990e857f7`.
- Added upstream monitoring, scheduled syncs, and hosted Windows MSVC checks.
- Added Windows CUDA discovery, COFF artifacts, and PowerShell smoke scripts.
- Used release-profile backend builds to avoid MSVC debug linker object limits.

Windows GPU checks require local NVIDIA hardware. GitHub-hosted Windows
runners check compilation and loading; `cuda-gdb` remains Linux-only.
