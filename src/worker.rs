use crate::runtime;
use crate::state::{LogEntry, LogKind, PackRequest, WorkerEvent};
use anyhow::{anyhow, Context, Result};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::sync::mpsc::Sender;
use std::time::Instant;

pub fn run_pack(request: PackRequest, tx: Sender<WorkerEvent>) {
    let started = Instant::now();
    if let Err(err) = execute_pack(&request, &tx, started) {
        let _ = tx.send(WorkerEvent::Failed {
            error: err.to_string(),
        });
    }
}

fn execute_pack(request: &PackRequest, tx: &Sender<WorkerEvent>, started: Instant) -> Result<()> {
    if !request.apk_path.exists() {
        return Err(anyhow!(
            "APK file does not exist: {}",
            request.apk_path.display()
        ));
    }

    fs::create_dir_all(&request.output_dir).with_context(|| {
        format!(
            "failed to create output directory {}",
            request.output_dir.display()
        )
    })?;

    let env = runtime::check_environment()?;
    let _ = tx.send(WorkerEvent::Log(LogEntry::new(
        LogKind::Info,
        format!("Embedded Java: {}", env.java_path.display()),
    )));
    let _ = tx.send(WorkerEvent::Log(LogEntry::new(
        LogKind::Info,
        format!("Java version: {}", env.java_version),
    )));
    let _ = tx.send(WorkerEvent::Log(LogEntry::new(
        LogKind::Info,
        format!("Walle JAR: {}", env.walle_path.display()),
    )));

    let total = request.channels.len();
    let mut generated_files = Vec::with_capacity(total);

    for (index, channel) in request.channels.iter().enumerate() {
        let current = index + 1;
        let _ = tx.send(WorkerEvent::Progress {
            channel: channel.clone(),
            current,
            total,
        });

        let target_file = output_path_for_channel(&request.apk_path, &request.output_dir, channel);

        let output = Command::new(&env.java_path)
            .arg("-jar")
            .arg(&env.walle_path)
            .arg("put")
            .arg("--channel")
            .arg(channel)
            .arg(&request.apk_path)
            .arg(&target_file)
            .output()
            .with_context(|| format!("failed to run walle command for channel '{}'", channel))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            let stdout = String::from_utf8_lossy(&output.stdout);
            let details = if stderr.trim().is_empty() {
                stdout.trim().to_string()
            } else {
                stderr.trim().to_string()
            };
            return Err(anyhow!(
                "channel '{}' failed: {}",
                channel,
                if details.is_empty() {
                    "walle returned non-zero exit status".to_string()
                } else {
                    details
                }
            ));
        }

        generated_files.push(target_file.clone());
        let _ = tx.send(WorkerEvent::Log(LogEntry::new(
            LogKind::Success,
            format!(
                "[{} / {}] {} => {}",
                current,
                total,
                channel,
                target_file.display()
            ),
        )));
    }

    let elapsed_ms = started.elapsed().as_millis();
    let _ = tx.send(WorkerEvent::Completed {
        generated_files,
        elapsed_ms,
    });

    Ok(())
}

fn output_path_for_channel(apk_path: &PathBuf, output_dir: &PathBuf, channel: &str) -> PathBuf {
    let base_name = apk_path
        .file_stem()
        .and_then(|value| value.to_str())
        .unwrap_or("app");
    let ext = apk_path
        .extension()
        .and_then(|value| value.to_str())
        .unwrap_or("apk");

    let sanitized_channel = channel
        .chars()
        .map(|ch| match ch {
            '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            _ => ch,
        })
        .collect::<String>();

    output_dir.join(format!("{}_{}.{}", base_name, sanitized_channel, ext))
}
