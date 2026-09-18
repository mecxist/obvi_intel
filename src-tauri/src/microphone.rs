use std::sync::mpsc;
use std::time::Duration;

#[cfg(target_os = "macos")]
use block2::RcBlock;
#[cfg(target_os = "macos")]
use objc2::runtime::{AnyClass, Bool};
#[cfg(target_os = "macos")]
use objc2::{class, msg_send};
#[cfg(target_os = "macos")]
use objc2_foundation::NSString;

#[cfg(target_os = "macos")]
#[link(name = "AVFoundation", kind = "framework")]
extern "C" {}

const AUDIO_MEDIA_TYPE: &str = "soun";
const STATUS_AUTHORIZED: i64 = 3;
const STATUS_DENIED: i64 = 2;
const STATUS_RESTRICTED: i64 = 1;

/// Ask macOS for microphone access so chat speech-to-text can use getUserMedia.
pub fn request_access() -> bool {
    #[cfg(target_os = "macos")]
    {
        request_macos_microphone()
    }
    #[cfg(not(target_os = "macos"))]
    {
        false
    }
}

#[cfg(target_os = "macos")]
fn request_macos_microphone() -> bool {
    let device_class: &AnyClass = class!(AVCaptureDevice);
    let media_type = NSString::from_str(AUDIO_MEDIA_TYPE);

    let status: i64 = unsafe {
        msg_send![device_class, authorizationStatusForMediaType: &*media_type]
    };

    match status {
        STATUS_AUTHORIZED => true,
        STATUS_DENIED | STATUS_RESTRICTED => false,
        _ => {
            let (tx, rx) = mpsc::channel();
            let block = RcBlock::new(move |granted: Bool| {
                let _ = tx.send(granted.as_bool());
            });
            unsafe {
                let _: () = msg_send![
                    device_class,
                    requestAccessForMediaType: &*media_type,
                    completionHandler: &*block
                ];
            }
            rx.recv_timeout(Duration::from_secs(120)).unwrap_or(false)
        }
    }
}
