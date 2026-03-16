mod i18n;
mod runtime;
mod state;
mod worker;

use crate::i18n::I18n;
use crate::runtime::check_environment;
use crate::state::{AppState, LogEntry, LogKind, PackRequest, WorkerEvent, MAX_LOGS};
use iced::widget::{button, column, container, row, scrollable, text, text_input};
use iced::{
    application, window, Background, Border, Color, Element, Font, Length, Shadow, Subscription,
    Task, Theme, Vector,
};
use rfd::FileDialog;
use std::collections::HashSet;
use std::fs;
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::thread;
use std::time::{Duration, Instant};

const HARMONYOS_SANS_SC_BYTES: &[u8] =
    include_bytes!("../resources/fonts/HarmonyOS_Sans_SC_Regular.ttf");
const HARMONYOS_SANS_SC_FONT: Font = Font::with_name("HarmonyOS Sans SC");
const LOG_RENDER_LIMIT: usize = 120;

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
        Theme::Light
    }

    fn localized<'a>(&self, zh: &'a str, en: &'a str) -> &'a str {
        match self.i18n.locale() {
            i18n::Locale::ZhCn => zh,
            i18n::Locale::EnUs => en,
        }
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
            iced::time::every(Duration::from_millis(200)).map(Message::Tick)
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
        let locale_text = match self.i18n.locale() {
            i18n::Locale::ZhCn => "zh-CN",
            i18n::Locale::EnUs => "en-US",
        };
        let runtime_ready = self.status_text == self.i18n.env_ready();
        let runtime_style: fn(&Theme) -> container::Style = if runtime_ready {
            style_status_ok_badge
        } else {
            style_status_warn_badge
        };
        let runtime_text = if runtime_ready {
            self.localized("内置 JRE 已就绪", "Embedded JRE Ready")
        } else {
            self.localized("运行时缺失", "Runtime Missing")
        };

        let header = container(
            row![
                column![
                    text(self.i18n.app_title())
                        .size(34)
                        .color(color_text_primary()),
                    text(self.i18n.subtitle())
                        .size(15)
                        .color(color_text_secondary()),
                ]
                .spacing(4),
                iced::widget::horizontal_space(),
                column![
                    container(
                        text(format!(
                            "{} {locale_text}",
                            self.localized("语言", "Locale")
                        ))
                        .size(12)
                        .color(color_text_secondary()),
                    )
                    .style(style_tag_badge)
                    .padding([6, 10]),
                    container(text(runtime_text).size(12).color(color_text_secondary()))
                        .style(runtime_style)
                        .padding([6, 10]),
                ]
                .spacing(8)
                .align_x(iced::Alignment::End),
            ]
            .align_y(iced::Alignment::Center),
        )
        .style(style_header_card)
        .padding([18, 20]);

        let file_controls = container(
            column![
                text(self.localized("输入文件", "Input"))
                    .size(17)
                    .color(color_text_primary()),
                row![
                    button(text(self.i18n.select_apk()).size(13))
                        .style(button_style(ButtonRole::Secondary))
                        .padding([8, 12])
                        .on_press(Message::SelectApk),
                    container(text(apk_path).size(13).color(color_text_secondary()))
                        .style(style_path_pill)
                        .padding([8, 12])
                        .width(Length::Fill),
                ]
                .spacing(10)
                .align_y(iced::Alignment::Center),
                row![
                    button(text(self.i18n.select_output()).size(13))
                        .style(button_style(ButtonRole::Secondary))
                        .padding([8, 12])
                        .on_press(Message::SelectOutputDir),
                    container(text(output_dir).size(13).color(color_text_secondary()))
                        .style(style_path_pill)
                        .padding([8, 12])
                        .width(Length::Fill),
                ]
                .spacing(10)
                .align_y(iced::Alignment::Center),
            ]
            .spacing(10),
        )
        .style(style_card)
        .padding([14, 16]);

        let mut channels_list = column![].spacing(8);
        if self.state.channels.is_empty() {
            channels_list = channels_list.push(
                container(
                    text(self.localized(
                        "暂无渠道，先导入或手动添加",
                        "No channels yet. Import or add one.",
                    ))
                    .size(13)
                    .color(color_text_tertiary()),
                )
                .style(style_empty_row)
                .padding([10, 12]),
            );
        }

        for (index, channel) in self.state.channels.iter().enumerate() {
            channels_list = channels_list.push(
                container(
                    row![
                        container(
                            text(format!("{}", index + 1))
                                .size(11)
                                .color(color_text_secondary())
                        )
                        .style(style_index_badge)
                        .padding([3, 8]),
                        text(channel)
                            .size(14)
                            .color(color_text_primary())
                            .width(Length::Fill),
                        button(text(self.i18n.delete_channel()).size(12))
                            .style(button_style(ButtonRole::Destructive))
                            .padding([6, 10])
                            .on_press(Message::RemoveChannel(index)),
                    ]
                    .spacing(9)
                    .align_y(iced::Alignment::Center),
                )
                .style(style_list_row)
                .padding([7, 9]),
            );
        }

        let channels_panel = container(
            column![
                row![
                    text(self.i18n.channels_label())
                        .size(20)
                        .color(color_text_primary()),
                    iced::widget::horizontal_space(),
                    container(
                        text(format!("{}", self.state.channels.len()))
                            .size(12)
                            .color(color_text_secondary())
                    )
                    .style(style_count_badge)
                    .padding([5, 10]),
                ]
                .align_y(iced::Alignment::Center),
                row![
                    button(text(self.i18n.import_channels()).size(13))
                        .style(button_style(ButtonRole::Secondary))
                        .padding([8, 12])
                        .on_press(Message::ImportChannels),
                    button(text(self.i18n.clear_channels()).size(13))
                        .style(button_style(ButtonRole::Ghost))
                        .padding([8, 12])
                        .on_press(Message::ClearChannels),
                ]
                .spacing(8),
                row![
                    text_input(self.i18n.channel_input_placeholder(), &self.channel_input)
                        .style(style_text_input)
                        .padding([9, 10])
                        .on_input(Message::ChannelInputChanged)
                        .on_submit(Message::AddChannel)
                        .width(Length::Fill),
                    button(text(self.i18n.add_channel()).size(13))
                        .style(button_style(ButtonRole::Secondary))
                        .padding([8, 12])
                        .on_press(Message::AddChannel),
                ]
                .spacing(8)
                .align_y(iced::Alignment::Center),
                scrollable(channels_list).height(Length::Fill),
            ]
            .spacing(10)
            .height(Length::Fill),
        )
        .style(style_card)
        .padding([14, 16])
        .width(Length::FillPortion(1));

        let total_logs = self.state.logs.len();
        let logs_slice = if total_logs > LOG_RENDER_LIMIT {
            &self.state.logs[total_logs - LOG_RENDER_LIMIT..]
        } else {
            &self.state.logs[..]
        };
        let hidden_logs = total_logs.saturating_sub(logs_slice.len());

        let mut logs_column = column![].spacing(8);
        if total_logs == 0 {
            logs_column = logs_column.push(
                container(
                    text(self.localized("暂无日志输出", "No logs yet"))
                        .size(13)
                        .color(color_text_tertiary()),
                )
                .style(style_empty_row)
                .padding([10, 12]),
            );
        }

        if hidden_logs > 0 {
            logs_column = logs_column.push(
                container(
                    text(match self.i18n.locale() {
                        i18n::Locale::ZhCn => {
                            format!(
                                "仅渲染最近 {} / {} 条日志（上限 {}）",
                                logs_slice.len(),
                                total_logs,
                                MAX_LOGS
                            )
                        }
                        i18n::Locale::EnUs => {
                            format!(
                                "Rendering latest {} / {} logs (cap: {})",
                                logs_slice.len(),
                                total_logs,
                                MAX_LOGS
                            )
                        }
                    })
                    .size(12)
                    .color(color_text_tertiary()),
                )
                .style(style_empty_row)
                .padding([8, 10]),
            );
        }

        for LogEntry {
            text: content,
            kind,
        } in logs_slice
        {
            let visual = log_visual(*kind);
            logs_column = logs_column.push(
                container(
                    row![
                        container(text(visual.label).size(10).color(visual.badge_text))
                            .style(visual.badge_style)
                            .padding([3, 8]),
                        text(content)
                            .size(13)
                            .color(color_text_primary())
                            .width(Length::Fill),
                    ]
                    .spacing(8)
                    .align_y(iced::Alignment::Center),
                )
                .style(visual.row_style)
                .padding([8, 10]),
            );
        }

        let logs_panel = container(
            column![
                row![
                    text(self.i18n.logs_label())
                        .size(20)
                        .color(color_text_primary()),
                    iced::widget::horizontal_space(),
                    container(
                        text(format!("{}", total_logs))
                            .size(12)
                            .color(color_text_secondary())
                    )
                    .style(style_count_badge)
                    .padding([5, 10]),
                ]
                .align_y(iced::Alignment::Center),
                scrollable(logs_column).height(Length::Fill)
            ]
            .spacing(10)
            .height(Length::Fill),
        )
        .style(style_card)
        .padding([14, 16])
        .width(Length::FillPortion(1));

        let main_panels = row![channels_panel, logs_panel]
            .spacing(12)
            .height(Length::Fill);

        let start_button_label = if self.state.is_packing {
            self.i18n.packing()
        } else {
            self.i18n.start_pack()
        };

        let start_button = {
            let btn = button(text(start_button_label).size(14))
                .style(button_style(ButtonRole::Primary))
                .padding([10, 16]);

            if self.state.can_start_pack() {
                btn.on_press(Message::StartPack)
            } else {
                btn
            }
        };

        let footer = container(
            row![
                text(format!(
                    "{}: {}",
                    self.i18n.status_label(),
                    self.status_text
                ))
                .size(13)
                .color(color_text_secondary()),
                iced::widget::horizontal_space(),
                start_button,
            ]
            .spacing(12)
            .align_y(iced::Alignment::Center),
        )
        .style(style_footer)
        .padding([10, 12]);

        container(
            column![header, file_controls, main_panels, footer]
                .spacing(12)
                .padding([14, 14]),
        )
        .style(style_app_background)
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
            WorkerEvent::Log(entry) => self.state.push_log_entry(entry),
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

#[derive(Clone, Copy, Debug)]
enum ButtonRole {
    Primary,
    Secondary,
    Ghost,
    Destructive,
}

#[derive(Clone, Copy)]
struct LogVisual {
    label: &'static str,
    badge_text: Color,
    badge_style: fn(&Theme) -> container::Style,
    row_style: fn(&Theme) -> container::Style,
}

fn color_canvas() -> Color {
    Color::from_rgb8(238, 241, 246)
}

fn color_card() -> Color {
    Color::from_rgb8(250, 251, 253)
}

fn color_card_emphasis() -> Color {
    Color::from_rgb8(246, 249, 255)
}

fn color_border() -> Color {
    Color::from_rgb8(216, 223, 233)
}

fn color_text_primary() -> Color {
    Color::from_rgb8(31, 37, 45)
}

fn color_text_secondary() -> Color {
    Color::from_rgb8(91, 103, 120)
}

fn color_text_tertiary() -> Color {
    Color::from_rgb8(132, 145, 164)
}

fn color_blue() -> Color {
    Color::from_rgb8(45, 108, 246)
}

fn color_blue_hover() -> Color {
    Color::from_rgb8(37, 96, 231)
}

fn color_blue_pressed() -> Color {
    Color::from_rgb8(30, 83, 205)
}

fn color_red() -> Color {
    Color::from_rgb8(217, 76, 76)
}

fn color_red_hover() -> Color {
    Color::from_rgb8(197, 65, 65)
}

fn color_red_pressed() -> Color {
    Color::from_rgb8(174, 56, 56)
}

fn style_app_background(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(color_canvas())),
        border: Border::default(),
        shadow: Shadow::default(),
    }
}

