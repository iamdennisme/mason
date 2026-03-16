use sys_locale::get_locale;

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub enum Locale {
    ZhCn,
    EnUs,
}

#[derive(Debug, Clone)]
pub struct I18n {
    locale: Locale,
}

impl I18n {
    pub fn auto() -> Self {
        let locale = detect_locale();
        Self { locale }
    }

    pub fn locale(&self) -> Locale {
        self.locale
    }

    pub fn app_title(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "Mason 渠道打包工具",
            Locale::EnUs => "Mason Channel Packager",
        }
    }

    pub fn subtitle(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "Android 渠道批量打包",
            Locale::EnUs => "Batch channel packaging for Android APKs",
        }
    }

    pub fn select_apk(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "选择 APK",
            Locale::EnUs => "Select APK",
        }
    }

    pub fn select_output(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "选择输出目录",
            Locale::EnUs => "Select Output",
        }
    }

    pub fn import_channels(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "导入文件",
            Locale::EnUs => "Import File",
        }
    }

    pub fn clear_channels(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "清空",
            Locale::EnUs => "Clear",
        }
    }

    pub fn add_channel(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "添加",
            Locale::EnUs => "Add",
        }
    }

    pub fn delete_channel(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "删除",
            Locale::EnUs => "Delete",
        }
    }

    pub fn channels_label(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道列表",
            Locale::EnUs => "Channels",
        }
    }

    pub fn logs_label(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "日志",
            Locale::EnUs => "Logs",
        }
    }

    pub fn status_label(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "状态",
            Locale::EnUs => "Status",
        }
    }

    pub fn start_pack(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "开始打包",
            Locale::EnUs => "Start Pack",
        }
    }

    pub fn packing(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "打包中...",
            Locale::EnUs => "Packing...",
        }
    }

    pub fn no_apk(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "未选择 APK",
            Locale::EnUs => "No APK selected",
        }
    }

    pub fn no_output(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "未选择输出目录",
            Locale::EnUs => "No output directory selected",
        }
    }

    pub fn channel_input_placeholder(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "输入渠道并回车",
            Locale::EnUs => "Add channel and press Enter",
        }
    }

    pub fn env_ready(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "环境就绪",
            Locale::EnUs => "Environment ready",
        }
    }

    pub fn env_missing(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "内置运行时缺失",
            Locale::EnUs => "Missing embedded runtime",
        }
    }

    pub fn apk_selected(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "已选择 APK",
            Locale::EnUs => "APK selected",
        }
    }

    pub fn output_selected(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "已选择输出目录",
            Locale::EnUs => "Output selected",
        }
    }

    pub fn channels_imported(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道已导入",
            Locale::EnUs => "Channels imported",
        }
    }

    pub fn channels_import_failed(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道导入失败",
            Locale::EnUs => "Channel import failed",
        }
    }

    pub fn channels_cleared(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道已清空",
            Locale::EnUs => "Channels cleared",
        }
    }

    pub fn channel_removed(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道已删除",
            Locale::EnUs => "Channel removed",
        }
    }

    pub fn channel_added(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道已添加",
            Locale::EnUs => "Channel added",
        }
    }

    pub fn channel_unchanged(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "渠道未变化",
            Locale::EnUs => "Channel unchanged",
        }
    }

    pub fn cannot_start(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "无法开始",
            Locale::EnUs => "Cannot start",
        }
    }

    pub fn completed(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "已完成",
            Locale::EnUs => "Completed",
        }
    }

    pub fn failed(&self) -> &'static str {
        match self.locale {
            Locale::ZhCn => "失败",
            Locale::EnUs => "Failed",
        }
    }

    pub fn packing_progress(&self, current: usize, total: usize) -> String {
        match self.locale {
            Locale::ZhCn => format!("打包中 {current}/{total}"),
            Locale::EnUs => format!("Packing {current}/{total}"),
        }
    }
}

fn detect_locale() -> Locale {
    if let Some(locale) = get_locale() {
        if locale.to_lowercase().starts_with("zh") {
            return Locale::ZhCn;
        }
    }
    Locale::EnUs
}
