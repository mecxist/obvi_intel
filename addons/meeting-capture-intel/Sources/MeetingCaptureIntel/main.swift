import AppKit
import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ScreenCaptureKit

struct CaptureSource: Codable {
    let id: String
    let kind: String
    let name: String
    let owningApplication: String?
    let width: Int
    let height: Int
}

struct StatusResponse: Codable {
    let available: Bool
    let architecture: String
    let minimumMacOS: String
    let screenCapturePermission: Bool
    let microphonePermission: String
    let mode: String
}

struct SourcesResponse: Codable {
    let sources: [CaptureSource]
}

struct EventMessage: Codable {
    let type: String
    let message: String?
    let outputDirectory: String?
}

enum CaptureError: Error, LocalizedError {
    case invalidArguments(String)
    case sourceNotFound(String)
    case permissionDenied(String)
    case writerFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message),
             .sourceNotFound(let message),
             .permissionDenied(let message),
             .writerFailure(let message):
            return message
        }
    }
}

enum CaptureTarget {
    case display(SCDisplay)
    case window(SCWindow)

    var name: String {
        switch self {
        case .display(let display):
            return "Display \(display.displayID)"
        case .window(let window):
            if let title = window.title, !title.isEmpty { return title }
            return window.owningApplication?.applicationName ?? "Untitled Window"
        }
    }

    var width: Int {
        switch self {
        case .display(let display): return Int(display.width)
        case .window(let window): return Int(window.frame.width)
        }
    }

    var height: Int {
        switch self {
        case .display(let display): return Int(display.height)
        case .window(let window): return Int(window.frame.height)
        }
    }
}

final class SignalRelay {
    static let shared = SignalRelay()
    var handler: (() -> Void)?
}

private func installSignalHandlers(_ handler: @escaping () -> Void) {
    SignalRelay.shared.handler = handler
    signal(SIGINT) { _ in SignalRelay.shared.handler?() }
    signal(SIGTERM) { _ in SignalRelay.shared.handler?() }
}

private func emit<T: Encodable>(_ value: T) {
    guard
        let data = try? JSONEncoder().encode(value),
        let string = String(data: data, encoding: .utf8)
    else { return }
    print(string)
    fflush(stdout)
}

private func emitEvent(_ type: String, message: String? = nil, outputDirectory: String? = nil) {
    emit(EventMessage(type: type, message: message, outputDirectory: outputDirectory))
}

@available(macOS 13.0, *)
final class NativeCaptureSession: NSObject, SCStreamOutput, SCStreamDelegate {
    private let target: CaptureTarget
    private let outputDirectory: URL
    private let captureMicrophone: Bool
    private let captureQueue = DispatchQueue(label: "obvious-intel.capture", qos: .userInitiated)
    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let systemAudioInput: AVAssetWriterInput
    private let microphoneEngine = AVAudioEngine()
    private var microphoneFile: AVAudioFile?
    private var stream: SCStream!
    private let stateLock = NSLock()
    private var writerStarted = false
    private var stopping = false
    private var completion: CheckedContinuation<Void, Error>?

