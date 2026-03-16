use anyhow::{anyhow, Context, Result};
use std::env;
use std::path::PathBuf;
use std::process::Command;

#[derive(Debug, Clone)]
pub struct RuntimePaths {
    pub java_executable: PathBuf,
    pub walle_jar: PathBuf,
}

#[derive(Debug, Clone)]
pub struct EnvironmentStatus {
    pub java_version: String,
    pub java_path: PathBuf,
    pub walle_path: PathBuf,
}

pub fn resolve_runtime_paths() -> Result<RuntimePaths> {
    let exe = env::current_exe().context("failed to resolve current executable")?;
    let resources_dir = if cfg!(target_os = "macos") {
        let macos_dir = exe.parent().context("failed to get executable directory")?;
        let contents_dir = macos_dir
            .parent()
            .context("failed to resolve macOS bundle Contents directory")?;
        contents_dir.join("Resources")
    } else {
        let exe_dir = exe.parent().context("failed to get executable directory")?;
        exe_dir.join("resources")
    };

    let java_executable = if cfg!(target_os = "windows") {
        resources_dir.join("jre").join("bin").join("java.exe")
    } else {
        resources_dir.join("jre").join("bin").join("java")
    };

    let walle_jar = resources_dir.join("walle").join("walle-cli-all.jar");

    Ok(RuntimePaths {
        java_executable,
        walle_jar,
    })
}

pub fn check_environment() -> Result<EnvironmentStatus> {
    let paths = resolve_runtime_paths()?;

    if !paths.java_executable.exists() {
        return Err(anyhow!(
            "embedded Java not found at {}",
            paths.java_executable.display()
        ));
    }

    if !paths.walle_jar.exists() {
        return Err(anyhow!(
            "embedded walle-cli-all.jar not found at {}",
            paths.walle_jar.display()
        ));
    }

    let output = Command::new(&paths.java_executable)
        .arg("-version")
        .output()
        .with_context(|| {
            format!(
                "failed to execute embedded Java at {}",
                paths.java_executable.display()
            )
        })?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        let message = if stderr.trim().is_empty() {
            stdout.to_string()
        } else {
            stderr.to_string()
        };
        return Err(anyhow!(
            "embedded Java returned non-zero status: {}",
            message.trim()
        ));
    }

    let version_text = if output.stderr.is_empty() {
        String::from_utf8_lossy(&output.stdout).to_string()
    } else {
        String::from_utf8_lossy(&output.stderr).to_string()
    };

    let java_version = extract_java_version(&version_text);

    Ok(EnvironmentStatus {
        java_version,
        java_path: paths.java_executable,
        walle_path: paths.walle_jar,
    })
}

fn extract_java_version(version_output: &str) -> String {
    for line in version_output.lines() {
        let normalized = line.trim();
        if normalized.contains("version") {
            return normalized.to_string();
        }
    }
    version_output.trim().to_string()
}
