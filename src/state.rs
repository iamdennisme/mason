use std::path::PathBuf;

pub const MAX_LOGS: usize = 300;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LogKind {
    Success,
    Error,
    Info,
    Progress,
}

#[derive(Clone, Debug)]
pub struct LogEntry {
    pub text: String,
    pub kind: LogKind,
}

impl LogEntry {
    pub fn new(kind: LogKind, text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            kind,
        }
    }
}

#[derive(Clone, Debug)]
pub struct AppState {
    pub apk_path: Option<PathBuf>,
    pub output_dir: Option<PathBuf>,
    pub channels: Vec<String>,
    pub logs: Vec<LogEntry>,
    pub is_packing: bool,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            apk_path: None,
            output_dir: None,
            channels: Vec::new(),
            logs: vec![LogEntry::new(
                LogKind::Info,
                "Mason Rust ready. Select APK and channels to start packaging.",
            )],
            is_packing: false,
        }
    }
}

impl AppState {
    pub fn can_start_pack(&self) -> bool {
        !self.is_packing
            && self.apk_path.is_some()
            && self.output_dir.is_some()
            && !self.channels.is_empty()
    }

    pub fn push_log_entry(&mut self, entry: LogEntry) {
        self.logs.push(entry);
        self.trim_logs();
    }

    pub fn push_log(&mut self, kind: LogKind, message: impl Into<String>) {
        self.push_log_entry(LogEntry::new(kind, message));
    }

    fn trim_logs(&mut self) {
        let overflow = self.logs.len().saturating_sub(MAX_LOGS);
        if overflow > 0 {
            self.logs.drain(0..overflow);
        }
    }
}

#[derive(Clone, Debug)]
pub struct PackRequest {
    pub apk_path: PathBuf,
    pub output_dir: PathBuf,
    pub channels: Vec<String>,
}

#[derive(Clone, Debug)]
pub enum WorkerEvent {
    Progress {
        channel: String,
        current: usize,
        total: usize,
    },
    Log(LogEntry),
    Completed {
        generated_files: Vec<PathBuf>,
        elapsed_ms: u128,
    },
    Failed {
        error: String,
    },
}

impl WorkerEvent {
    pub fn is_terminal(&self) -> bool {
        matches!(
            self,
            WorkerEvent::Completed { .. } | WorkerEvent::Failed { .. }
        )
    }
}
