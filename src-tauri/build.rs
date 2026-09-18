const COMMANDS: &[&str] = &[
    "app_web_url",
    "get_config",
    "is_onboarded",
    "open_external",
    "frontend_log",
    "meeting_window_status",
    "dictation_request_access",
    "dictation_start",
    "dictation_stop",
    "quick_bar",
    "notch_bar",
    "meeting_bar",
    "perf_mark",
    "dismiss_news",
    "set_active_thread",
];

fn main() {
    tauri_build::try_build(
        tauri_build::Attributes::new()
            .app_manifest(tauri_build::AppManifest::new().commands(COMMANDS)),
    )
    .expect("failed to build Tauri app manifest");
}