fn style_header_card(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(color_card_emphasis())),
        border: Border {
            radius: 20.0.into(),
            width: 1.0,
            color: Color::from_rgb8(210, 220, 238),
        },
        shadow: Shadow {
            color: Color::from_rgba(0.14, 0.19, 0.29, 0.08),
            offset: Vector::new(0.0, 1.0),
            blur_radius: 6.0,
        },
    }
}

fn style_card(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(color_card())),
        border: Border {
            radius: 18.0.into(),
            width: 1.0,
            color: color_border(),
        },
        shadow: Shadow {
            color: Color::from_rgba(0.09, 0.14, 0.22, 0.06),
            offset: Vector::new(0.0, 1.0),
            blur_radius: 4.0,
        },
    }
}

fn style_footer(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(247, 249, 252))),
        border: Border {
            radius: 14.0.into(),
            width: 1.0,
            color: Color::from_rgb8(217, 224, 235),
        },
        shadow: Shadow::default(),
    }
}

fn style_path_pill(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_secondary()),
        background: Some(Background::Color(Color::from_rgb8(243, 246, 251))),
        border: Border {
            radius: 11.0.into(),
            width: 1.0,
            color: Color::from_rgb8(219, 226, 238),
        },
        shadow: Shadow::default(),
    }
}