    init(target: CaptureTarget, outputDirectory: URL, captureMicrophone: Bool) throws {
        self.target = target
        self.outputDirectory = outputDirectory
        self.captureMicrophone = captureMicrophone

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let movieURL = outputDirectory.appendingPathComponent("meeting.mov")
        if FileManager.default.fileExists(atPath: movieURL.path) {
            try FileManager.default.removeItem(at: movieURL)
        }

        writer = try AVAssetWriter(outputURL: movieURL, fileType: .mov)

        let width = Self.evenDimension(target.width)
        let height = Self.evenDimension(target.height)

        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 4_000_000,
                    AVVideoMaxKeyFrameIntervalKey: 60
                ]
            ]
        )
        videoInput.expectsMediaDataInRealTime = true

        systemAudioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128_000
            ]
        )
        systemAudioInput.expectsMediaDataInRealTime = true

        guard writer.canAdd(videoInput), writer.canAdd(systemAudioInput) else {
            throw CaptureError.writerFailure("Unable to configure AVAssetWriter")
        }
        writer.add(videoInput)
        writer.add(systemAudioInput)

        let configuration = SCStreamConfiguration()
        configuration.width = width
        configuration.height = height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.queueDepth = 6
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2

        let filter: SCContentFilter
        switch target {
        case .display(let display):
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        case .window(let window):
            filter = SCContentFilter(desktopIndependentWindow: window)
        }

        super.init()
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: captureQueue)
    }

    func runUntilStopped() async throws {
        if captureMicrophone {
            try await startMicrophoneCapture()
        }

        installSignalHandlers { [weak self] in
            guard let self else { return }
            Task { await self.stop() }
        }

        try await stream.startCapture()
        emitEvent("recording-started", message: target.name, outputDirectory: outputDirectory.path)

        try await withCheckedThrowingContinuation { continuation in
            completion = continuation
        }
    }

    func stop() async {
        stateLock.lock()
        if stopping {
            stateLock.unlock()
            return
        }
        stopping = true
        stateLock.unlock()

        do {
            try await stream.stopCapture()
        } catch {
            emitEvent("warning", message: "Screen capture stop returned: \(error.localizedDescription)")
        }

        stopMicrophoneCapture()

        captureQueue.sync {
            videoInput.markAsFinished()
            systemAudioInput.markAsFinished()
        }

        if writerStarted {
            await withCheckedContinuation { continuation in
                writer.finishWriting { continuation.resume() }
            }
        } else {
            writer.cancelWriting()
        }

        let message = writer.status == .completed
            ? "capture finalized"
            : (writer.error?.localizedDescription ?? "capture stopped")
        emitEvent("recording-stopped", message: message, outputDirectory: outputDirectory.path)
        completion?.resume()
        completion = nil
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        emitEvent("error", message: error.localizedDescription, outputDirectory: outputDirectory.path)
        completion?.resume(throwing: error)
        completion = nil
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard CMSampleBufferIsValid(sampleBuffer) else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        startWriterIfNeeded(at: timestamp)

        switch outputType {
        case .screen:
            guard Self.isCompleteScreenFrame(sampleBuffer), videoInput.isReadyForMoreMediaData else { return }
            _ = videoInput.append(sampleBuffer)
        case .audio:
            guard systemAudioInput.isReadyForMoreMediaData else { return }
            _ = systemAudioInput.append(sampleBuffer)
        @unknown default:
            break
        }
    }

    private func startWriterIfNeeded(at timestamp: CMTime) {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !writerStarted else { return }
        guard writer.startWriting() else {
            emitEvent("error", message: writer.error?.localizedDescription ?? "Unable to start writer")
            return
        }
        writer.startSession(atSourceTime: timestamp)
        writerStarted = true
    }

    private func startMicrophoneCapture() async throws {
        let authorization = AVCaptureDevice.authorizationStatus(for: .audio)
        if authorization == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { continuation.resume(returning: $0) }
            }
            if !granted {
                throw CaptureError.permissionDenied("Microphone permission was denied")
            }
        } else if authorization != .authorized {
            throw CaptureError.permissionDenied("Microphone permission is not granted")
        }

        let input = microphoneEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        let microphoneURL = outputDirectory.appendingPathComponent("microphone.caf")
        if FileManager.default.fileExists(atPath: microphoneURL.path) {
            try FileManager.default.removeItem(at: microphoneURL)
        }

        microphoneFile = try AVAudioFile(
            forWriting: microphoneURL,
            settings: format.settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let file = self?.microphoneFile else { return }
            do {
                try file.write(from: buffer)
            } catch {
                emitEvent("warning", message: "Microphone write failed: \(error.localizedDescription)")
            }
        }

        microphoneEngine.prepare()
        try microphoneEngine.start()
    }

    private func stopMicrophoneCapture() {
        guard captureMicrophone else { return }
        microphoneEngine.inputNode.removeTap(onBus: 0)
        microphoneEngine.stop()
        microphoneFile = nil
    }

    private static func evenDimension(_ value: Int) -> Int {
        let normalized = max(2, value)
        return normalized.isMultiple(of: 2) ? normalized : normalized - 1
    }

    private static func isCompleteScreenFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer,
                createIfNecessary: false
            ) as? [[SCStreamFrameInfo: Any]],
            let first = attachments.first,
            let rawStatus = first[.status] as? Int,
            let status = SCFrameStatus(rawValue: rawStatus)
        else {
            return true
        }
        return status == .complete
    }
}

