import Foundation

/// Which backend transcribes recorded audio. Stored in UserDefaults under
/// "transcriptionEngine". Defaults to `.local` so the app needs no API key for
/// its core feature.
enum TranscriptionEngine: String, CaseIterable {
    case local
    case openai

    static var current: TranscriptionEngine {
        TranscriptionEngine(rawValue: UserDefaults.standard.string(forKey: "transcriptionEngine") ?? "") ?? .local
    }
}

/// A backend that turns an audio file into text. Both the on-device WhisperKit
/// engine and the OpenAI API conform, so they're interchangeable at the call site.
/// Implementations return the existing `WhisperResponse` shape so the downstream
/// tonality-transform / clipboard flow stays unchanged.
protocol TranscriptionProvider {
    func transcribe(fileURL: URL) async throws -> WhisperResponse
}

/// Wraps the existing OpenAI `WhisperService` as a provider.
struct OpenAITranscriptionProvider: TranscriptionProvider {
    let apiKey: String

    func transcribe(fileURL: URL) async throws -> WhisperResponse {
        try await WhisperService.transcribe(fileURL: fileURL, apiKey: apiKey)
    }
}