fn style_tag_badge(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_secondary()),
        background: Some(Background::Color(Color::from_rgb8(241, 246, 255))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(196, 216, 248),
        },
        shadow: Shadow::default(),
    }
}

fn style_status_ok_badge(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(38, 108, 69)),
        background: Some(Background::Color(Color::from_rgb8(229, 247, 236))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(172, 223, 186),
        },
        shadow: Shadow::default(),
    }
}

fn style_status_warn_badge(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(138, 76, 39)),
        background: Some(Background::Color(Color::from_rgb8(252, 240, 226))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(238, 205, 168),
        },
        shadow: Shadow::default(),
    }
}

fn style_count_badge(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_secondary()),
        background: Some(Background::Color(Color::from_rgb8(239, 244, 251))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(206, 217, 233),
        },
        shadow: Shadow::default(),
    }
}

fn style_index_badge(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_secondary()),
        background: Some(Background::Color(Color::from_rgb8(239, 245, 255))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(210, 221, 239),
        },
        shadow: Shadow::default(),
    }
}

fn style_list_row(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(252, 253, 255))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(226, 232, 242),
        },
        shadow: Shadow::default(),
    }
}

fn style_empty_row(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_tertiary()),
        background: Some(Background::Color(Color::from_rgb8(245, 248, 252))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(225, 232, 241),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_row_success(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(245, 251, 247))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(191, 228, 205),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_badge_success(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(32, 109, 65)),
        background: Some(Background::Color(Color::from_rgb8(224, 245, 233))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(191, 228, 205),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_row_error(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(255, 246, 246))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(240, 203, 203),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_badge_error(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(153, 46, 46)),
        background: Some(Background::Color(Color::from_rgb8(252, 232, 232))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(240, 203, 203),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_row_info(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(246, 250, 255))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(196, 216, 243),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_badge_info(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(42, 93, 166)),
        background: Some(Background::Color(Color::from_rgb8(228, 239, 253))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(196, 216, 243),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_row_progress(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(color_text_primary()),
        background: Some(Background::Color(Color::from_rgb8(255, 251, 241))),
        border: Border {
            radius: 12.0.into(),
            width: 1.0,
            color: Color::from_rgb8(238, 217, 171),
        },
        shadow: Shadow::default(),
    }
}

fn style_log_badge_progress(_theme: &Theme) -> container::Style {
    container::Style {
        text_color: Some(Color::from_rgb8(131, 94, 37)),
        background: Some(Background::Color(Color::from_rgb8(250, 239, 217))),
        border: Border {
            radius: 999.0.into(),
            width: 1.0,
            color: Color::from_rgb8(238, 217, 171),
        },
        shadow: Shadow::default(),
    }
}

fn log_visual(kind: LogKind) -> LogVisual {
    match kind {
        LogKind::Success => LogVisual {
            label: "OK",
            badge_text: Color::from_rgb8(32, 109, 65),
            badge_style: style_log_badge_success,
            row_style: style_log_row_success,
        },
        LogKind::Error => LogVisual {
            label: "ERR",
            badge_text: Color::from_rgb8(153, 46, 46),
            badge_style: style_log_badge_error,
            row_style: style_log_row_error,
        },
        LogKind::Info => LogVisual {
            label: "INFO",
            badge_text: Color::from_rgb8(42, 93, 166),
            badge_style: style_log_badge_info,
            row_style: style_log_row_info,
        },
        LogKind::Progress => LogVisual {
            label: "RUN",
            badge_text: Color::from_rgb8(131, 94, 37),
            badge_style: style_log_badge_progress,
            row_style: style_log_row_progress,
        },
    }
}

fn style_text_input(_theme: &Theme, status: text_input::Status) -> text_input::Style {
    let mut border_color = Color::from_rgb8(206, 215, 229);
    let mut background = Color::from_rgb8(252, 253, 255);

    match status {
        text_input::Status::Hovered => {
            border_color = Color::from_rgb8(183, 196, 215);
        }
        text_input::Status::Focused => {
            border_color = color_blue();
        }
        text_input::Status::Disabled => {
            border_color = Color::from_rgb8(222, 228, 238);
            background = Color::from_rgb8(246, 248, 252);
        }
        _ => {}
    }

    text_input::Style {
        background: Background::Color(background),
        border: Border {
            radius: 11.0.into(),
            width: 1.0,
            color: border_color,
        },
        icon: color_text_tertiary(),
        placeholder: color_text_tertiary(),
        value: color_text_primary(),
        selection: Color::from_rgba(0.21, 0.45, 0.96, 0.25),
    }
}

fn button_style(role: ButtonRole) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |_theme, status| {
        let (background, text, border) = match (role, status) {
            (_, button::Status::Disabled) => (
                Color::from_rgb8(234, 238, 245),
                Color::from_rgb8(150, 160, 174),
                Color::from_rgb8(214, 223, 236),
            ),
            (ButtonRole::Primary, button::Status::Hovered) => (
                color_blue_hover(),
                Color::WHITE,
                Color::from_rgb8(30, 90, 217),
            ),
            (ButtonRole::Primary, button::Status::Pressed) => (
                color_blue_pressed(),
                Color::WHITE,
                Color::from_rgb8(24, 74, 183),
            ),
            (ButtonRole::Primary, _) => {
                (color_blue(), Color::WHITE, Color::from_rgb8(44, 100, 223))
            }
            (ButtonRole::Secondary, button::Status::Hovered) => (
                Color::from_rgb8(239, 245, 255),
                Color::from_rgb8(53, 90, 150),
                Color::from_rgb8(165, 191, 234),
            ),
            (ButtonRole::Secondary, button::Status::Pressed) => (
                Color::from_rgb8(227, 236, 251),
                Color::from_rgb8(44, 78, 133),
                Color::from_rgb8(149, 177, 223),
            ),
            (ButtonRole::Secondary, _) => (
                Color::from_rgb8(235, 243, 255),
                Color::from_rgb8(59, 93, 149),
                Color::from_rgb8(180, 203, 241),
            ),
            (ButtonRole::Destructive, button::Status::Hovered) => (
                color_red_hover(),
                Color::WHITE,
                Color::from_rgb8(180, 55, 55),
            ),
            (ButtonRole::Destructive, button::Status::Pressed) => (
                color_red_pressed(),
                Color::WHITE,
                Color::from_rgb8(159, 49, 49),
            ),
            (ButtonRole::Destructive, _) => {
                (color_red(), Color::WHITE, Color::from_rgb8(193, 66, 66))
            }
            (ButtonRole::Ghost, button::Status::Hovered) => (
                Color::from_rgb8(239, 243, 250),
                color_text_primary(),
                Color::from_rgb8(187, 198, 215),
            ),
            (ButtonRole::Ghost, button::Status::Pressed) => (
                Color::from_rgb8(228, 233, 243),
                color_text_primary(),
                Color::from_rgb8(174, 186, 204),
            ),
            (ButtonRole::Ghost, _) => (
                Color::from_rgb8(246, 249, 253),
                color_text_secondary(),
                Color::from_rgb8(210, 220, 233),
            ),
        };

        button::Style {
            background: Some(Background::Color(background)),
            text_color: text,
            border: Border {
                radius: 10.0.into(),
                width: 1.0,
                color: border,
            },
            shadow: Shadow::default(),
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
