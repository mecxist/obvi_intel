mod microphone;

use serde_json::{json, Value};
use std::path::PathBuf;
use std::process::Command;

const APP_WEB_URL: &str = "https://app.obvious.ai";

fn tacet_path() -> Option<PathBuf> {
    if let Ok(custom) = std::env::var("TACET_DIR") {
        let path = PathBuf::from(custom);
        if path.is_dir() {
            return Some(path);
        }
    }

    let home = std::env::var("HOME").ok()?;
    let path = PathBuf::from(home)
        .join(".local")
        .join("share")
        .join("obvious-intel")
        .join("tacet");

    path.is_dir().then_some(path)
}

#[tauri::command]
fn app_web_url() -> String {
    APP_WEB_URL.to_string()
}

#[tauri::command]
fn get_config() -> Value {
    let tacet_installed = tacet_path().is_some();

    json!({
        "appWebUrl": APP_WEB_URL,
        "app_web_url": APP_WEB_URL,
        "environment": "production",
        "env": "production",
        "platform": "macos",
        "arch": "x86_64",
        "version": "0.34.1-intel-compat",
        "meetingCaptureAvailable": false,
        "meeting_capture_available": false,
        "tacetCompanionInstalled": tacet_installed,
        "tacet_companion_installed": tacet_installed,
        "dictationAvailable": true,
        "intelCompatibilityBuild": true
    })
}

#[tauri::command]
fn is_onboarded() -> bool {
    true
}

#[tauri::command]
fn open_external(target: String) -> Result<(), String> {
    let allowed = target.starts_with("https://")
        || target.starts_with("http://")
        || target.starts_with("mailto:");
    if !allowed {
        return Err("refusing to open a non-web external target".into());
    }

    let status = Command::new("open")
        .arg(&target)
        .status()
        .map_err(|e| e.to_string())?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("macOS open exited with status {status}"))
    }
}

#[tauri::command]
fn frontend_log() -> bool {
    true
}

#[tauri::command]
fn meeting_window_status() -> Value {
    let tacet_installed = tacet_path().is_some();

    json!({
        "supported": false,
        "available": false,
        "reason": "Recall.ai Desktop Recording SDK does not support Intel macOS",
        "tacetCompanionInstalled": tacet_installed,
        "tacet_companion_installed": tacet_installed,
        "recommendedMeetingEngine": "Tacet",
        "recommended_meeting_engine": "Tacet",
        "integrationMode": "companion",
        "integration_mode": "companion"
    })
}

#[tauri::command]
fn dictation_request_access() -> bool {
    microphone::request_access()
}

#[tauri::command]
fn dictation_start() -> bool {
    microphone::request_access()
}

#[tauri::command]
fn dictation_stop() -> bool {
    true
}

#[tauri::command]
fn quick_bar() -> bool { true }

#[tauri::command]
fn notch_bar() -> bool { true }

#[tauri::command]
fn meeting_bar() -> bool { false }

#[tauri::command]
fn perf_mark() -> bool { true }

#[tauri::command]
fn dismiss_news() -> bool { true }

#[tauri::command]
fn set_active_thread() -> bool { true }

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let mut builder = tauri::WebviewWindowBuilder::new(
                app,
                "main",
                tauri::WebviewUrl::External(
                    APP_WEB_URL.parse().expect("APP_WEB_URL must be a valid URL"),
                ),
            )
            .title("Obvious")
            .inner_size(1440.0, 920.0)
            .min_inner_size(900.0, 640.0)
            .resizable(true)
            .fullscreen(false)
            .devtools(true);

            #[cfg(target_os = "macos")]
            {
                builder = builder.with_webview_configuration(microphone::webview_configuration());
            }

            builder.build()?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            app_web_url,
            get_config,
            is_onboarded,
            open_external,
            frontend_log,
            meeting_window_status,
            dictation_request_access,
            dictation_start,
            dictation_stop,
            quick_bar,
            notch_bar,
            meeting_bar,
            perf_mark,
            dismiss_news,
            set_active_thread,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Obvious Intel compatibility shell");
}
