/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

//! Signed Windows distributions and the matching prebuilt compiler backend.
//! PowerShell delegates trust decisions to Windows Authenticode verification.

use std::path::{Path, PathBuf};
use std::process::Command;

/// Embedded downloader and installer registration helper.
/// Its downloaded inputs must match the release publisher and signed manifest.
const SCRIPT: &str = include_str!("windows_release.ps1");

/// Selects the release operation independently of any Cargo project.
/// Updating and rollback open the signed onni installer, then release the CLI.
#[derive(Clone, Copy, Debug, clap::ValueEnum)]
pub enum Action {
    /// Install the requested version, or this CLI's version.
    /// The installer checks its destination and remembers previous choices.
    Install,
    /// Download the latest Windows release and open its installer.
    /// An explicit version selects a particular published release instead.
    Update,
    /// Open the installer for the previously installed Windows version.
    /// A first installation has no previous version to restore.
    Rollback,
}

/// Runs a managed installation operation without resolving project metadata.
/// Errors preserve the installed binaries and are printed by the CLI boundary.
pub fn run(action: Action, version: Option<&str>, download_only: bool) -> Result<(), String> {
    let action_name = match action {
        Action::Install => "Install",
        Action::Update => "Update",
        Action::Rollback => "Rollback",
    };
    let chosen = match action {
        Action::Install => Some(version.unwrap_or(env!("CARGO_PKG_VERSION"))),
        _ => version,
    };
    if matches!(action, Action::Rollback) && version.is_some() {
        return Err("rollback uses the recorded previous version; omit --version".into());
    }
    with_script(|cmd| {
        cmd.args(["-Action", action_name]);
        if let Some(version) = chosen {
            cmd.args(["-Version", version]);
        }
        if download_only {
            cmd.arg("-DownloadOnly");
        }
        let status = cmd
            .status()
            .map_err(|e| format!("could not run Windows setup: {e}"))?;
        if status.success() {
            Ok(())
        } else {
            Err("Windows release installation failed; see the diagnostic above".into())
        }
    })
}

/// Downloads only a backend whose signed metadata matches both dependency and rustc.
/// Other platforms, source revisions and explicit source-only mode keep source builds.
pub fn prebuilt(cache: &Path, revision: Option<&str>) -> Result<Option<PathBuf>, String> {
    if !supports_prebuilt(revision) {
        return Ok(None);
    }
    let destination = cache.join("releases").join(env!("CARGO_PKG_VERSION"));
    if !destination.is_dir() && std::env::var_os("CARGO_NET_OFFLINE").is_some_and(|v| v == "true") {
        return Ok(None);
    }
    verify_directory(&destination)?;
    let backend = destination.join("rustc_codegen_cuda.dll");
    if !backend.is_file() {
        return Err("verified backend was not installed".into());
    }
    Ok(Some(backend))
}

/// Validates the signed side-by-side package before loading its compiler DLL.
/// Callers first check that the project's resolved source matches the release.
pub fn verify_packaged(backend: &Path) -> Result<(), String> {
    verify_directory(backend.parent().ok_or("backend has no parent directory")?)
}

/// Verifies an existing package or installs it atomically into a new directory.
/// The signed manifest binds the runtime commit, full rustc fingerprint and files.
fn verify_directory(destination: &Path) -> Result<(), String> {
    let fingerprint = crate::backend::current_toolchain_fingerprint()
        .ok_or("could not identify rustc for the prebuilt backend")?;
    with_script(|cmd| {
        cmd.args([
            "-Action",
            "Backend",
            "-Version",
            env!("CARGO_PKG_VERSION"),
            "-Destination",
        ])
        .arg(destination)
        .args([
            "-ExpectedRevision",
            crate::backend::PINNED_SOURCE_REVISION,
            "-ExpectedRustc",
            &fingerprint,
        ]);
        let output = cmd
            .output()
            .map_err(|e| format!("could not download prebuilt backend: {e}"))?;
        if !output.status.success() {
            return Err(format!(
                "Signed Windows backend setup failed:\n{}\nSet CUDA_OXIDE_PREBUILT=0 to build from source.",
                String::from_utf8_lossy(&output.stderr)
            ));
        }
        Ok(())
    })
}

/// Only the release's exact runtime revision can use its precompiled backend.
/// Other hosts and explicit source-only mode retain the existing build path.
pub fn supports_prebuilt(revision: Option<&str>) -> bool {
    cfg!(all(windows, target_arch = "x86_64"))
        && !source_only()
        && revision.is_none_or(|r| r == crate::backend::PINNED_SOURCE_REVISION)
}

/// Explicitly bypass both adjacent packages and downloaded release backends.
pub fn source_only() -> bool {
    std::env::var_os("CUDA_OXIDE_PREBUILT").is_some_and(|v| v == "0")
}

/// Writes the embedded helper to an exclusively created temporary directory.
/// Arguments are passed as separate process arguments; no shell interpolation is used.
fn with_script<T>(run: impl FnOnce(&mut Command) -> Result<T, String>) -> Result<T, String> {
    if !cfg!(windows) {
        return Err("Windows release commands require Windows x64".into());
    }
    let root = std::env::temp_dir();
    let nonce = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_nanos();
    let directory = root.join(format!("cuda-oxide-release-{}-{nonce}", std::process::id()));
    std::fs::create_dir(&directory).map_err(|e| e.to_string())?;
    let result = (|| {
        let script = directory.join("manage.ps1");
        std::fs::write(&script, SCRIPT).map_err(|e| e.to_string())?;
        let windows = std::env::var_os("SystemRoot").ok_or("SystemRoot is not set")?;
        let exe = PathBuf::from(windows).join("System32/WindowsPowerShell/v1.0/powershell.exe");
        let mut cmd = Command::new(exe);
        cmd.env_remove("PSModulePath");
        cmd.args([
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
        ])
        .arg(script);
        run(&mut cmd)
    })();
    let _ = std::fs::remove_dir_all(&directory);
    result
}
