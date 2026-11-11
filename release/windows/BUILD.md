# Building the Windows distribution

Build from a Developer PowerShell with the repository's pinned Rust toolchain,
CUDA Toolkit, LLVM/libclang and libffi available. Keep signing credentials and
machine-specific paths outside the repository.

```powershell
.\cuda-oxide\scripts\package-windows-release.ps1 -Version 0.4.0 -SignScript C:\Build\sign-payload.ps1
onni check release\windows\installer.oss
onni build release\windows\installer.oss --sign-profile release --out artifacts
```

Use onni 1.1.0. Supply its private signing profile through `ONNI_SIGNING_PROFILES`.
Use `--set payload=C:/Build/package` for a different staging directory and
`--set version=0.4.0` to select the release version. The installer, CLI, backend
and PowerShell helpers must have trusted timestamped signatures from the release
publisher. The signed manifest binds the package version, runtime revision, full
rustc fingerprint and SHA-256 of every payload file.

Signed packaging always checks Cargo build freshness, including when `-SkipBuild`
is present. That switch only skips builds for unsigned test packages. The requested
version must match Cargo metadata and the built CLI; the compiler host must match
the package target.

`build-icon.ps1` creates nine ICO sizes (16–256 pixels) from the geometry documented
in `assets/chip-icon.svg`. The classic wizard follows the Windows system theme
and uses the repository preview's GPU chip beside the welcome and finished pages.
Both palettes keep the neutral sidebar distinct from the main content. The icon
and control accents use NVIDIA Green (`#76B900`); titles remain native text.
`locales.oss` contains the 24 localized custom
messages; onni supplies the standard wizard translations.

## Validation

```powershell
.\release\windows\test-release.ps1 -Package C:\Build\package
onni preview release\windows\installer.oss --scheme light --dpi 100 --dpi 150 --dpi 200 --out preview
```

The trust tests reject unsigned or altered payloads, a wrong runtime revision,
a wrong rustc fingerprint, unsafe ZIP paths, duplicate ZIP entries, false archive
sizes and streams exceeding their byte limits. Registration
tests use a private temporary registry key and leave the user's PATH unchanged.
Also test a real install, repair and uninstall, and run a newly scaffolded GPU
project with the packaged tools. Preview renders contain example values; label
them as installer previews in release documentation. The checked-in images are
native wizard previews, not proof of a completed installation.

The installer's file transaction can roll back file installation failures.
The registration helper runs after file commit; if it fails, onni reports an error
and exit code 103 while retaining the installed files. Re-run setup to repair it.
The CLI's `windows rollback` opens the previous release's installer; it does not
restore arbitrary user files or a full machine snapshot.
