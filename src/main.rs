mod i18n;
mod runtime;
mod state;
mod worker;

use crate::i18n::I18n;
use crate::runtime::check_environment;
use crate::state::{AppState, LogEntry, LogKind, PackRequest, WorkerEvent};
use iced::widget::{button, column, container, row, scrollable, text, text_input};
use iced::{application, window, Element, Font, Length, Subscription, Task, Theme};
use rfd::FileDialog;
use std::collections::HashSet;
use std::fs;
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::thread;
use std::time::{Duration, Instant};

const HARMONYOS_SANS_SC_BYTES: &[u8] =
    include_bytes!("../resources/fonts/HarmonyOS_Sans_SC_Regular.ttf");
const HARMONYOS_SANS_SC_FONT: Font = Font::with_name("HarmonyOS Sans SC");

#[derive(Debug, Clone)]
enum Message {
    SelectApk,
    SelectOutputDir,
    ImportChannels,
    ClearChannels,
    AddChannel,
    RemoveChannel(usize),
    StartPack,
    ChannelInputChanged(String),
    Tick(Instant),
}

struct MasonApp {
    state: AppState,
    i18n: I18n,
    channel_input: String,
    status_text: String,
    worker_rx: Option<Receiver<WorkerEvent>>,
}

impl MasonApp {
    fn new() -> (Self, Task<Message>) {
        let i18n = I18n::auto();
        let mut state = AppState::default();
        let status_text;

        match check_environment() {
            Ok(env) => {
                state.push_log(
                    LogKind::Success,
                    format!("Embedded Java ready: {}", env.java_version),
                );
                status_text = i18n.env_ready().to_string();
            }
            Err(err) => {
                state.push_log(LogKind::Error, format!("Environment check failed: {err}"));
                status_text = i18n.env_missing().to_string();
            }
        }

        (
            Self {
                state,
                i18n,
                channel_input: String::new(),
                status_text,
                worker_rx: None,
            },
            Task::none(),
        )
    }

    fn title(&self) -> String {
        self.i18n.app_title().to_string()
    }

    fn theme(&self) -> Theme {
        Theme::Dark
    }

    fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::SelectApk => {
                if self.state.is_packing {
                    return Task::none();
                }

                if let Some(path) = FileDialog::new()
                    .add_filter("APK", &["apk"])
                    .set_title(self.i18n.select_apk())
                    .pick_file()
                {
                    self.state.apk_path = Some(path.clone());
                    self.state
                        .push_log(LogKind::Info, format!("APK selected: {}", path.display()));
                    self.status_text = self.i18n.apk_selected().to_string();
                }
            }
            Message::SelectOutputDir => {
                if self.state.is_packing {
                    return Task::none();
                }

                if let Some(path) = FileDialog::new()
                    .set_title(self.i18n.select_output())
                    .pick_folder()
                {
                    self.state.output_dir = Some(path.clone());
                    self.state.push_log(
                        LogKind::Info,
                        format!("Output directory: {}", path.display()),
                    );
                    self.status_text = self.i18n.output_selected().to_string();
                }
            }
            Message::ImportChannels => {
                if self.state.is_packing {
                    return Task::none();
                }

                if let Some(path) = FileDialog::new()
                    .set_title(self.i18n.import_channels())
                    .pick_file()
                {
                    match fs::read_to_string(&path) {
                        Ok(content) => {
                            let imported =
                                normalize_channels(content.lines().map(ToOwned::to_owned));
                            if imported.is_empty() {
                                self.state.push_log(
                                    LogKind::Error,
                                    "No valid channels found in the file",
                                );
                                self.status_text = self.i18n.channels_import_failed().to_string();
                            } else {
                                self.state.channels =
                                    merge_channels(&self.state.channels, &imported);
                                self.state.push_log(
                                    LogKind::Success,
                                    format!(
                                        "Imported {} channel(s) from {}",
                                        imported.len(),
                                        path.display()
                                    ),
                                );
                                self.status_text = self.i18n.channels_imported().to_string();
                            }
                        }
                        Err(err) => {
                            self.state.push_log(
                                LogKind::Error,
                                format!("Failed to read channel file: {err}"),
                            );
                            self.status_text = self.i18n.channels_import_failed().to_string();
                        }
                    }
                }
            }
            Message::ClearChannels => {
                if self.state.is_packing {
                    return Task::none();
                }

                self.state.channels.clear();
                self.state.push_log(LogKind::Info, "All channels cleared");
                self.status_text = self.i18n.channels_cleared().to_string();
            }
            Message::AddChannel => {
                if self.state.is_packing {
                    return Task::none();
                }

                let channel = self.channel_input.trim();
                if channel.is_empty() {
                    return Task::none();
                }

                if self.state.channels.iter().any(|value| value == channel) {
                    self.state
                        .push_log(LogKind::Info, format!("Channel already exists: {channel}"));
                    self.status_text = self.i18n.channel_unchanged().to_string();
                } else {
                    self.state.channels.push(channel.to_string());
                    self.state
                        .push_log(LogKind::Success, format!("Added channel: {channel}"));
                    self.status_text = self.i18n.channel_added().to_string();
                }

                self.channel_input.clear();
            }
            Message::RemoveChannel(index) => {
                if self.state.is_packing {
                    return Task::none();
                }

                if index < self.state.channels.len() {
                    let removed = self.state.channels.remove(index);
                    self.state
                        .push_log(LogKind::Info, format!("Removed channel: {removed}"));
                    self.status_text = self.i18n.channel_removed().to_string();
                }
            }
            Message::StartPack => {
                if !self.state.can_start_pack() {
                    self.state.push_log(
                        LogKind::Error,
                        "Select APK, output directory, and at least one channel",
                    );
                    self.status_text = self.i18n.cannot_start().to_string();
                    return Task::none();
                }

                let request = PackRequest {
                    apk_path: self
                        .state
                        .apk_path
                        .clone()
                        .expect("apk_path validated before start"),
                    output_dir: self
                        .state
                        .output_dir
                        .clone()
                        .expect("output_dir validated before start"),
                    channels: self.state.channels.clone(),
                };

                self.state.is_packing = true;
                self.status_text = self.i18n.packing().to_string();
                self.state.push_log(
                    LogKind::Info,
                    format!("Starting package for {} channel(s)", request.channels.len()),
                );

                let (tx, rx) = mpsc::channel::<WorkerEvent>();
                self.worker_rx = Some(rx);
                thread::spawn(move || worker::run_pack(request, tx));
            }
            Message::ChannelInputChanged(value) => {
                self.channel_input = value;
            }
            Message::Tick(_now) => {
                self.poll_worker_events();
            }
        }

        Task::none()
    }

    fn subscription(&self) -> Subscription<Message> {
        if self.state.is_packing {
            iced::time::every(Duration::from_millis(120)).map(Message::Tick)
        } else {
            Subscription::none()
        }
    }

    fn view(&self) -> Element<'_, Message> {
        let apk_path = self
            .state
            .apk_path
            .as_ref()
            .map(|value| value.display().to_string())
            .unwrap_or_else(|| self.i18n.no_apk().to_string());

        let output_dir = self
            .state
            .output_dir
            .as_ref()
            .map(|value| value.display().to_string())
            .unwrap_or_else(|| self.i18n.no_output().to_string());

        let header = column![
            text(self.i18n.app_title()).size(30),
            text(self.i18n.subtitle()).size(16),
            text(format!(
                "Locale: {}",
                match self.i18n.locale() {
                    i18n::Locale::ZhCn => "zh-CN",
                    i18n::Locale::EnUs => "en-US",
                }
            ))
            .size(12)
        ]
        .spacing(4);

        let file_controls = column![
            row![
                button(self.i18n.select_apk()).on_press(Message::SelectApk),
                text(apk_path).size(14)
            ]
            .spacing(12)
            .align_y(iced::Alignment::Center),
            row![
                button(self.i18n.select_output()).on_press(Message::SelectOutputDir),
                text(output_dir).size(14)
            ]
            .spacing(12)
            .align_y(iced::Alignment::Center),
        ]
        .spacing(12);

        let mut channels_list = column![];
        for (index, channel) in self.state.channels.iter().enumerate() {
            channels_list = channels_list.push(
                row![
                    text(format!("{}", index + 1)).size(12),
                    text(channel).size(14).width(Length::Fill),
                    button(self.i18n.delete_channel()).on_press(Message::RemoveChannel(index))
                ]
                .spacing(8)
                .align_y(iced::Alignment::Center),
            );
        }

        let channels_panel = column![
            row![
                text(self.i18n.channels_label()).size(20),
                text(format!("({})", self.state.channels.len())).size(14),
            ]
            .spacing(8)
            .align_y(iced::Alignment::Center),
            row![
                button(self.i18n.import_channels()).on_press(Message::ImportChannels),
                button(self.i18n.clear_channels()).on_press(Message::ClearChannels),
            ]
            .spacing(8),
            row![
                text_input(self.i18n.channel_input_placeholder(), &self.channel_input)
                    .on_input(Message::ChannelInputChanged)
                    .on_submit(Message::AddChannel)
                    .width(Length::Fill),
                button(self.i18n.add_channel()).on_press(Message::AddChannel)
            ]
            .spacing(8)
            .align_y(iced::Alignment::Center),
            scrollable(channels_list.spacing(6)).height(Length::Fill),
        ]
        .spacing(10)
        .height(Length::Fill);

        let mut logs_column = column![];
        for LogEntry {
            text: content,
            kind,
        } in &self.state.logs
        {
            let color = match kind {
                LogKind::Success => iced::Color::from_rgb8(105, 205, 120),
                LogKind::Error => iced::Color::from_rgb8(235, 98, 98),
                LogKind::Info => iced::Color::from_rgb8(135, 181, 235),
                LogKind::Progress => iced::Color::from_rgb8(235, 190, 98),
            };
            logs_column = logs_column.push(text(content).size(13).color(color));
        }

        let logs_panel = column![
            text(self.i18n.logs_label()).size(20),
            scrollable(logs_column.spacing(4)).height(Length::Fill)
        ]
        .spacing(10)
        .height(Length::Fill);

        let main_panels = row![
            container(channels_panel)
                .width(Length::FillPortion(1))
                .padding(12),
            container(logs_panel)
                .width(Length::FillPortion(1))
                .padding(12),
        ]
        .spacing(12)
        .height(Length::Fill);

        let start_button_label = if self.state.is_packing {
            self.i18n.packing()
        } else {
            self.i18n.start_pack()
        };

        let footer = row![
            text(format!(
                "{}: {}",
                self.i18n.status_label(),
                self.status_text
            ))
            .size(14),
            iced::widget::horizontal_space(),
            button(start_button_label).on_press(Message::StartPack),
        ]
        .spacing(12)
        .align_y(iced::Alignment::Center);

        container(
            column![header, file_controls, main_panels, footer]
                .spacing(14)
                .padding(16),
        )
        .width(Length::Fill)
        .height(Length::Fill)
        .into()
    }

    fn poll_worker_events(&mut self) {
        let mut close_channel = false;
        let mut pending_events = Vec::new();

        if let Some(rx) = &self.worker_rx {
            loop {
                match rx.try_recv() {
                    Ok(event) => {
                        let is_terminal = event.is_terminal();
                        pending_events.push(event);
                        if is_terminal {
                            close_channel = true;
                            break;
                        }
                    }
                    Err(TryRecvError::Empty) => break,
                    Err(TryRecvError::Disconnected) => {
                        close_channel = true;
                        break;
                    }
                }
            }
        }

        for event in pending_events {
            self.apply_worker_event(event);
        }

        if close_channel {
            self.worker_rx = None;
        }
    }

    fn apply_worker_event(&mut self, event: WorkerEvent) {
        match event {
            WorkerEvent::Progress {
                channel,
                current,
                total,
            } => {
                self.state.push_log(
                    LogKind::Progress,
                    format!("Packing channel: {channel} ({current}/{total})"),
                );
                self.status_text = self.i18n.packing_progress(current, total);
            }
            WorkerEvent::Log(entry) => self.state.logs.push(entry),
            WorkerEvent::Completed {
                generated_files,
                elapsed_ms,
            } => {
                self.state.is_packing = false;
                self.state.push_log(
                    LogKind::Success,
                    format!(
                        "Completed. Generated {} file(s) in {:.2}s",
                        generated_files.len(),
                        elapsed_ms as f64 / 1000.0
                    ),
                );
                self.status_text = self.i18n.completed().to_string();
            }
            WorkerEvent::Failed { error } => {
                self.state.is_packing = false;
                self.state
                    .push_log(LogKind::Error, format!("Packaging failed: {error}"));
                self.status_text = self.i18n.failed().to_string();
            }
        }
    }
}

fn merge_channels(existing: &[String], incoming: &[String]) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut merged = Vec::with_capacity(existing.len() + incoming.len());

    for value in existing.iter().chain(incoming.iter()) {
        if seen.insert(value.to_lowercase()) {
            merged.push(value.clone());
        }
    }

    merged
}

fn normalize_channels<I>(lines: I) -> Vec<String>
where
    I: Iterator<Item = String>,
{
    let mut seen = HashSet::new();
    let mut result = Vec::new();

    for line in lines {
        let normalized = line.trim();
        if normalized.is_empty() {
            continue;
        }

        let key = normalized.to_lowercase();
        if seen.insert(key) {
            result.push(normalized.to_string());
        }
    }

    result
}

fn main() -> iced::Result {
    application(MasonApp::title, MasonApp::update, MasonApp::view)
        .theme(MasonApp::theme)
        .subscription(MasonApp::subscription)
        .font(HARMONYOS_SANS_SC_BYTES)
        .default_font(HARMONYOS_SANS_SC_FONT)
        .window(window::Settings {
            size: iced::Size::new(1120.0, 760.0),
            min_size: Some(iced::Size::new(980.0, 680.0)),
            ..window::Settings::default()
        })
        .run_with(MasonApp::new)
}
