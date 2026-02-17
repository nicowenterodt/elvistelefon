import AppKit
import Combine
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.r, modifiers: [.command, .shift]))
}

enum AppState: Equatable {
    case idle
    case recording
    case transcribing
    case done(String)
    case error(String)
}

enum RecordingMode: String {
    case pushToTalk = "pushToTalk"
    case toggle = "toggle"
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var state: AppState = .idle {
        didSet { showToastForState() }
    }
    @Published var audioLevel: Float = 0

    private let recorder = AudioRecorder()
    private var resetTask: Task<Void, Never>?
    private var settingsObserver: Any?
    private var currentMode: RecordingMode?

    private static let elvisQuotes = [
        "Thank you, thank you very much.",
        "Truth is like the sun. You can shut it out for a time, but it ain't goin' away.",
        "Ambition is a dream with a V8 engine.",
        "When things go wrong, don't go with them.",
        "Taking care of business!",
    ]

    private static let milestoneMessages: [Int: String] = [
        1: "Elvis is in the building.",
        10: "You're all shook up!",
        25: "Taking care of business, baby.",
        50: "Viva Las Vegas!",
        100: "You're the king of transcription!",
        500: "Elvis has NOT left the building!",
    ]

    var recordingMode: RecordingMode {
        RecordingMode(rawValue: UserDefaults.standard.string(forKey: "recordingMode") ?? "") ?? .pushToTalk
    }

    var tonalityMode: TonalityMode {
        TonalityMode(rawValue: UserDefaults.standard.string(forKey: "tonalityMode") ?? "") ?? .normal
    }

    init() {
        registerShortcutHandlers()
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.registerShortcutHandlers()
            }
        }
    }

    deinit {
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func registerShortcutHandlers() {
        let mode = recordingMode
        guard mode != currentMode else { return }
        currentMode = mode

        KeyboardShortcuts.removeHandler(for: .toggleRecording)

        switch mode {
        case .pushToTalk:
            KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
                self?.startRecording()
            }
            KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
                self?.stopRecordingAndTranscribe()
            }
        case .toggle:
            KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
                self?.toggleRecording()
            }
        }
    }

    var statusText: String {
        switch state {
        case .idle: return "Ready"
        case .recording: return "Recording…"
        case .transcribing: return "Transcribing…"
        case .done(let text):
            let preview = text.prefix(80)
            return "Copied: \(preview)\(text.count > 80 ? "…" : "")"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var systemImage: String {
        switch state {
        case .idle: return "waveform"
        case .recording: return "waveform.circle.fill"
        case .transcribing: return "waveform.badge.ellipsis"
        case .done: return "waveform.badge.checkmark"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    func toggleRecording() {
        switch state {
        case .idle, .done, .error:
            startRecording()
        case .recording:
            stopRecordingAndTranscribe()
        case .transcribing:
            break
        }
    }

    func startRecording() {
        switch state {
        case .idle, .done, .error: break
        default: return
        }
        resetTask?.cancel()
        do {
            recorder.onAudioLevel = { [weak self] level in
                Task { @MainActor [weak self] in
                    self?.audioLevel = level
                }
            }
            try recorder.startRecording()
            state = .recording
        } catch {
            state = .error(error.localizedDescription)
            scheduleReset()
        }
    }

    func stopRecordingAndTranscribe() {
        guard state == .recording else { return }
        audioLevel = 0

        guard let fileURL = recorder.stopRecording() else {
            state = .error("No recording file")
            scheduleReset()
            return
        }

        guard let apiKey = KeychainService.loadAPIKey(), !apiKey.isEmpty else {
            state = .error("No API key — open Settings")
            recorder.cleanup()
            scheduleReset()
            return
        }

        state = .transcribing

        Task { @MainActor in
            do {
                let response = try await WhisperService.transcribe(fileURL: fileURL, apiKey: apiKey)
                let rawText = response.text.trimmingCharacters(in: .whitespacesAndNewlines)

                var finalText = rawText
                let mode = tonalityMode
                if let systemPrompt = mode.systemPrompt(language: response.language) {
                    ToastWindow.shared.showTransforming(mode: mode)
                    do {
                        finalText = try await ChatCompletionService.transform(
                            text: rawText,
                            systemPrompt: systemPrompt,
                            apiKey: apiKey
                        )
                    } catch {
                        // Silent fallback to raw transcription
                    }
                }

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(finalText, forType: .string)

                state = .done(finalText)
                handleTranscriptionMilestone()
            } catch {
                state = .error(error.localizedDescription)
            }
            recorder.cleanup()
            scheduleReset()
        }
    }

    private func successMessage() -> String {
        if Int.random(in: 0..<5) == 0 {
            return Self.elvisQuotes.randomElement()!
        }
        return "Copied to clipboard!"
    }

    private func incrementTranscriptionCount() -> Int {
        let key = "transcriptionCount"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        return count
    }

    private func handleTranscriptionMilestone() {
        let count = incrementTranscriptionCount()
        guard let message = Self.milestoneMessages[count] else { return }

        // Show milestone toast after a short delay so it appears after the success toast
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            ToastWindow.shared.show(icon: "star.fill", text: message, color: .purple, autoDismissAfter: 3)
        }
    }

    private func showToastForState() {
        switch state {
        case .idle:
            ToastWindow.shared.dismiss()
        case .recording:
            ToastWindow.shared.showRecording(viewModel: self)
        case .transcribing:
            ToastWindow.shared.showTranscribing()
        case .done:
            ToastWindow.shared.show(icon: "checkmark.circle.fill", text: successMessage(), color: .green, autoDismissAfter: 2)
        case .error(let msg):
            ToastWindow.shared.show(icon: "exclamationmark.triangle.fill", text: msg, color: .red, autoDismissAfter: 3)
        }
    }

    private func scheduleReset() {
        resetTask?.cancel()
        resetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                state = .idle
            }
        }
    }
}