@available(macOS 13.0, *)
private func listSources() async throws -> [CaptureSource] {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    var sources: [CaptureSource] = []

    for window in content.windows where window.isOnScreen {
        sources.append(CaptureSource(
            id: "window:\(window.windowID)",
            kind: "window",
            name: window.title?.isEmpty == false
                ? window.title!
                : (window.owningApplication?.applicationName ?? "Untitled Window"),
            owningApplication: window.owningApplication?.applicationName,
            width: Int(window.frame.width),
            height: Int(window.frame.height)
        ))
    }

    for display in content.displays {
        sources.append(CaptureSource(
            id: "display:\(display.displayID)",
            kind: "display",
            name: "Display \(display.displayID)",
            owningApplication: nil,
            width: Int(display.width),
            height: Int(display.height)
        ))
    }

    return sources
}

@available(macOS 13.0, *)
private func resolveTarget(_ sourceID: String) async throws -> CaptureTarget {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

    if sourceID.hasPrefix("window:"), let id = UInt32(sourceID.dropFirst("window:".count)) {
        guard let window = content.windows.first(where: { $0.windowID == id }) else {
            throw CaptureError.sourceNotFound("Window not found: \(sourceID)")
        }
        return .window(window)
    }

    if sourceID.hasPrefix("display:"), let id = UInt32(sourceID.dropFirst("display:".count)) {
        guard let display = content.displays.first(where: { $0.displayID == id }) else {
            throw CaptureError.sourceNotFound("Display not found: \(sourceID)")
        }
        return .display(display)
    }

    throw CaptureError.invalidArguments("Unknown source identifier: \(sourceID)")
}

private func microphonePermissionName() -> String {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not-determined"
    @unknown default: return "unknown"
    }
}

private func argumentMap(_ arguments: [String]) throws -> [String: String] {
    var result: [String: String] = [:]
    var index = 0
    while index < arguments.count {
        guard arguments[index].hasPrefix("--"), index + 1 < arguments.count else {
            throw CaptureError.invalidArguments("Arguments must use --key value pairs")
        }
        result[String(arguments[index].dropFirst(2))] = arguments[index + 1]
        index += 2
    }
    return result
}

@MainActor
private func run() async throws {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else {
        throw CaptureError.invalidArguments(
            "Expected one of: status, request-permissions, list-sources, record"
        )
    }

    guard #available(macOS 13.0, *) else {
        throw CaptureError.invalidArguments(
            "The Intel meeting capture add-on requires macOS 13 or newer"
        )
    }

    switch command {
    case "status":
        emit(StatusResponse(
            available: true,
            architecture: "x86_64",
            minimumMacOS: "13.0",
            screenCapturePermission: CGPreflightScreenCaptureAccess(),
            microphonePermission: microphonePermissionName(),
            mode: "local-native-capture"
        ))

    case "request-permissions":
        let screenGranted = CGRequestScreenCaptureAccess()
        var microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            microphoneGranted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) {
                    continuation.resume(returning: $0)
                }
            }
        }
        emit(StatusResponse(
            available: screenGranted && microphoneGranted,
            architecture: "x86_64",
            minimumMacOS: "13.0",
            screenCapturePermission: screenGranted,
            microphonePermission: microphonePermissionName(),
            mode: "local-native-capture"
        ))

    case "list-sources":
        emit(SourcesResponse(sources: try await listSources()))

    case "record":
        let values = try argumentMap(Array(args.dropFirst()))
        guard let sourceID = values["source-id"], let outputPath = values["output-dir"] else {
            throw CaptureError.invalidArguments(
                "record requires --source-id and --output-dir"
            )
        }
        let target = try await resolveTarget(sourceID)
        let session = try NativeCaptureSession(
            target: target,
            outputDirectory: URL(fileURLWithPath: outputPath),
            captureMicrophone: values["capture-microphone"] != "false"
        )
        try await session.runUntilStopped()

    default:
        throw CaptureError.invalidArguments("Unknown command: \(command)")
    }
}

Task { @MainActor in
    do {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        try await run()
        exit(0)
    } catch {
        emitEvent("error", message: error.localizedDescription)
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

dispatchMain()
