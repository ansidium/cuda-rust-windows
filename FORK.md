# CUDA Rust Windows Fork

This fork adds `x86_64-pc-windows-msvc` support to
[NVIDIA/cuda-rust](https://github.com/NVIDIA/cuda-rust).
The upstream baseline is `cced2a35bcc557b30f27209ff3887b4eb728cb63`
(CUDA-Oxide 0.3.0, shared host crates 0.5.0).

## Maintenance

- Sync upstream into `main` with merge commits. Do not rewrite published `main` history.
- Base feature branches on the fork's synchronized `main`.
- Keep Windows changes narrow. Preserve upstream behavior outside Windows.
- Do not add fork-only public APIs without discussion and documentation.
- Linux regressions block a change unless the pull request explains the
  regression and the follow-up needed to restore compatibility.
- Push only to the fork. Before pushing, run `git remote -v` and verify the
  full `OWNER/REPOSITORY`; `NVIDIA/cuda-rust` is read-only.

## Upstream sync

Start on a clean `main` branch. Configure `upstream` once:

```bash
git remote add upstream https://github.com/NVIDIA/cuda-rust.git
```

Fetch and merge:

```bash
git fetch upstream --tags
git switch main
git merge --no-ff --signoff upstream/main
```

Accept upstream changes unrelated to Windows, then retain only the Windows
compatibility changes still needed. Document intentional differences below.

The PowerShell helper combines the merge and checks. Run it from a clean
repository root on `main`:

```powershell
.\scripts\sync-upstream.ps1 -RunChecks
```

Add `-Push` to push `main` to `origin` after the checks pass. The helper does
not create releases, move tags, or change versions.

## Windows checks

Run from the SIMT workspace:

```powershell
cd cuda-oxide
cargo build --locked -p cargo-oxide
.\target\debug\cargo-oxide.exe doctor
.\target\debug\cargo-oxide.exe build vecadd
.\target\debug\cargo-oxide.exe run vecadd
.\scripts\smoketest.ps1
```

Kernel execution needs an NVIDIA GPU. On a machine without one, use
`.\scripts\smoketest.ps1 -BuildOnly`.
Update [CHANGELOG.windows.md](CHANGELOG.windows.md) when Windows support changes.

The [upstream monitor](.github/workflows/upstream-monitor.yml),
[weekly sync](.github/workflows/upstream-sync-main.yml), and
[Windows canary](.github/workflows/windows.yml) automate drift detection,
upstream merges, and MSVC compilation checks.

## Releases

Publish `windows-vX.Y.Z` only after upstream has released the matching
CUDA-Oxide version. Build the archive with
`cuda-oxide/scripts/package-windows-release.ps1`; see
[Windows setup](cuda-oxide/cuda-oxide-book/getting-started/windows.md).

## Windows differences

- MSVC CUDA enum conversions, COFF artifact embedding, and Windows DLL discovery.
- Release-profile backend builds on Windows.
- Generated projects pin the runtime and compiler dependencies to one fork revision.
- The host, SIMT, and Tile workspaces use Rust 1.99.1. Upstream's host and Tile
  pins are 1.98.0 at this baseline.
- Fork CI uses GitHub-hosted CPU runners. NVIDIA's GPU runner pool is limited
  to the canonical repository.

Past changes are recorded in [CHANGELOG.windows.md](CHANGELOG.windows.md).
