import Foundation
import WhisperKit

/// On-device transcription via WhisperKit (CoreML). Owns a single cached
/// `WhisperKit` instance and the model download/load lifecycle, and publishes
/// `loadState` so Settings can show progress.
///
/// Runs on the main actor: `@Published` updates must happen there, and
/// WhisperKit's heavy work is `async` and offloaded internally, so the main
/// thread isn't blocked during inference.
@MainActor
final class LocalWhisperService: ObservableObject, TranscriptionProvider {
    static let shared = LocalWhisperService()

    enum LoadState: Equatable {
        case notReady
        case downloading(Double)
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var loadState: LoadState = .notReady

    private var whisperKit: WhisperKit?
    private var loadedVariant: String?
    private var loadTask: Task<Void, Error>?

    private init() {}

    // MARK: - Model location & selection

    /// `<App Support>/Elvistelefon/models` — sits next to the api-key file.
    static var modelsBaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport
            .appendingPathComponent("Elvistelefon", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Canonical WhisperKit variant name (folder on argmaxinc/whisperkit-coreml)
    /// derived from the short name stored in Settings (e.g. "large-v3").
    var canonicalVariant: String {
        let short = UserDefaults.standard.string(forKey: "whisperModel") ?? "large-v3"
        if short.hasPrefix("openai_") || short.contains("/") { return short }
        return "openai_whisper-\(short)"
    }

    /// Tracks which variant has been fully downloaded+loaded at least once,
    /// so launch-time prewarm never triggers a surprise multi-GB download.
    var isModelDownloaded: Bool {
        UserDefaults.standard.string(forKey: "downloadedWhisperModel") == canonicalVariant
    }

    // MARK: - Lifecycle

    /// Reset cached state when the user picks a different model in Settings.
    func markStale() {
        if loadedVariant != canonicalVariant {
            loadState = .notReady
        }
    }

    /// Settings "Download" button entry point.
    func prepare() async {
        try? await ensureLoaded()
    }

    /// Download (if needed), prewarm and load the selected model, caching the
    /// instance. Coalesces concurrent callers and reloads on variant change.
    func ensureLoaded() async throws {
        let variant = canonicalVariant
        if whisperKit != nil, loadedVariant == variant, loadState == .ready { return }

        if let existing = loadTask {
            try await existing.value
            if loadedVariant == variant { return }
        }

        let task = Task { try await loadModel(variant: variant) }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    private func loadModel(variant: String) async throws {
        do {
            loadState = .downloading(0)
            let folder = try await WhisperKit.download(
                variant: variant,
                downloadBase: Self.modelsBaseURL,
                progressCallback: { progress in
                    Task { @MainActor [weak self] in
                        self?.loadState = .downloading(progress.fractionCompleted)
                    }
                }
            )

            loadState = .loading
            let config = WhisperKitConfig(
                modelFolder: folder.path,
                prewarm: true,
                load: true,
                download: false
            )
            let kit = try await WhisperKit(config)

            whisperKit = kit
            loadedVariant = variant
            UserDefaults.standard.set(variant, forKey: "downloadedWhisperModel")
            loadState = .ready
        } catch {
            loadState = .failed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - TranscriptionProvider

    func transcribe(fileURL: URL) async throws -> WhisperResponse {
        try await ensureLoaded()
        guard let kit = whisperKit else {
            throw NSError(domain: "LocalWhisperService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Transcription model not loaded"])
        }
        let results: [TranscriptionResult] = try await kit.transcribe(audioPath: fileURL.path)
        let first = results.first
        let text = first?.text ?? ""
        let language = first?.language
        return WhisperResponse(text: text, language: language)
    }
}
