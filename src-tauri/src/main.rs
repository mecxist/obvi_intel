use serde_json::{json, Value};
use std::process::Command;

const APP_WEB_URL: &str = "https://app.obvious.ai";

#[tauri::command]
fn app_web_url() -> String {
    APP_WEB_URL.to_string()
}

#[tauri::command]
fn get_config() -> Value {
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
        "dictationAvailable": false,
        "intelCompatibilityBuild": true
    })
}

#[tauri::command]
fn is_onboarded() -> bool {
    // Skip native-only onboarding. Account/workspace onboarding still lives in the web app.
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
    // Payload fields are intentionally ignored in the compatibility build.
    true
}

#[tauri::command]
fn meeting_window_status() -> Value {
    json!({
        "supported": false,
        "available": false,
        "reason": "Recall.ai Desktop Recording SDK does not support Intel macOS"
    })
}

#[tauri::command]
fn dictation_request_access() -> bool { false }

#[tauri::command]
fn dictation_start() -> bool { false }

#[tauri::command]
fn dictation_stop() -> bool { true }

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
